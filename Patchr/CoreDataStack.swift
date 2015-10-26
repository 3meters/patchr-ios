//
//  CoreDataStack.swift
//  Patchr
//
//  Created by Jay Massena on 10/26/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation

class CoreDataStack: NSObject {
	
	var managedObjectContext: NSManagedObjectContext!
	var privateContext: NSManagedObjectContext!
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
		
		let pc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
		pc.persistentStoreCoordinator = psc
		pc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		self.privateContext = pc
		
		let mc: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		mc.parentContext = pc
		mc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		self.managedObjectContext = mc
		
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
		saveContext(self.managedObjectContext, wait: wait)
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
			name: NSManagedObjectContextDidSaveNotification, object: self.managedObjectContext)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillResignActive:",
			name: UIApplicationWillResignActiveNotification, object: self.managedObjectContext)
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
		saveContext(self.privateContext, wait: false)
	}
	
	func appWillResignActive(info: NSNotification) {
		saveContext(self.managedObjectContext, wait: true)
		saveContext(self.privateContext, wait: true)
	}
	
	func persistentStoreCoordinatorStoresWillChange(info: NSNotification) {
		saveContext(self.managedObjectContext, wait: true)
	}
	
	func persistentStoreCoordinatorStoresDidChange(info: NSNotification) {
		saveContext(self.privateContext, wait: false)
	}
	
	func persistentStoreDidImportUbiquitousContentChanges(info: NSNotification) {
		self.managedObjectContext.performBlock {
			self.managedObjectContext.mergeChangesFromContextDidSaveNotification(info)
		}
	}
}
