
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

	var coreDataStack: CoreDataStack!

	var mainContext: NSManagedObjectContext!
	
    var activityDateInsertDeletePatch	: Int64
	var activityDateInsertDeleteMessage	: Int64
	var activityDateWatching			: Int64

    var currentPatch:         Patch?    // Currently used for message context
	
	let backgroundOperationQueue = NSOperationQueue()
	let imageOperationQueue = NSOperationQueue()
	let backgroundDispatch: dispatch_queue_t
	
	lazy var schemaDictionary: [String: ServiceBase.Type] = {
		return [
            "message": Message.self,
			"notification": Notification.self,
			"patch": Patch.self,
			"user": User.self
		]
	}()

	private override init() {
		
		let activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
        self.activityDateInsertDeletePatch = activityDate
		self.activityDateInsertDeleteMessage = activityDate
		self.activityDateWatching = activityDate
		
		self.backgroundOperationQueue.name = "Background queue"
		self.imageOperationQueue.name = "Image processing queue"
		self.backgroundDispatch = dispatch_queue_create("background_queue", nil)
		
		super.init()
		
		self.coreDataStack = CoreDataStack()
		self.mainContext = self.coreDataStack.stackMainContext
	}
	
	func saveContext(wait: Bool) {
		self.coreDataStack.saveContext(self.mainContext, wait: wait)
	}

    func saveContext(context: NSManagedObjectContext, wait: Bool) {
        self.coreDataStack.saveContext(context, wait: wait)
    }

	func reset() {
		self.coreDataStack.reset()
		self.coreDataStack = CoreDataStack()
		self.mainContext = self.coreDataStack.stackMainContext
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Singles
	 *--------------------------------------------------------------------------------------------*/

	func withPatchId(patchId: String, refresh: Bool = false, completion: (NSManagedObjectID?, error: NSError?) -> Void) {
        /*
        * - Load a patch for the patch form
        * - Show a patch by id for a notification.
        */
		withEntityType(Patch.self, entityId: patchId, refresh: refresh) {
			objectId, error in
			completion(objectId, error: error)
		}
	}

	func withMessageId(messageId: String, refresh: Bool = false, blockCriteria: Bool = false, completion: (NSManagedObjectID?, error: NSError?) -> Void) {
        /*
        * Load a message for the message form.
        */
		withEntityType(Message.self, entityId: messageId, refresh: refresh, blockCriteria: blockCriteria) {
			objectId, error in
			completion(objectId, error: error)
		}
	}

	func withUserId(userId: String, refresh: Bool = false, completion: (NSManagedObjectID?, error: NSError?) -> Void) {
        /*
        * - Load users for items in user lists
        * - Load user by id for a notification.
        */
		withEntityType(User.self, entityId: userId, refresh: refresh) {
			objectId, error in
			completion(objectId, error: error)
		}
	}

    func withEntityId(entityId: String, refresh: Bool = false, completion: (NSManagedObjectID?, error: NSError?) -> Void) {
        /*
        * Used by notifications which only have an entity id to work with.
        */
		switch entityId {
			case _ where entityId.hasPrefix("pa."):
				withPatchId(entityId, refresh: refresh, completion: completion)
            
			case _ where entityId.hasPrefix("us."):
				withUserId(entityId, refresh: refresh, completion: completion)
            
			case _ where entityId.hasPrefix("me."):
				withMessageId(entityId, refresh: refresh, completion: completion)
            
			default:
				Log.w("WARNING: withEntity not currently implemented for id of form \(entityId)")
				completion(nil, error: nil)
		}
	}

	private func withEntityType(entityType: ServiceBase.Type,
		entityId: String,
		refresh: Bool = false,
		blockCriteria: Bool = false,
		completion: (NSManagedObjectID?, error: NSError?) -> Void) {
		
		/* Pull from data model if available */
		let modelEntity = entityType.fetchOneById(entityId, inManagedObjectContext: mainContext) as ServiceBase!
		
		/* If not in data model or caller wants the freshest available then call service */
		if refresh || modelEntity == nil {
			
			var criteria: [String: AnyObject] = [:]
			var objectId: NSManagedObjectID?
			if modelEntity != nil {
				objectId = modelEntity.objectID
				if !blockCriteria {
					criteria = modelEntity.criteria()
				}
			}
			
			Utils.stopwatch2.start("Entity", message: "\(entityType)")
			
			fetchByEntityType(entityType, withId: entityId, criteria: criteria, completion: {
				response, error in
				
				/* Returns on background thread */
				if modelEntity != nil {
					guard !self.objectHasBeenDeleted(modelEntity) else {
						return
					}
				}
				
				if let _ = ServerError(error) {
					completion(nil, error: error)
				}
				else {
					let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
					privateContext.parentContext = DataController.instance.mainContext
					
					privateContext.performBlock {
						Utils.stopwatch2.segmentTime("\(entityType): network call finished")
						
						/* Turn maps and arrays into objects */
						if let dictionary = response as? [NSObject:AnyObject] {
							
							let dataWrapper = ServiceData()
							ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper)
							Utils.stopwatch2.segmentNote("\(entityType): service time: \(dataWrapper.time)ms")
							
							if !dataWrapper.noopValue {
								if let entityDictionaries = dataWrapper.data as? [[NSObject:AnyObject]] {
									if entityDictionaries.count == 1 {
										
										let entity = entityType.fetchOrInsertOneById(entityId, inManagedObjectContext: privateContext)
										entityType.setPropertiesFromDictionary(entityDictionaries[0], onObject: entity!)
										entity!.refreshedValue = true
										objectId = entity?.objectID
										if blockCriteria {
											entity!.decoratedValue = true
										}
										
										/* Poke each impacted queryItem to trigger NSFetchedResultsController callbacks */
										for queryItem in entity!.queryItems {
											if let result = queryItem as? QueryItem {
												result.modifiedDate = NSDate()
											}
										}
									}
								}
								
								/* Persist the changes and triggers notifications to observers */
								DataController.instance.saveContext(privateContext, wait: true)
								DataController.instance.saveContext(false)				// Main context
							}
						}
						completion(objectId, error: nil)
						Utils.stopwatch2.stop("\(entityType)")
					}
				}
			})
		}
		else {
			completion(modelEntity.objectID, error: nil)
		}
    }
	
    private func fetchByEntityType(type: ServiceBase.Type, withId id: String, criteria: Dictionary<String,AnyObject> = [:], completion: (response: AnyObject?, error: NSError?) -> Void) {
        if let _ = type as? Patch.Type {
            DataController.proxibase.fetchPatchById(id, criteria:criteria, completion: completion)
        }
        else if let _ = type as? Message.Type {
            DataController.proxibase.fetchMessageById(id, criteria:criteria, completion: completion)
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
		let query = self.mainContext.objectWithID(queryId) as! Query
		
        if query.name == DataStoreQueryName.NotificationsForCurrentUser.rawValue && !UserController.instance.authenticated {
            completion(queryItems: [], query: query, error: nil)
            return
        }

        let coordinate = LocationController.instance.lastLocationAccepted()?.coordinate

        var entity: ServiceBase!
        var entityId: String!
		
        /* We only get here if either entity or entityId are available */
		
        if query.contextEntity != nil {
            entity = query.contextEntity
            entityId = query.contextEntity.id_
        }
		else {
			entityId = query.entityId
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
        
        var criteria: [String: AnyObject] = [:]
		if !force && query.executedValue && entity != nil && !paging {
			criteria = entity!.criteria(true)
		}
		
		Utils.stopwatch1.start("List", message: "\(query.name)")
		
		/*--------------------------------------------------------------------------------------------
		* Callback
		*--------------------------------------------------------------------------------------------*/
		
		func refreshCompletion(response: AnyObject?, error: NSError?) -> Void {
			/*
			* Returns on background thread
			*/
			guard !objectHasBeenDeleted(query) else {
				return
			}
			
			guard error == nil else {
				let query = self.mainContext.objectWithID(queryId) as! Query
				completion(queryItems: [], query: query, error: error)
				return
			}
			
			/* Use a private context */
			
			let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
			privateContext.parentContext = DataController.instance.mainContext
			privateContext.performBlock {
				
				let query = privateContext.objectWithID(queryId) as! Query
				Utils.stopwatch1.segmentTime("\(query.name): network call finished")
				
				/* Turn response entities into managed entities */
				let returnValue = self.handleServiceDataResponseForQuery(query, response: response!, context: privateContext)
				
				/* If service query completed as a noop then bail */
				if (returnValue.serviceData.noopValue) {
					completion(queryItems: [], query: query, error: error)
					return
				}
				
				/* So we can provide a hint that paging is available */
				query.moreValue = (returnValue.serviceData.moreValue && returnValue.serviceData.countValue > 0)
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
								privateContext.deleteObject(existingQueryItem) // Does not throw
							}
						}
					}
				}
				
				/* Persist the changes and triggers notifications to observers */
				DataController.instance.saveContext(privateContext, wait: true)
				DataController.instance.saveContext(false)						// Main context
				Utils.stopwatch1.segmentTime("\(query.name): context saved")
				
				/* Sets query.executed and query.offsetDate but doesn't do anything with queryItems */
				completion(queryItems: queryItems, query: query, error: error)
				Utils.stopwatch1.stop("\(query.name)")
				
			}
		}
		
		switch query.name {
			case DataStoreQueryName.NearbyPatches.rawValue:
                DataController.proxibase.fetchNearbyPatches(coordinate, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.NotificationsForCurrentUser.rawValue:
                DataController.proxibase.fetchNotifications(skip, completion: refreshCompletion)
            
			case DataStoreQueryName.ExplorePatches.rawValue:
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
	
	private func handleServiceDataResponseForQuery(query: Query, response: AnyObject, context: NSManagedObjectContext) -> (serviceData:ServiceData, queryItems:[QueryItem]) {

		var queryItems: [QueryItem] = []
		let dataWrapper = ServiceData()
		if let dictionary = response as? [NSObject:AnyObject] {

			ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper)
			Utils.stopwatch1.segmentNote("\(query.name): service time: \(dataWrapper.time)ms")

            if (dataWrapper.noopValue) {
                return (dataWrapper, [])
            }
            
			if var entityDictionaries = dataWrapper.data as? [[NSObject: AnyObject]] {
                
                /* Append the sidecar maps if any */
                if let sidecar = query.sidecar as? [[NSObject: AnyObject]] where sidecar.count > 0 {
					
                    /* Find date brackets in current set */
                    var startDate = NSDate(timeIntervalSince1970: 0)
                    var endDate = NSDate()
                    for entityDictionary in entityDictionaries {
                        if let itemDateValue = entityDictionary["sortDate"] as? Int {
							let itemDate = NSDate(timeIntervalSince1970: NSTimeInterval(itemDateValue / 1000))
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
                        if let itemDateValue = sidecarDictionary["sortDate"] as? Int {
							let itemDate = NSDate(timeIntervalSince1970: NSTimeInterval(itemDateValue / 1000))
							if query.offsetValue == 0 {
								if itemDate >= endDate {
									entityDictionaries.append(sidecarDictionary)
								}
							}
							else {
								if itemDate <= query.offsetDate && itemDate >= endDate {
									entityDictionaries.append(sidecarDictionary)
								}
							}
                        }
                    }
					Utils.stopwatch1.segmentTime("\(query.name): sidecar processed")
                }

				var itemPosition = 0 + query.offsetValue
				let location = LocationController.instance.lastLocationFromManager()

				for entityDictionary in entityDictionaries {

					if let schema = entityDictionary["schema"] as? String, let entityType = schemaDictionary[schema] {
                        /*
                         * We either create a new entity or update an existing entity. If existing then
                         * we keep the same instance and overwrite the properties included in the downloaded
                         * entity retaining any other properties including local ones.
                         */
						let entityId = ((entityDictionary["_id"] != nil) ? entityDictionary["_id"] : entityDictionary["id"]) as! String // Notifications use "id", everything else from service is "_id"
                        let entity = entityType.fetchOrInsertOneById(entityId, inManagedObjectContext: context) as! Entity
						
                        /* Transfer the properties: Updates the object if it was already in the model */
                        entityType.setPropertiesFromDictionary(entityDictionary, onObject: entity)
						
						/* A tiny bit of fixup */
						if let user = entity as? User where UserController.instance.authenticated {
							if user.email == nil && user.id_ == UserController.instance.currentUser.id_ {
								user.email = UserController.instance.currentUser.email
							}
						}
                        
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
                            queryItem = QueryItem.insertInManagedObjectContext(context) as! QueryItem
                        }

                        /* Set properties */
                        queryItem.query = query     // Sets both query and query.queryItems
                        queryItem.object = entity	// The only place that associates an entity with a query item
                        queryItem.positionValue = Int64(itemPosition++)
                        queryItem.sortDate = entity.sortDate
						
                        if let patch = entity as? Patch {
                            if let distance = patch.distanceFrom(location) {
                                queryItem.distanceValue = distance
                            }
                        }

                        queryItems.append(queryItem)
					}
					else {
						assert(false, "Missing or unknown schema for object \(entityDictionary)")
					}
				}
				Utils.stopwatch1.segmentTime("\(query.name): list items processed")

			}
		}
        return (dataWrapper, queryItems)    // Includes existing and new, could still have orphans
	}
	
	func objectHasBeenDeleted(object: NSManagedObject) -> Bool {
		if object.deleted {
			return true
		}
		if object.managedObjectContext == nil {
			return true
		}
		do {
			try self.mainContext.existingObjectWithID(object.objectID)
		}
		catch {
			return true
		}
		return false
	}
	
    func dataWrapperForResponse(response: AnyObject) -> ServiceData? {
        if let dictionary = response as? [NSObject:AnyObject] {
            let dataWrapper = ServiceData()
            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper)
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

