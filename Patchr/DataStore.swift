//
//  DataStore.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class DataStore: NSObject {
    
    var proxibaseClient : ProxibaseClient
    private var managedObjectContext : NSManagedObjectContext
    
    private lazy var schemaDictionary : [String : Entity.Type] = {
        return [
            "notification" : Notification.self,
            "patch" : Patch.self
        ]
    }()
    
    init(managedObjectContext context: NSManagedObjectContext, proxibaseClient: ProxibaseClient) {
        self.managedObjectContext = context;
        self.proxibaseClient = proxibaseClient;
        super.init()
    }
    
    func loadMoreResultsFor(query: Query, completion:(results: [QueryResult], error: NSError?) -> Void) {
        var parameters : Dictionary<String, AnyObject> = [
            "entityId" : self.proxibaseClient.userId ?? "",
            "cursor" : [
                "sort" : ["modifiedDate" : -1],
                "skip" : query.offset,
                "limit" : query.limit
            ]
        ]
        switch query.name {
        case "patches/near":
            parameters = [:]
            parameters["location"] = ["lat" : 49.2845280, "lng": -123.1092720] // TODO get current location
            parameters["radius"] = 10000
            parameters["links"] = linksForLinkProfile("patch")
        case "do/getEntitiesForEntity watching":
            var cursor = parameters["cursor"] as [String : AnyObject]
            cursor["direction"] = "out"
            cursor["linkTypes"] = ["watch"]
            cursor["schemas"] = ["patch"]
            parameters["cursor"] = cursor
        case "do/getEntitiesForEntity owner":
            var cursor = parameters["cursor"] as [String : AnyObject]
            cursor["direction"] = "out"
            cursor["linkTypes"] = ["create"]
            cursor["schemas"] = ["patch"]
            parameters["cursor"] = cursor
        case "stats/to/patches/from/messages mostActive":
            parameters = ["type" : "content"]
        case "stats/to/patches/from/users mostPopular":
            parameters = ["type" : "watch"]
        default: ()
        }
        fetchMoreResultsForGenericQuery(query, parameters: parameters, completion: completion)
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
                            NSLog("Unknown schema: \(schema)")
                        }
                    } else {
                        NSLog("No schema for object \(entityDictionary)")
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
                    "limit" : 1,
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
            
        default:()
        }
        
        return ["shortcuts" : true, "active" : activeLinks]
    }
}
