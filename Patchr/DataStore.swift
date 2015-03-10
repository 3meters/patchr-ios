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
            "message" : Message.self,
            "user": User.self
        ]
    }()
    
    init(managedObjectContext context: NSManagedObjectContext, proxibaseClient: ProxibaseClient, locationManager: CLLocationManager) {
        self.managedObjectContext = context;
        self.proxibaseClient = proxibaseClient;
        self.locationManager = locationManager
        super.init()
    }

    private var _currentUser: User? = nil
    
    func withCurrentUser(refresh:Bool = false, completion: (User) -> Void)
    {
        if refresh || _currentUser == nil
        {
            let userQuery = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
            userQuery.name = "Current user"
            self.loadMoreResultsFor(userQuery) { results, error in
                if results.count == 1
                {
                    let user = results[0].entity_ as User
                    self._currentUser = user
                    dispatch_async(dispatch_get_main_queue())
                    {
                        completion(self._currentUser!)
                    }
                }
            }
        }
        else {
            completion(self._currentUser!)
        }
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
        case "Messages for patch":
            // TODO need better mechanism to pass patchId through query
            let patchId = query.parameters["patchId"] as String
            self.proxibaseClient.fetchMessagesForPatch(patchId, completion: { (response, error) -> Void in
                completion(results: self.handleResponseForQuery(query, response: response!), error: error)
            })
        case "Current user":
            self.proxibaseClient.fetchCurrentUser() { response, error in
                completion(results: self.handleResponseForQuery(query, response: response!), error: error)
            }
        default:
            assert(false, "Unknown query name \(query.name)")
        }
    }
    
    private func handleResponseForQuery(query: Query, response: AnyObject) -> [QueryResult] {
        var queryResults: [QueryResult] = []
        queryResults = handleServiceDataResponseForQuery(query, response: response).results
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
                            
                            var entityModel : Entity
                            if let entityId = entityDictionary["_id"] as? String {
                                entityModel = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: self.managedObjectContext) as Entity
                            } else {
                                entityModel = modelType.insertInManagedObjectContext(self.managedObjectContext) as Entity
                            }
                            
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
