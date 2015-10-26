
/*
 * DataStore
 *
 * Handles general data browse operations by coordinating interactions with the data model (core data)
 * and the proxibase service. All insert/update/delete and custom interactions are handled by direct
 * calls to Proxibase.
 * 
 * Singleton queries using with* methids pull in linked entities using link specs based on the
 * targeted entity type. The linked entities are pushed into the data model. They are bound to
 * the target entity like this:
 *
 * 	- Patch.messagesSet
 * 	- Patch.place
 * 	- ServiceBase.creator (linked entity overwrites entity.creator property if it's set)
 * 	- ServiceBase.owner
 *
 * Collection queries using refreshResultsFor method use both linked and links to pull in data
 * for related entities. Two services queries use links and all the rest use linked.
 */

import UIKit
import CoreData
import CoreLocation

class DataController: NSObject {

	static let instance  = DataController()
	static let proxibase = Proxibase()

	private var coreDataStack: CoreDataStack!

	var mainContext: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
	
    var activityDate: Int64
    var currentPatch: Patch?    // Currently used for message context
	
	var backgroundQueue = NSOperationQueue()
	var imageQueue = NSOperationQueue()

	private lazy var schemaDictionary: [String:ServiceBase.Type] = {
		return [
            "message": Message.self,
			"notification": Notification.self,
			"patch": Patch.self,
            "place": Place.self,
			"user": User.self
		]
	}()

	private override init() {
		
        self.activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
		self.backgroundQueue.name = "Background queue"
		self.imageQueue.name = "Image processing queue"
		
		super.init()
		
		self.coreDataStack = CoreDataStack()
		self.mainContext = self.coreDataStack.mainContext
        self.backgroundContext = self.coreDataStack.backgroundContext
	}
	
	func saveContext(wait: Bool = false) {
		self.coreDataStack.saveContext(self.mainContext, wait: wait)
	}

    func saveContext(context: NSManagedObjectContext, wait: Bool = false) {
        self.coreDataStack.saveContext(context, wait: wait)
    }

	/*--------------------------------------------------------------------------------------------
	 * Singles
	 *--------------------------------------------------------------------------------------------*/

	func withPatchId(patchId: String, refresh: Bool = false, completion: (Patch?, error: NSError?) -> Void) {
        /*
        * - Load a patch for the patch form
        * - Show a patch by id for a notification.
        */
		withEntityType(Patch.self, id: patchId, refresh: refresh) {
			(model, error) -> Void in
			completion(model as? Patch, error: error)
		}
	}

	func withMessageId(messageId: String, refresh: Bool = false, completion: (Message?, error: NSError?) -> Void) {
        /*
        * Load a message for the message form.
        */
		withEntityType(Message.self, id: messageId, refresh: refresh) {
			(model, error) -> Void in
			completion(model as? Message, error: error)
		}
	}

	func withUserId(userId: String, refresh: Bool = false, completion: (User?, error: NSError?) -> Void) {
        /*
        * - Load users for items in user lists
        * - Load user by id for a notification.
        */
		withEntityType(User.self, id: userId, refresh: refresh) {
			(model, error) -> Void in
			completion(model as? User, error: error)
		}
	}

    func withPlaceId(placeId: String, refresh: Bool = false, completion: (Place?, error: NSError?) -> Void) {
        /*
        * - Load a place for the place form
        */
        withEntityType(Place.self, id: placeId, refresh: refresh) {
            (model, error) -> Void in
            completion(model as? Place, error: error)
        }
    }
    
    func withEntityId(entityId: String, refresh: Bool = false, completion: (Entity?, error: NSError?) -> Void) {
        /*
        * Used by notifications which only have an entity id to work with.
        */
		switch entityId {
			case _ where entityId.hasPrefix("pa."):
				withPatchId(entityId, refresh: refresh, completion: completion)
            
            case _ where entityId.hasPrefix("pl."):
                withPlaceId(entityId, refresh: refresh, completion: completion)
            
			case _ where entityId.hasPrefix("us."):
				withUserId(entityId, refresh: refresh, completion: completion)
            
			case _ where entityId.hasPrefix("me."):
				withMessageId(entityId, refresh: refresh, completion: completion)
            
			default:
				Log.w("WARNING: withEntity not currently implemented for id of form \(entityId)")
				completion(nil, error: nil)
		}
	}

