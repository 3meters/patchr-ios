//
//  DebugViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-02.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit


class DebugViewController: UIViewController
{
    @IBOutlet weak var serverURIField: UITextField!

    @IBOutlet weak var serverControl: UISegmentedControl!
    
    let userDefaults = { NSUserDefaults.standardUserDefaults() }()
    
    var uriAtStart: String = ""
    
    private func updateSegmentControl()
    {
        if serverURIField.text == ProxibaseClient.sharedInstance.StagingURI
        {
            serverControl.selectedSegmentIndex = 0
        }
        else if serverURIField.text == ProxibaseClient.sharedInstance.ProductionURI
        {
            serverControl.selectedSegmentIndex = 1
        }
        else
        {
            serverControl.selectedSegmentIndex = -1 /*none*/
        }
    }
    
    var observerObject: TextFieldChangeObserver?
    
    override func viewWillAppear(animated: Bool) {
    
        super.viewWillAppear(animated)
        serverURIField.text = userDefaults.stringForKey("com.3meters.patchr.ios.serverURI")
        
        observerObject = TextFieldChangeObserver(serverURIField) { [unowned self] in
            self.updateSegmentControl()
        }
        uriAtStart = serverURIField.text
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        userDefaults.setObject(serverURIField.text, forKey:"com.3meters.patchr.ios.serverURI")

        observerObject?.stopObserving()

        // If the URI changed and we were signed in then sign out
        if uriAtStart != serverURIField.text {
            if ProxibaseClient.sharedInstance.authenticated {
                ProxibaseClient.sharedInstance.signOut() { _, _ in }
            }
        }
    }

    @IBAction func serverControlAction(sender: AnyObject)
    {
        if serverControl.selectedSegmentIndex == 0 {
            serverURIField.text = ProxibaseClient.sharedInstance.StagingURI
        } else if serverControl.selectedSegmentIndex == 1 {
            serverURIField.text = ProxibaseClient.sharedInstance.ProductionURI
        }
    }
    

    @IBAction func testButtonAction(sender: AnyObject)
    {
        println("test")
    }
}
