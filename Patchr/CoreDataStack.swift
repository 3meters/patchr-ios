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
	
	override init(){
		super.init()
		initialize()
	}
	
	func initialize() {
		
		let modelURLs = NSBundle.mainBundle().URLsForResourcesWithExtension("momd", subdirectory: nil)
		let modelURL = modelURLs?.last		
		ZAssert(modelURL, message: "Failed to find model URL")
		
		let mom = NSManagedObjectModel(contentsOfURL: modelURL!)
		ZAssert(mom, message: "Error initializing mom from: \(modelURL!)")
		
		let psc = NSPersistentStoreCoordinator(managedObjectModel: mom!)
		ZAssert(psc, message: "Failed to intitialize persistent store coordinator")
		self.persistentStoreCoordinator = psc

		/* Master on background thread */
		let master: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
		master.persistentStoreCoordinator = psc
		master.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		self.stackWriterContext = master

		/* Main on main thread parented by Master */
		let main: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		main.parentContext = master
		main.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		self.stackMainContext = main

		registerForNotifications()
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let store = try! psc.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
			self.ZAssert(store, message: "Failed to initialize store")
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
				Log.d("Error saving context")
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
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "mainManagedObjectContextDidSave:",
			name: NSManagedObjectContextDidSaveNotification, object: self.stackMainContext)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillResignActive:",
			name: UIApplicationWillResignActiveNotification, object: self.stackMainContext)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreCoordinatorStoresWillChange:",
			name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.persistentStoreCoordinator)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreCoordinatorStoresDidChange:",
			name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.persistentStoreCoordinator)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChanges:",
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
		self.saveContext(self.stackWriterContext, wait: true)	// Commits changes to the store
	}
	
	func appWillResignActive(info: NSNotification) {
		saveContext(self.stackMainContext, wait: true)
		saveContext(self.stackWriterContext, wait: true)
	}
	
	func persistentStoreCoordinatorStoresWillChange(info: NSNotification) {
		saveContext(self.stackMainContext, wait: true)
	}
	
	func persistentStoreCoordinatorStoresDidChange(info: NSNotification) {
		saveContext(self.stackWriterContext, wait: false)
	}
	
	func persistentStoreDidImportUbiquitousContentChanges(info: NSNotification) {
		self.stackMainContext.performBlock {
			self.stackMainContext.mergeChangesFromContextDidSaveNotification(info)
		}
	}
}