    private func withEntityType(entityType: ServiceBase.Type, id: String, refresh: Bool = false, completion: (ServiceBase?, error: NSError?) -> Void) {
            
            /* Pull from data model if available */
            var entity = entityType.fetchOneById(id, inManagedObjectContext: mainContext) as ServiceBase!
            
            /* If not in data model or caller wants the freshest available then call service */
            if refresh || entity == nil {
                
                var criteria: [String: AnyObject] = [:]
                if entity != nil {
                    criteria = entity.criteria()
                }
                
                fetchByEntityType(entityType, withId: id, criteria: criteria, completion: {
                    response, error in
					
					/* Returns on background thread */
                    
                    if let _ = ServerError(error) {
                        completion(nil, error: error)
                    }
                    else {
                        /* Turn maps and arrays into objects */
                        if let dictionary = response as? [NSObject:AnyObject] {

                            let dataWrapper = ServiceData()
                            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
							Log.d("RESPONSE Service time: \(dataWrapper.time) for \(entityType)")
                            
                            if !dataWrapper.noopValue {
                                if let entityDictionaries = dataWrapper.data as? [[NSObject:AnyObject]] {
                                    if entityDictionaries.count == 1 {
                                        entity = entityType.fetchOrInsertOneById(id, inManagedObjectContext: self.backgroundContext)
                                        entityType.setPropertiesFromDictionary(entityDictionaries[0], onObject: entity, mappingNames: true)
										entity.refreshedValue = true
                                    }
                                }
                                
                                /* Poke each impacted queryItem to trigger NSFetchedResultsController callbacks */
                                for queryItem in entity.queryItems {
                                    if let result = queryItem as? QueryItem {
                                        result.modifiedDate = NSDate()
                                    }
                                }
                                
                                /* Persist the changes and triggers notifications to observers */
								DataController.instance.saveContext(self.backgroundContext, wait: false)
                            }
                        }
                        completion(entity, error: nil)
                    }
                })
            }
            else {
                completion(entity, error: nil)
            }
    }
    
