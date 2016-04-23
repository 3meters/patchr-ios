//
//  CoreDataStack.swift
//  Patchr
//
//  Created by Jay Massena on 10/26/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation

class CoreDataStack: NSObject {

	var stackWriterContext:         NSManagedObjectContext!		// On background thread
	var stackMainContext:           NSManagedObjectContext!		// On main thread
	var persistentStoreCoordinator: NSPersistentStoreCoordinator!
	var storeUrl: NSURL?
	
	override init(){
		super.init()
		initialize()
	}
	
	func initialize() {
		
		guard let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension:"momd") else {
			fatalError("Error loading model from bundle")
		}
		
		guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
			fatalError("Error initializing mom from: \(modelURL)")
		}
		
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		self.persistentStoreCoordinator = coordinator

		/* Master on background thread */
		let writer: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
		writer.persistentStoreCoordinator = coordinator
		writer.name = "WriterContext"
		writer.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		writer.undoManager = nil
		self.stackWriterContext = writer

		/* Main on main thread parented by Master */
		let main: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		main.parentContext = writer
		main.name = "MainContext"
		main.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		main.undoManager = nil
		self.stackMainContext = main

		registerForNotifications()
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			
			let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
			let docUrl = urls[urls.endIndex-1]
			self.storeUrl = docUrl.URLByAppendingPathComponent("Patchr.sqlite")
			self.createStore(self.storeUrl!)
		}
	}
	
	func createStore(storeUrl: NSURL) {
		do {
			/*
			* Light migration supported for the following changes only:
			* https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html
			*
			* - Add or remove a property (attribute or relationship).
			* - Make a nonoptional property optional.
			* - Make an optional attribute nonoptional, as long as you provide a default value.
			* - Add or remove an entity.
			* - Rename a property.
			* - Rename an entity.
			*/
			let options = [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true ]
			try self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeUrl!, options: options)
		}
		catch {
			/* Report any error we got. */
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
			dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			/*
			* Replace this with code to handle the error appropriately. abort() causes the application to
			* generate a crash log and terminate. DO NOT use this function in a shipping application,
			* although it may be useful during development.
			*/
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}
	}
	
	func deleteStore(storeUrl: NSURL) {
		if NSFileManager.defaultManager().fileExistsAtPath(storeUrl.path!) {
			do {
				for store in self.persistentStoreCoordinator.persistentStores {
					try self.persistentStoreCoordinator.removePersistentStore(store)
				}
				try NSFileManager.defaultManager().removeItemAtURL(storeUrl)
				Log.d("Store deleted")
			}
			catch {
				Log.w("Store delete failed")
			}
		}
	}
	
	func replaceStore() {
		deleteStore(self.storeUrl!)
		createStore(self.storeUrl!)
	}
	
	func resetNew() {
		replaceStore()
	}
	
	func reset() {
		
		let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
		privateContext.parentContext = DataController.instance.mainContext
		privateContext.performBlock {
			privateContext.deleteAllObjects()
			self.saveContext(self.stackMainContext, wait: true)
			self.saveContext(self.stackWriterContext, wait: true)
		}
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func saveContext(wait: Bool = false) {
		saveContext(self.stackMainContext, wait: wait)
	}
	
	func saveContext(context: NSManagedObjectContext, wait: Bool) {
		
		func save() {
			do {
				try context.save()
			}
			catch {
				fatalError("Failure to save context: \(error)")
			}
		}
		
		if context.hasChanges {
			if wait {
				context.performBlockAndWait(save)
			}
			else {
				context.performBlock(save)
			}
		}
	}

	func registerForNotifications() {
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataStack.mainManagedObjectContextDidSave(_:)),
			name: NSManagedObjectContextDidSaveNotification, object: self.stackMainContext)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataStack.appWillResignActive(_:)),
			name: UIApplicationWillResignActiveNotification, object: self.stackMainContext)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataStack.persistentStoreCoordinatorStoresWillChange(_:)),
			name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.persistentStoreCoordinator)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataStack.persistentStoreCoordinatorStoresDidChange(_:)),
			name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.persistentStoreCoordinator)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreDataStack.persistentStoreDidImportUbiquitousContentChanges(_:)),
			name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.persistentStoreCoordinator)
	}
	
	func ZAssert(test: AnyObject?, message: String) {
		if (test != nil) {
			return
		}
		
		print(message)
		
		#if DEBUG
			let exception = NSException()
			exception.raise()
		#endif
	}
	
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/
	
	func mainManagedObjectContextDidSave(info: NSNotification) {
		self.saveContext(self.stackWriterContext, wait: true)	// Commits changes to the persisted store
	}
	
	func appWillResignActive(info: NSNotification) {
		saveContext(self.stackMainContext, wait: true)
		saveContext(self.stackWriterContext, wait: true)
	}
	
	func persistentStoreCoordinatorStoresWillChange(info: NSNotification) {
		saveContext(self.stackMainContext, wait: true)
	}
	
	func persistentStoreCoordinatorStoresDidChange(info: NSNotification) {
		saveContext(self.stackWriterContext, wait: BLOCKING)
	}
	
	func persistentStoreDidImportUbiquitousContentChanges(info: NSNotification) {
		self.stackMainContext.performBlock {
			self.stackMainContext.mergeChangesFromContextDidSaveNotification(info)
		}
	}
}
