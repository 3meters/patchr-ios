//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {

    @IBAction func signInButtonAction(sender: UIButton) {
        let alertController = UIAlertController(title: "Sign In", message: "Sign in with your email and password", preferredStyle: UIAlertControllerStyle.Alert)
        
        let loginAction = UIAlertAction(title: "Sign In", style: .Default) { (_) in
            let loginTextField = alertController.textFields![0] as UITextField
            let passwordTextField = alertController.textFields![1] as UITextField
            
            let proxibaseClient = ProxibaseClient()
            // TODO need installId
            proxibaseClient.signIn(loginTextField.text, password: passwordTextField.text, installId: "1", completion: { (userId, sessionKey, response, error) -> Void in
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
        
        
        let forgotPasswordAction = UIAlertAction(title: "Forgot Password", style: .Destructive) { (_) in }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Email"
            textField.text = "rob@robmaceachern.com"
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                loginAction.enabled = textField.text != ""
            }
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
            textField.text = "test9090"
        }
        
        let loginTextField = alertController.textFields![0] as UITextField
        let passwordTextField = alertController.textFields![1] as UITextField
        loginAction.enabled = (loginTextField.text != "") && (passwordTextField.text != "")
        
        alertController.addAction(loginAction)
        alertController.addAction(forgotPasswordAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }


}
