//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class SignInTableViewController: UITableViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextField.text = "rob@robmaceachern.com"
        self.passwordTextField.text = "test9090"
    }
    
    @IBAction func signInButtonAction(sender: NSObject) {
        let proxibaseClient = ProxibaseClient()
        // TODO need installId
        proxibaseClient.signIn(self.emailTextField.text, password: self.passwordTextField.text, installId: "1", completion: { (userId, sessionKey, response, error) -> Void in
            if (error != nil) {
                NSLog("Login error \(error)")
            } else {
                NSLog("Login success")
                // Ideally sessionKey would be stored more securely
                NSUserDefaults.standardUserDefaults().setObject(userId, forKey: "com.3meters.patchr.ios.userId")
                NSUserDefaults.standardUserDefaults().setObject(sessionKey, forKey: "com.3meters.patchr.ios.sessionKey")
                NSUserDefaults.standardUserDefaults().synchronize()
                let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as UIViewController
                appDelegate.window!.setRootViewController(destinationViewController, animated: true)
            }
        })
    }
}
