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
    @IBOutlet weak var signInErrorMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextField.text = "rob@robmaceachern.com"
        self.passwordTextField.text = "test9090"
    }
    
    @IBAction func signInButtonAction(sender: NSObject) {
        signInErrorMessage.text = ""
        ProxibaseClient.sharedInstance.signIn(self.emailTextField.text, password: self.passwordTextField.text) { (response, error) -> Void in
            if (error != nil) {
                NSLog("Login error \(error!)")
                if let loginErrorMessage: AnyObject = (response!["error"] as NSDictionary)["message"] {
                    self.signInErrorMessage.text = loginErrorMessage as? String
                }
            } else {
                NSLog("Login success")

                let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let destinationViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateInitialViewController() as UIViewController
                appDelegate.window!.setRootViewController(destinationViewController, animated: true)
            }
        }
    }
}
