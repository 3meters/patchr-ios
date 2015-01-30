//
//  ViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, RMCoreDataStackDelegate {

    private var coreDataStack : RMCoreDataStack!
    private var dataStore : DataStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let coreDataConfiguration = RMCoreDataConfiguration()
        coreDataConfiguration.persistentStoreType = NSInMemoryStoreType
        self.coreDataStack = RMCoreDataStack()
        self.coreDataStack.delegate = self
        self.coreDataStack.constructWithConfiguration(coreDataConfiguration)
        
        self.dataStore = DataStore(managedObjectContext: self.coreDataStack.managedObjectContext, proxibaseClient: ProxibaseClient())
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationViewController as? QueryResultTableViewController {
            viewController.managedObjectContext = self.coreDataStack.managedObjectContext
            viewController.dataStore = self.dataStore
            
            switch segue.identifier! {
            case "do/getNotifications", "patches/near", "do/getEntitiesForEntity watching", "do/getEntitiesForEntity owner", "stats/to/patches/from/messages mostActive", "stats/to/patches/from/users mostPopular":
                let query = Query.insertInManagedObjectContext(self.coreDataStack.managedObjectContext) as Query
                query.name = segue.identifier!
                query.limitValue = 25
                query.path = segue.identifier!.componentsSeparatedByString(" ")[0]
                self.coreDataStack.managedObjectContext.save(nil)
                viewController.query = query
            default:
                NSLog("Unknown segue identifier \(segue.identifier)")
            }
        }
    }

    @IBAction func authenticationButtonAction(sender: UIButton) {
        if self.dataStore.proxibaseClient.authenticated {
            sender.setTitle("Logging out...", forState: UIControlState.Normal)
            self.dataStore.proxibaseClient.signOut({ (response, error) -> Void in
                if error == nil {
                    sender.setTitle("Login", forState: UIControlState.Normal)
                }
            })
        } else {
            sender.setTitle("Logging in...", forState: UIControlState.Normal)
            self.dataStore.proxibaseClient.signIn("rob@robmaceachern.com", password: "test9090", installId: "123456", completion: { (response, error) -> Void in
                if error == nil {
                    sender.setTitle("Logout", forState: UIControlState.Normal)
                }
            })
        }
    }
    
// MARK: RMCoreDataStackDelegate
    
    func coreDataStack(stack: RMCoreDataStack!, didFinishInitializingWithInfo info: [NSObject : AnyObject]!) {
        NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
    }
    
    func coreDataStack(stack: RMCoreDataStack!, failedInitializingWithInfo info: [NSObject : AnyObject]!) {
        NSLog("[%@ %@]", reflect(self).summary, __FUNCTION__)
    }
}