    private func fetchByEntityType(type: ServiceBase.Type, withId id: String, criteria: Dictionary<String,AnyObject> = [:], completion: (response: AnyObject?, error: NSError?) -> Void) {
        if let _ = type as? Patch.Type {
            DataController.proxibase.fetchPatchById(id, criteria:criteria, completion: completion)
        }
        else if let _ = type as? Message.Type {
            DataController.proxibase.fetchMessageById(id, criteria:criteria, completion: completion)
        }
        else if let _ = type as? Place.Type {
            DataController.proxibase.fetchPlaceById(id, criteria:criteria, completion: completion)
        }
        else if let _ = type as? User.Type {
            DataController.proxibase.fetchUserById(id, criteria:criteria, completion: completion)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Collections
     *--------------------------------------------------------------------------------------------*/
    
    func refreshItemsFor(queryId: NSManagedObjectID, force: Bool = false, paging: Bool = false, completion: (queryItems: [QueryItem], query: Query, error: NSError?) -> Void) {
		/* 
		 * Called on background thread 
		 */
		let query = self.backgroundContext.objectWithID(queryId) as! Query
		
        if query.name == DataStoreQueryName.NotificationsForCurrentUser.rawValue && !UserController.instance.authenticated {
            completion(queryItems: [], query: query, error: nil)
            return
        }

		/* Callback when service call is complete */
		func refreshCompletion(response: AnyObject?, error: NSError?) -> Void {
			/* 
			 * Returns on background thread 
			 */
			if error != nil {
				completion(queryItems: [], query: query, error: error)
				return
			}
			
			/* Turn response entities into managed entities */
			let returnValue = self.handleServiceDataResponseForQuery(query, response: response!)
			
			/* If service query completed as a noop then bail */
			if (returnValue.serviceData.noopValue) {
				completion(queryItems: [], query: query, error: error)
				return
			}
			
			/* So we can provide a hint that paging is available */
			query.moreValue = returnValue.serviceData.moreValue
			let queryItems = returnValue.queryItems
			
			/*
			* Clearing entities that have been deleted is tricky. When paging, we don't
			* have a good way to know that an entity for a previous page set has been deleted
			* unless we are on page one and working forward in a fresh pass.
			*
			* Starting at zero will cause all entities outside of the first 'page' to be
			* deleted as well as any first page entities no longer part of the refreshed
			* first page.
			*/
			if query.offsetValue == 0 {
				let queryItemSet = Set(queryItems)  // If for some reason there are any duplicates, this will remove them
				for item in query.queryItems {
					if let existingQueryItem = item as? QueryItem {
						if !queryItemSet.contains(existingQueryItem) {
							self.backgroundContext.deleteObject(existingQueryItem) // Does not throw
						}
					}
				}
			}
			
			/* Persist the changes and triggers notifications to observers */
			Log.d("Save context: \(query.name)")
			DataController.instance.saveContext(self.backgroundContext, wait: false)
			completion(queryItems: queryItems, query: query, error: error)
		}
		
        let coordinate = LocationController.instance.lastLocationAccepted()?.coordinate

        var entity: ServiceBase!
        var entityId: String!
		
        /* We only get here if either entity or entityId are available */
		
        if query.parameters != nil {
            entity = query.parameters["entity"] as? ServiceBase
            entityId = query.parameters["entityId"] as? String
        }
        
        if entityId == nil && entity != nil {
            entityId = entity.id_
        }
        
        if force {
            query.offsetValue = 0
            query.executedValue = false
        }
        
        var isOwner = false
        if entity != nil && entity.creator != nil && UserController.instance.authenticated {
            isOwner = (entity.creator.entityId == UserController.instance.currentUser.id_)
        }

        var skip = 0
        if paging {
            skip = Int(ceil(Float(query.offsetValue) / Float(query.pageSizeValue)) * Float(query.pageSizeValue))
        }
        
        query.criteriaValue = false
        var criteria: [String: AnyObject] = [:]
		if !force && query.executedValue && entity != nil && !paging {
			criteria = entity!.criteria(true)
            query.criteriaValue = true
		}
        
		switch query.name {
			case DataStoreQueryName.NearbyPatches.rawValue:
                query.criteriaValue = false
                DataController.proxibase.fetchNearbyPatches(coordinate, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.NotificationsForCurrentUser.rawValue:
                query.criteriaValue = false
                DataController.proxibase.fetchNotifications(skip, completion: refreshCompletion)
            
			case DataStoreQueryName.ExplorePatches.rawValue:
                query.criteriaValue = false
                DataController.proxibase.fetchInterestingPatches(coordinate, skip: skip, completion: refreshCompletion)
            
			case DataStoreQueryName.MessagesByUser.rawValue:
                DataController.proxibase.fetchMessagesOwnedByUser(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.MessagesForPatch.rawValue:
				DataController.proxibase.fetchMessagesForPatch(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.WatchersForPatch.rawValue:
                DataController.proxibase.fetchUsersThatWatchPatch(entityId, isOwner: isOwner, criteria: criteria, skip: skip, completion: refreshCompletion)

            case DataStoreQueryName.LikersForMessage.rawValue:
                DataController.proxibase.fetchUsersThatLikeMessage(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
            case DataStoreQueryName.PatchesByUser.rawValue:
                DataController.proxibase.fetchPatchesOwnedByUser(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
            case DataStoreQueryName.PatchesUserIsWatching.rawValue:
                DataController.proxibase.fetchPatchesUserIsWatching(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
            case DataStoreQueryName.FavoritePatches.rawValue:
                DataController.proxibase.fetchUsersFavoritePatches(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
			default:
				assert(false, "No refreshResultsFor implementation for query name \(query.name)")
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/
	
	private func handleServiceDataResponseForQuery(query: Query, response: AnyObject) -> (serviceData:ServiceData, queryItems:[QueryItem]) {

		var queryItems: [QueryItem] = []
		let dataWrapper = ServiceData()
		if let dictionary = response as? [NSObject:AnyObject] {

			ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
			Log.d("RESPONSE service time: \(dataWrapper.time) for \(query.name)")

            if (dataWrapper.noopValue) {
                return (dataWrapper, [])
            }
            
			if var entityDictionaries = dataWrapper.data as? [[NSObject: AnyObject]] {
                
                /* Append the sidecar maps if any */
                if let sidecar = query.sidecar as? [[NSObject: AnyObject]] {
                    
                    /* Find date brackets in current set */
                    var startDate: Int = 0
                    var endDate: Int = Int(NSDate().timeIntervalSince1970 * 1000)
                    for entityDictionary in entityDictionaries {
                        if let itemDate = entityDictionary["sortDate"] as? Int {
                            if itemDate < endDate {
                                endDate = itemDate
                            }
                            if itemDate > startDate {
                                startDate = itemDate
                            }
                        }
                    }
                    
                    /* Fold in sidecar items that fall inside bracketed date range */
                    for sidecarDictionary in sidecar {
                        if let itemDate = sidecarDictionary["sortDate"] as? Int {
                            if itemDate <= startDate && itemDate >= endDate {
                                entityDictionaries.append(sidecarDictionary)
                            }
                        }
                    }
                }

				var itemPosition = 0 + query.offsetValue
				for entityDictionary in entityDictionaries {

					if let schema = entityDictionary["schema"] as? String, let modelType = schemaDictionary[schema] {
                        /*
                         * We either create a new entity or update an existing entity. If existing then
                         * we keep the same instance and overwrite the properties included in the downloaded
                         * entity retaining any other properties including local ones.
                         */
                        var entity: Entity
                        if let entityId = entityDictionary["_id"] as? String {
                            entity = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: self.backgroundContext) as! Entity
                        }
                        else {
                            entity = modelType.insertInManagedObjectContext(self.backgroundContext) as! Entity
                        }
                        
                        /* Transfer the properties: Updates the object if it was already in the model */
                        modelType.setPropertiesFromDictionary(entityDictionary, onObject: entity, mappingNames: true)
                        
                        /* Check to see if this entity is already part of the query */
                        var queryItem: QueryItem!
                        for item in entity.queryItems {
                            let existingQueryItem = item as! QueryItem
                            if existingQueryItem.query == query {
                                queryItem = existingQueryItem
                            }
                        }
                        
                        /* Add if new */
                        if queryItem == nil {
                            queryItem = QueryItem.insertInManagedObjectContext(self.backgroundContext) as! QueryItem
                        }

                        /* Set properties */
                        queryItem.query = query     // Sets both query and query.queryItems
                        queryItem.object = entity	// The only place that associates an entity with a query item
                        queryItem.positionValue = Int64(itemPosition++)
                        queryItem.sortDate = entity.sortDate
                        
                        if let patch = entity as? Patch {
                            if let distance = patch.distance() {
                                queryItem.distanceValue = distance
                            }
                        }

                        queryItems.append(queryItem)
					}
					else {
						assert(false, "Missing or unknown schema for object \(entityDictionary)")
					}
				}
			}
		}
        return (dataWrapper, queryItems)    // Includes existing and new, could still have orphans
	}
    
    func dataWrapperForResponse(response: AnyObject) -> ServiceData? {
        if let dictionary = response as? [NSObject:AnyObject] {
            let dataWrapper = ServiceData()
            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
			Log.d("Service response time: \(dataWrapper.time)")

            return dataWrapper
        }
        return nil
    }    
}

enum Event: String {
    case ApplicationDidEnterBackground = "applicationDidEnterBackground"
    case ApplicationWillEnterForeground = "applicationWillEnterForeground"
    case ApplicationWillResignActive = "applicationWillResignActive"
    case ApplicationDidBecomeActive = "applicationDidBecomeActive"
    case LocationUpdate = "locationUpdate"
}

enum DataStoreQueryName: String {
	case WatchersForPatch            = "WatchersForPatch"
    case LikersForMessage            = "LikersForMessage"
	case NearbyPatches               = "NearbyPatches"
	case NotificationsForCurrentUser = "NotificationsForCurrentUser"
	case ExplorePatches              = "ExplorePatches"
	case MessagesByUser              = "MessagesByUser"
    case MessagesForPatch            = "MessagesForPatch"
	case PatchesByUser               = "PatchesByUser"
    case PatchesUserIsWatching       = "PatchesUserIsWatching"
    case FavoritePatches             = "FavoritePatches"
}

