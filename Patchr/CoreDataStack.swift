//
//  CoreDataStack.swift
//  Patchr
//
//  Created by Jay Massena on 10/26/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation

class CoreDataStack: NSObject {
    //@formatter:off
    var stackWriterContext:         NSManagedObjectContext!     // On background thread
    var stackMainContext:           NSManagedObjectContext!     // On main thread
    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    var storeUrl:                   NSURL?
    //@formatter:on

    override init() {
        super.init()
        initialize()
    }

    func initialize() {

        guard let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        self.persistentStoreCoordinator = coordinator

        /* Master on background thread */
        let writer: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        writer.persistentStoreCoordinator = coordinator
        writer.name = "WriterContext"
        writer.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writer.undoManager = nil
        self.stackWriterContext = writer

        /* Main on main thread parented by Master */
        let main: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        main.parent = writer
        main.name = "MainContext"
        main.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        main.undoManager = nil
        self.stackMainContext = main

        registerForNotifications()
        
        DispatchQueue.global().async {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let docUrl = urls[urls.endIndex - 1]
            self.storeUrl = docUrl.appendingPathComponent("Patchr.sqlite") as NSURL?
            self.createStore(storeUrl: self.storeUrl!)
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
                    NSInferMappingModelAutomaticallyOption: true]
            try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.storeUrl! as URL, options: options)
        } catch {
            /* Report any error we got. */
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data." as AnyObject?
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            /*
            * Replace this with code to handle the error appropriately. abort() causes the application to
            * generate a crash log and terminate. DO NOT use this function in a shipping application,
            * although it may be useful during development.
            */
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            Log.e("There was an error creating or loading the application's saved data.", breadcrumb: true)
            Log.e((error as NSError).localizedDescription, breadcrumb: true)
            abort()
        }
    }

    func deleteStore(storeUrl: NSURL) {
        if FileManager.default.fileExists(atPath: storeUrl.path!) {
            do {
                for store in self.persistentStoreCoordinator.persistentStores {
                    try self.persistentStoreCoordinator.remove(store)
                }
                try FileManager.default.removeItem(at: storeUrl as URL)
                Log.d("Store deleted")
            } catch {
                Log.w("Store delete failed")
            }
        }
    }

    func replaceStore() {
        deleteStore(storeUrl: self.storeUrl!)
        createStore(storeUrl: self.storeUrl!)
    }

    func resetNew() {
        replaceStore()
    }

    func reset() {

        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = DataController.instance.mainContext
        privateContext.perform {
            privateContext.deleteAllObjects()
            self.saveContext(context: self.stackMainContext, wait: true)
            self.saveContext(context: self.stackWriterContext, wait: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func saveContext(wait: Bool = false) {
        saveContext(context: self.stackMainContext, wait: wait)
    }

    func saveContext(context: NSManagedObjectContext, wait: Bool) {

        func save() {
            do {
                try context.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }

        if context.hasChanges {
            if wait {
                context.performAndWait(save)
            }
            else {
                context.perform(save)
            }
        }
    }

    func registerForNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.mainManagedObjectContextDidSave(info:)),
                                                         name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.stackMainContext)
        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.appWillResignActive(info:)),
                                                         name: NSNotification.Name.UIApplicationWillResignActive, object: self.stackMainContext)
        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.persistentStoreCoordinatorStoresWillChange(info:)),
                                                         name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: self.persistentStoreCoordinator)
        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.persistentStoreCoordinatorStoresDidChange(info:)),
                                                         name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: self.persistentStoreCoordinator)
        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.persistentStoreDidImportUbiquitousContentChanges(info:)),
                                                         name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator)
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
        self.saveContext(context: self.stackWriterContext, wait: true)    // Commits changes to the persisted store
    }

    func appWillResignActive(info: NSNotification) {
        saveContext(context: self.stackMainContext, wait: true)
        saveContext(context: self.stackWriterContext, wait: true)
    }

    func persistentStoreCoordinatorStoresWillChange(info: NSNotification) {
        saveContext(context: self.stackMainContext, wait: true)
    }

    func persistentStoreCoordinatorStoresDidChange(info: NSNotification) {
        saveContext(context: self.stackWriterContext, wait: BLOCKING)
    }

    func persistentStoreDidImportUbiquitousContentChanges(info: NSNotification) {
        self.stackMainContext.perform {
            self.stackMainContext.mergeChanges(fromContextDidSave: info as Notification)
        }
    }
}
