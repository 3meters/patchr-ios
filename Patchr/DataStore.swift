//
//  DataStore.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CoreLocation

class DataStore: NSObject {
    
    var proxibaseClient : ProxibaseClient
    private var managedObjectContext : NSManagedObjectContext
    private var locationManager : CLLocationManager
    
    private lazy var schemaDictionary : [String : Entity.Type] = {
        return [
            "notification" : Notification.self,
            "patch" : Patch.self,
            "message" : Message.self
        ]
    }()
    
    init(managedObjectContext context: NSManagedObjectContext, proxibaseClient: ProxibaseClient, locationManager: CLLocationManager) {
        self.managedObjectContext = context;
        self.proxibaseClient = proxibaseClient;
        self.locationManager = locationManager
        super.init()
    }
    
    func loadMoreResultsFor(query: Query, completion:(results: [QueryResult], error: NSError?) -> Void) {
        
        switch query.name {
        case "Nearby patches":
            self.proxibaseClient.fetchNearbyPatches(self.currentUserLocation(), radius: 10000, completion: { (response, error) -> Void in
                completion(results: self.handleResponseForQuery(query, response: response!), error: error)
            })
        case "Notifications for current user":
            self.proxibaseClient.fetchNotifications(completion: { (response, error) -> Void in
                completion(results: self.handleResponseForQuery(query, response: response!), error: error)
            })
        case "Explore patches":
            self.proxibaseClient.fetchMostMessagedPatches(completion: { (response, error) -> Void in
                completion(results: self.handleResponseForQuery(query, response: response!), error: error)
            })
        case "Comments by current user":
            self.proxibaseClient.fetchMessagesOwnedByCurrentUser(completion: { (response, error) -> Void in
                completion(results: self.handleResponseForQuery(query, response: response!), error: error)
            })
        default:
            assert(false, "Unknown query name \(query.name)")
        }
    }
    
    private func fetchMoreResultsForGenericQuery(query: Query, parameters: [String : AnyObject], completion: (results: [QueryResult], error: NSError?) -> Void) {
        self.proxibaseClient.performPOSTRequestFor(query.path,
            parameters: parameters,
            completion: { (response, var error) -> Void in
                var queryResults : [QueryResult] = []
                if error == nil {
                    if response != nil {
                        queryResults = self.handleResponseForQuery(query, response: response!)
                        query.managedObjectContext?.save(&error)
                    }
                }
                completion(results: queryResults, error: error)
        })
    }
    
    private func handleResponseForQuery(query: Query, response: AnyObject) -> [QueryResult] {
        var queryResults: [QueryResult] = []
        queryResults = handleServiceDataResponseForQuery(query, response: response).results
        query.offsetValue += queryResults.count // TODO this assumes query requests are performed serially. Not currently a safe assumption
        return queryResults
    }
    
    private func handleServiceDataResponseForQuery(query: Query, response: AnyObject) -> (serviceData: ServiceData, results: [QueryResult]) {
        var results: [QueryResult] = []
        let dataWrapper = ServiceData()
        if let dictionary = response as? [NSObject : AnyObject] {
            NSLog("%@", dictionary)
            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
            if let entityDictionaries = dataWrapper.data as? [[NSObject : AnyObject]] {
                for entityDictionary in entityDictionaries {
                    if let schema = entityDictionary["schema"] as? String {
                        if let modelType = self.schemaDictionary[schema] {
                            let entityModel = modelType.insertInManagedObjectContext(self.managedObjectContext) as Entity
                            modelType.setPropertiesFromDictionary(entityDictionary, onObject: entityModel, mappingNames: true)
                            let queryResult = QueryResult.insertInManagedObjectContext(self.managedObjectContext) as QueryResult
                            queryResult.query = query
                            queryResult.entity_ = entityModel
                            queryResult.position = entityModel.position != nil ? entityModel.position : entityModel.rank
                            //queryResult.rank = entityModel.rank
                            queryResult.sortDate = entityModel.sortDate
                            results.append(queryResult)
                        } else {
                            assert(false, "Unknown schema: \(schema)")
                        }
                    } else {
                        assert(false, "No schema for object \(entityDictionary)")
                    }
                }
            }
        }
        return (dataWrapper, results)
    }
    
    private func linksForLinkProfile(profile: String) -> [NSObject:AnyObject] {
        // TODO check these values and move to constants
        let limitProximity = 25
        let limitContent = 25
        let currentUserId = self.proxibaseClient.userId ?? "" // TODO should be better
        
        var activeLinks : [[NSObject:AnyObject]] = [[:]]
        
        // TODO change profile type to an enum
        switch profile {
        case "patch", "beacon":
            activeLinks = [[
                    "type" : "proximity",
                    "schema" : "beacon",
                    "links" : true,
                    "count" : true,
                    "limit" : limitProximity,
                    "direction" : "out"
                ],
                [
                    "type" : "proximity",
                    "schema" : "place",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "out"
                ],
                [
                    "type" : "content",
                    "schema" : "message",
                    "links" : true,
                    "count" : true,
                    "limit" : limitContent,
                    "direction" : "both"
                ],
                [
                    "type" : "watch",
                    "schema" : "user",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "in",
                    "where" : ["_from" : currentUserId]
                ],
                [
                    "type" : "like",
                    "schema" : "user",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "in",
                    "where" : ["_from" : currentUserId]
                ],
                [
                    "type" : "content",
                    "schema" : "message",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "in",
                    "where" : ["_creator" : currentUserId]
                ]]
        case "message":
            activeLinks = [[
                    "type" : "content",
                    "schema" : "message",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "both"
                ],
                [
                    "type" : "content",
                    "schema" : "patch",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "out"
                ],
                [
                    "type" : "share",
                    "schema" : "patch",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "out"
                ],
                [
                    "type" : "share",
                    "schema" : "message",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "out"
                ],
                [
                    "type" : "share",
                    "schema" : "user",
                    "links" : true,
                    "count" : true,
                    "limit" : 5,
                    "direction" : "out"
                ],
                [
                    "type" : "like",
                    "schema" : "user",
                    "links" : true,
                    "count" : true,
                    "limit" : 1,
                    "direction" : "in",
                    "where" : ["_from" : currentUserId]
                ]
            ]
            
        default:()
        }
        
        return ["shortcuts" : true, "active" : activeLinks]
    }
    
    private func currentUserLocation() -> CLLocationCoordinate2D {
        if locationManager.location != nil {
            return locationManager.location.coordinate
        } else {
            // Fallback location
            // TODO we can be more creative with this:
            // - store/retrieve location in NSUserDefaults
            // - likely get a nearby major city based on timezone
            return CLLocationCoordinate2D(latitude: 49.2845280, longitude: -123.1092720)
        }
    }
}
