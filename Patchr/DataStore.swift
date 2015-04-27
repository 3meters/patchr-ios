//
//  DataStore.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CoreLocation

enum DataStoreQueryName : String {
    case LikersLinksForPatch = "Likers for patch"
    case WatchersLinksForPatch = "Watchers for patch"
}

class DataStore: NSObject {
    
    var proxibaseClient : ProxibaseClient
    private var managedObjectContext : NSManagedObjectContext
    private var locationManager : CLLocationManager
    
    private lazy var schemaDictionary : [String : ServiceBase.Type] = {
        return [
            "notification" : Notification.self,
            "patch" : Patch.self,
            "message" : Message.self,
            "user": User.self,
            "link": PALink.self
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
            let userQuery = Query.insertInManagedObjectContext(self.managedObjectContext) as! Query
            userQuery.name = "Current user"
            self.refreshResultsFor(userQuery) { results, error in
                if results.count == 1
                {
                    let user = results[0].result as! User
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
    
    // NOTE: avoid using this method
    func withEntity(entityId:String, refresh:Bool = false, completion: (Entity?) -> Void) {
        
        // TODO: switching on id prefix is almost certainly a bad idea.
        switch entityId {
        case let isPatch where entityId.hasPrefix("pa."):
            withPatch(entityId, refresh: refresh, completion: completion)
        case let isUser where entityId.hasPrefix("us."):
            withUser(entityId, refresh: refresh, completion: completion)
        default:
            NSLog("WARNING: withEntity not currently implemented for id of form \(entityId)")
            completion(nil)
        }
        
    }
    
    private func findModelType(type:ServiceBase.Type, withId id:String, completion: (response: AnyObject?, error: NSError?) -> Void) {
        
        if let patchType = type as? Patch.Type {
            self.proxibaseClient.findPatch(id, completion: completion)
        } else if let userType = type as? User.Type {
            self.proxibaseClient.findUser(id, completion: completion)
        }
        
    }
    
    private func withModel(modelType:ServiceBase.Type, id:String, refresh:Bool = false, completion: (ServiceBase) -> Void) {
        var object = modelType.fetchOneById(id, inManagedObjectContext: self.managedObjectContext)
        
        if refresh || object == nil {
            
            self.findModelType(modelType, withId: id, completion: { (response, error) -> Void in
                
                if error != nil {
                    
                    completion(object)
                    
                } else {
                    
                    if let dictionary = response as? [NSObject : AnyObject] {
                        
                        let dataWrapper = ServiceData()
                        ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
                        
                        if let entityDictionaries = dataWrapper.data as? [[NSObject : AnyObject]] {
                            
                            if entityDictionaries.count == 1 {
                                object = modelType.fetchOrInsertOneById(id, inManagedObjectContext: self.managedObjectContext)
                                modelType.setPropertiesFromDictionary(entityDictionaries[0], onObject: object, mappingNames: true)
                            }
                            
                        }
                        
                        // George: swift 1.2 conversion
                        // for queryResult in object?.queryResults?.allObjects as? [QueryResult] ?? []{
                        for queryResult in object.queryResults {
                            // Poke each impacted queryResult to trigger NSFetchedResultsController callbacks
                            (queryResult as! QueryResult).modificationDate = NSDate()
                        }
                        
                        self.managedObjectContext.save(nil)
                        
                    }
                    
                    completion(object)
                    
                }
            })
            
        } else {
            
            completion(object)
            
        }
    }
    
    func withPatch(patchId:String, refresh:Bool = false, completion: (Patch?) -> Void) {
        self.withModel(Patch.self, id: patchId, refresh: refresh) { (model) -> Void in
            completion(model as? Patch)
        }
    }
    
    func withUser(userId:String, refresh:Bool = false, completion: (User?) -> Void) {
        self.withModel(User.self, id: userId, refresh: refresh) { (model) -> Void in
            completion(model as? User)
        }
    }
    
    func refreshResultsFor(query: Query, completion:(results: [QueryResult], error: NSError?) -> Void) {

        func refreshCompletion(response: AnyObject?, error: NSError?) -> Void {
            
            if error != nil {
                completion(results: [], error: error)
                return
            }
            
            let results = self.handleResponseForQuery(query, response: response!)
            let resultsSet = NSSet(array: results)
            // We need to purge all query results for the query that are not in the current result set
            for existingQueryResult in query.queryResults {
                if !resultsSet.containsObject(existingQueryResult) {
                    self.managedObjectContext.deleteObject(existingQueryResult as! NSManagedObject)
                }
            }
            // query.offset = results.count
            self.managedObjectContext.save(nil)
            
            completion(results: results, error: error)
        }
        
        let defaultRadius = 10000
        
        switch query.name {
            
        case "Nearby patches":
            self.proxibaseClient.fetchNearbyPatches(self.currentUserLocation(), radius: defaultRadius, completion:refreshCompletion)
        case "Notifications for current user":
            self.proxibaseClient.fetchNotifications(completion: refreshCompletion)
        case "Explore patches":
            self.proxibaseClient.fetchInterestingPatches(self.currentUserLocation(), completion: refreshCompletion)
        case "Comments by current user":
            self.proxibaseClient.fetchMessagesOwnedByCurrentUser(completion: refreshCompletion)
        case "Messages for patch":
            let patchId = query.parameters["patchId"] as! String
            self.proxibaseClient.fetchMessagesForPatch(patchId, completion: refreshCompletion)
        case "Current user":
            self.proxibaseClient.fetchCurrentUser(refreshCompletion)
        case DataStoreQueryName.LikersLinksForPatch.rawValue:
            let patchId = query.parameters["patchId"] as! String
            self.proxibaseClient.fetchPatchWithLikerLinks(patchId, completion: refreshCompletion)
        case DataStoreQueryName.WatchersLinksForPatch.rawValue:
            let patchId = query.parameters["patchId"] as! String
            self.proxibaseClient.fetchPatchWithWatcherLinks(patchId, completion: refreshCompletion)
        default:
            assert(false, "No refreshResultsFor implementation for query name \(query.name)")
        }
    }
    
    private func handleResponseForQuery(query: Query, response: AnyObject) -> [QueryResult] {
        var queryResults: [QueryResult] = []
        switch query.name {
        case DataStoreQueryName.LikersLinksForPatch.rawValue, DataStoreQueryName.WatchersLinksForPatch.rawValue:
            // QueryResults will be PALink type
            let json = JSON(response)
            let links = json["data"]["links"]
            for (index: String, subJson: JSON) in links {
                let position = index.toInt() ?? 0 // TODO: This will end up being something like: index.toInt() + query.offset
                if let queryResult = self.extractQueryResultFrom(subJson, query: query, resultPositionValue: position) {
                    queryResults.append(queryResult)
                }
            }
        default:
            queryResults = handleServiceDataResponseForQuery(query, response: response).results
        }
        return queryResults
    }
    
    private func extractQueryResultFrom(entityJSON: JSON, query: Query, resultPositionValue: Int) -> QueryResult? {
        
        var queryResult: QueryResult!
        
        if let schema = entityJSON["schema"].string {
            
            if let modelType = self.schemaDictionary[schema] {
                
                var entityModel : ServiceBase
                if let entityId = entityJSON["_id"].string {
                    entityModel = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: self.managedObjectContext) as ServiceBase
                } else if let entityId = entityJSON["id"].string { // Old API doesn't have the underscore (?)
                    entityModel = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: self.managedObjectContext) as ServiceBase
                } else {
                    entityModel = modelType.insertInManagedObjectContext(self.managedObjectContext) as! ServiceBase
                }
                
                modelType.setPropertiesFromDictionary(entityJSON.dictionaryObject, onObject: entityModel, mappingNames: true)
                
                for obj in entityModel.queryResults {
                    let existingQueryResult = obj as! QueryResult
                    if existingQueryResult.query == query {
                        queryResult = existingQueryResult
                    }
                }
                
                if queryResult == nil {
                    queryResult = QueryResult.insertInManagedObjectContext(self.managedObjectContext) as! QueryResult
                }
                
                queryResult.query = query
                queryResult.result = entityModel
                queryResult.position = resultPositionValue
                queryResult.sortDate = entityModel.sortDate
            }
        }
        return queryResult
    }
    
    private func handleServiceDataResponseForQuery(query: Query, response: AnyObject) -> (serviceData: ServiceData, results: [QueryResult]) {

        var results: [QueryResult] = []
        let dataWrapper = ServiceData()
        if let dictionary = response as? [NSObject : AnyObject] {
            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
            if let entityDictionaries = dataWrapper.data as? [[NSObject : AnyObject]] {
                var resultPosition = 0; // + query.offset
                for entityDictionary in entityDictionaries {
                    if let schema = entityDictionary["schema"] as? String {
                        if let modelType = self.schemaDictionary[schema] {
                            
                            var entityModel : Entity
                            if let entityId = entityDictionary["_id"] as? String {
                                entityModel = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: self.managedObjectContext) as! Entity
                            } else if let entityId = entityDictionary["id"] as? String { // Old API doesn't have the underscore (?)
                                entityModel = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: self.managedObjectContext) as! Entity
                            } else {
                                entityModel = modelType.insertInManagedObjectContext(self.managedObjectContext) as! Entity
                            }
                            
                            modelType.setPropertiesFromDictionary(entityDictionary, onObject: entityModel, mappingNames: true)
                            
                            var queryResult: QueryResult!;
                            for obj in entityModel.queryResults {
                                let existingQueryResult = obj as! QueryResult
                                if existingQueryResult.query == query {
                                    queryResult = existingQueryResult
                                }
                            }
                            
                            if queryResult == nil {
                                queryResult = QueryResult.insertInManagedObjectContext(self.managedObjectContext) as! QueryResult
                            }
                            
                            queryResult.query = query
                            queryResult.result = entityModel
                            queryResult.position = resultPosition++
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
            // - store/retrieve location in NSUserDefaults
            // - likely get a nearby major city based on timezone
            return CLLocationCoordinate2D(latitude: 49.2845280, longitude: -123.1092720)
        }
    }
}
