
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

	private var coreDataStack: RMCoreDataStack!

	var managedObjectContext: NSManagedObjectContext!
    var activityDate: Int64

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
        activityDate = Int64(NSDate().timeIntervalSince1970 * 1000)
		super.init()

		let coreDataConfiguration = RMCoreDataConfiguration()
		coreDataConfiguration.persistentStoreType = NSInMemoryStoreType
		coreDataStack = RMCoreDataStack()
		coreDataStack.delegate = self
		coreDataStack.constructWithConfiguration(coreDataConfiguration)

		managedObjectContext = coreDataStack.managedObjectContext
	}

	/*--------------------------------------------------------------------------------------------
	 * Singles
	 *--------------------------------------------------------------------------------------------*/

	func withPatchId(patchId: String, refresh: Bool = false, completion: (Patch?) -> Void) {
        /*
        * - Load a patch for the patch form
        * - Show a patch by id for a notification.
        */
		withEntityType(Patch.self, id: patchId, refresh: refresh) {
			(model) -> Void in
			completion(model as? Patch)
		}
	}

	func withMessageId(messageId: String, refresh: Bool = false, completion: (Message?) -> Void) {
        /*
        * Load a message for the message form.
        */
		withEntityType(Message.self, id: messageId, refresh: refresh) {
			(model) -> Void in
			completion(model as? Message)
		}
	}

	func withUserId(userId: String, refresh: Bool = false, completion: (User?) -> Void) {
        /*
        * - Load users for items in user lists
        * - Load user by id for a notification.
        */
		withEntityType(User.self, id: userId, refresh: refresh) {
			(model) -> Void in
			completion(model as? User)
		}
	}

    func withPlaceId(placeId: String, refresh: Bool = false, completion: (Place?) -> Void) {
        /*
        * - Load a place for the place form
        */
        withEntityType(Place.self, id: placeId, refresh: refresh) {
            (model) -> Void in
            completion(model as? Place)
        }
    }
    
	func withEntityId(entityId: String, refresh: Bool = false, completion: (Entity?) -> Void) {
        /*
        * Used by notifications which only have an entity id to work with.
        */
		switch entityId {
			case let isPatch where entityId.hasPrefix("pa."):
				withPatchId(entityId, refresh: refresh, completion: completion)
            
            case let isPlace where entityId.hasPrefix("pl."):
                withPlaceId(entityId, refresh: refresh, completion: completion)
            
			case let isUser where entityId.hasPrefix("us."):
				withUserId(entityId, refresh: refresh, completion: completion)
            
			case let isMessage where entityId.hasPrefix("me."):
				withMessageId(entityId, refresh: refresh, completion: completion)
            
			default:
				NSLog("WARNING: withEntity not currently implemented for id of form \(entityId)")
				completion(nil)
		}
	}

    private func withEntityType(entityType: ServiceBase.Type, id: String, refresh: Bool = false, completion: (ServiceBase?) -> Void) {
            
            /* Pull from data model if available */
            var entity = entityType.fetchOneById(id, inManagedObjectContext: managedObjectContext) as ServiceBase!
            
            /* If not in data model or caller wants the freshest available then call service */
            if refresh || entity == nil {
                
                var criteria: [String: AnyObject] = [:]
                if entity != nil {
                    criteria = entity.criteria()
                }
                
                fetchByEntityType(entityType, withId: id, criteria: criteria, completion: {
                    (response, error) -> Void in
                    
                    if error != nil {
                        completion(nil)
                    }
                    else {
                        /* Turn maps and arrays into objects */
                        if let dictionary = response as? [NSObject:AnyObject] {

                            let dataWrapper = ServiceData()
                            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
                            
                            if !dataWrapper.noopValue {
                                if let entityDictionaries = dataWrapper.data as? [[NSObject:AnyObject]] {
                                    if entityDictionaries.count == 1 {
                                        entity = entityType.fetchOrInsertOneById(id, inManagedObjectContext: self.managedObjectContext)
                                        entityType.setPropertiesFromDictionary(entityDictionaries[0], onObject: entity, mappingNames: true)
                                    }
                                }
                                
                                /* Poke each impacted queryItem to trigger NSFetchedResultsController callbacks */
                                for queryItem in entity.queryItems {
                                    if let result = queryItem as? QueryItem {
                                        result.modifiedDate = NSDate()
                                    }
                                }
                                
                                self.managedObjectContext!.save(nil)	// Makes changes visible
                            }
                        }
                        completion(entity)
                    }
                })
            }
            else {
                completion(entity)
            }
    }
    
    private func fetchByEntityType(type: ServiceBase.Type, withId id: String, criteria: Dictionary<String,AnyObject> = [:], completion: (response:AnyObject?, error:NSError?) -> Void) {
        if let patchType = type as? Patch.Type {
            DataController.proxibase.fetchPatchById(id, criteria:criteria, completion: completion)
        }
        else if let messageType = type as? Message.Type {
            DataController.proxibase.fetchMessageById(id, criteria:criteria, completion: completion)
        }
        else if let placeType = type as? Place.Type {
            DataController.proxibase.fetchPlaceById(id, criteria:criteria, completion: completion)
        }
        else if let userType = type as? User.Type {
            DataController.proxibase.fetchUserById(id, criteria:criteria, completion: completion)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Collections
     *--------------------------------------------------------------------------------------------*/
    
    func refreshItemsFor(query: Query, force: Bool = false, paging: Bool = false, completion: (queryItems: [QueryItem], query: Query, error: NSError?) -> Void) {
        
        if !query.validValue {
            completion(queryItems: [], query: query, error: nil)
            return
        }

		/* Callback when service call is complete */
		func refreshCompletion(response: AnyObject?, error: NSError?) -> Void {

			if error != nil {
                completion(queryItems: [], query: query, error: error)
				return
			}
            
            /* If service query completed as a noop then bail */
            let returnValue = handleServiceDataResponseForQuery(query, response: response!)
            
            if (returnValue.serviceData.noopValue) {
                completion(queryItems: [], query: query, error: error)
                return
            }
            
            query.moreValue = returnValue.serviceData.moreValue

			let queryItems = returnValue.queryItems
			/* 
             * Previous query exection might have put objects in the store that are no
             * longer part of the query so delete them.
             */
            let queryItemSet = Set(queryItems)  // If for some reason there are any duplicates, this will remove them
            if query.offsetValue == 0 {
                for obj in query.queryItems {
                    if let item = obj as? QueryItem {
                        if !queryItemSet.contains(item) {
                            managedObjectContext!.deleteObject(item)
                        }
                    }
                }
            }
            
			managedObjectContext!.save(nil)

            completion(queryItems: queryItems, query: query, error: error)
		}
        
        let coordinate = LocationController.instance.currentLocation()?.coordinate
        let defaultRadius: Int32 = 10000

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
        if entity != nil && entity.creator != nil {
            isOwner = (entity.creator.entityId == UserController.instance.currentUser.id_)
        }

        var skip = 0
        if paging {
            skip = Int(ceil(Float(query.offsetValue) / Float(query.pageSizeValue)) * Float(query.pageSizeValue))
        }
        
        query.criteriaValue = false
        var criteria: [String: AnyObject] = [:]
		if !force && query.executedValue && entity != nil && !paging {
			criteria = entity!.criteria(activityOnly: true)
            query.criteriaValue = true
		}
        
		switch query.name {
			case DataStoreQueryName.NearbyPatches.rawValue:
                query.criteriaValue = false
                DataController.proxibase.fetchNearbyPatches(coordinate, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.NotificationsForCurrentUser.rawValue:
                query.criteriaValue = false
                DataController.proxibase.fetchNotifications(skip: skip, completion: refreshCompletion)
            
			case DataStoreQueryName.ExplorePatches.rawValue:
                query.criteriaValue = false
                DataController.proxibase.fetchInterestingPatches(coordinate, skip: skip, completion: refreshCompletion)
            
			case DataStoreQueryName.MessagesByUser.rawValue:
                DataController.proxibase.fetchMessagesOwnedByUser(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.MessagesForPatch.rawValue:
				DataController.proxibase.fetchMessagesForPatch(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.LikersForPatch.rawValue:
				DataController.proxibase.fetchUsersThatLikePatch(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)

			case DataStoreQueryName.WatchersForPatch.rawValue:
                DataController.proxibase.fetchUsersThatWatchPatch(entityId, isOwner: isOwner, criteria: criteria, skip: skip, completion: refreshCompletion)

            case DataStoreQueryName.LikersForMessage.rawValue:
                DataController.proxibase.fetchUsersThatLikeMessage(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
            case DataStoreQueryName.PatchesByUser.rawValue:
                DataController.proxibase.fetchPatchesOwnedByUser(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
            case DataStoreQueryName.PatchesUserIsWatching.rawValue:
                DataController.proxibase.fetchPatchesUserIsWatching(entityId, criteria: criteria, skip: skip, completion: refreshCompletion)
            
			default:
				assert(false, "No refreshResultsFor implementation for query name \(query.name)")
		}
	}

	/*--------------------------------------------------------------------------------------------
	 * Methods
	 *--------------------------------------------------------------------------------------------*/

	private func handleServiceDataResponseForQuery(query: Query, response: AnyObject) -> (serviceData:ServiceData, queryItems:[QueryItem]) {

		var items: [QueryItem] = []
		let dataWrapper            = ServiceData()
		if let dictionary = response as? [NSObject:AnyObject] {

			ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
            if (dataWrapper.noopValue) {
                return (dataWrapper, [])
            }
            
			if let entityDictionaries = dataWrapper.data as? [[String:NSObject]] {

				var itemPosition = 0 + query.offsetValue
				for entityDictionary in entityDictionaries {

					if let schema = entityDictionary["schema"] as? String {
						if let modelType = schemaDictionary[schema] {

							var entity: Entity
							if let entityId = entityDictionary["_id"] as? String {
								entity = modelType.fetchOrInsertOneById(entityId, inManagedObjectContext: managedObjectContext) as! Entity
							}
							else {
								entity = modelType.insertInManagedObjectContext(managedObjectContext) as! Entity
							}

							modelType.setPropertiesFromDictionary(entityDictionary, onObject: entity, mappingNames: true)

							var queryItem: QueryItem!;
							for obj in entity.queryItems {
								let existingQueryItem = obj as! QueryItem
								if existingQueryItem.query == query {
									queryItem = existingQueryItem
								}
							}

							if queryItem == nil {
								queryItem = QueryItem.insertInManagedObjectContext(managedObjectContext) as! QueryItem
							}

                            queryItem.query = query     // Sets both query and query.queryItems
							queryItem.object = entity	// The only place that associates an entity with a query item
							queryItem.positionValue = Int64(itemPosition++)
							queryItem.sortDate = entity.sortDate
                            
                            if let patch = entity as? Patch {
                                queryItem.distanceValue = patch.distanceValue
                            }

							items.append(queryItem)
						}
						else {
							assert(false, "Unknown schema: \(schema)")
						}
					}
					else {
						assert(false, "No schema for object \(entityDictionary)")
					}
				}
			}
		}
		return (dataWrapper, items)
	}
    
    func dataWrapperForResponse(response: AnyObject) -> ServiceData? {
        if let dictionary = response as? [NSObject:AnyObject] {
            let dataWrapper = ServiceData()
            ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper, mappingNames: false)
            return dataWrapper
        }
        return nil
    }
    
    // Returns the most recently presented UIViewController (visible)
    func getCurrentViewController() -> UIViewController? {
        
        // If the root view is a navigation controller, we can just return the visible ViewController
        if let navigationController = getNavigationController() {
            return navigationController.visibleViewController
        }
        
        // Otherwise, we must get the root UIViewController and iterate through presented views
        if let rootController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            
            var currentController: UIViewController! = rootController
            
            // Each ViewController keeps track of the views it has presented, so we
            // can move from the head to the tail, which will always be the current view
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            
            return currentController
        }
        return nil
    }
    
    // Returns the navigation controller if it exists
    func getNavigationController() -> UINavigationController? {
        
        if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController  {
            return navigationController as? UINavigationController
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
	case LikersForPatch              = "LikersForPatch"
	case WatchersForPatch            = "WatchersForPatch"
    case LikersForMessage            = "LikersForMessage"
	case NearbyPatches               = "NearbyPatches"
	case NotificationsForCurrentUser = "NotificationsForCurrentUser"
	case ExplorePatches              = "ExplorePatches"
	case MessagesByUser              = "MessagesByUser"
    case MessagesForPatch            = "MessagesForPatch"
	case PatchesByUser               = "PatchesByUser"
    case PatchesUserIsWatching       = "PatchesUserIsWatching"
}

extension DataController: RMCoreDataStackDelegate {
    
	func coreDataStack(stack: RMCoreDataStack!, didFinishInitializingWithInfo info: [NSObject:AnyObject]!) {
		NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
	}

	func coreDataStack(stack: RMCoreDataStack!, failedInitializingWithInfo info: [NSObject:AnyObject]!) {
		NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
	}
}


