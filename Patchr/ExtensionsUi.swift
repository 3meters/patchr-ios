//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

extension UITextField {
    var isEmpty: Bool {
        return self.text == nil || self.text.isEmpty
    }
}

extension UIImage {
    
    func resizeTo(size:CGSize) -> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 1.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func normalizedImage() -> UIImage {
        if self.imageOrientation == UIImageOrientation.Up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
        self.drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: self.size))
        let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
}

extension UIView {
    
    func fadeIn(duration: NSTimeInterval = 0.3, delay: NSTimeInterval = 0.0, alpha: CGFloat = 1.0, completion: ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = alpha
            }, completion: completion)  }
    
    func fadeOut(duration: NSTimeInterval = 0.3, delay: NSTimeInterval = 0.0, alpha: CGFloat = 0.0, completion: (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = alpha
            }, completion: completion)
    }

    func showSubviews(level: Int = 0) {
        /* 
         * Utility to show some information about subview frames. 
         */
        var indent = ""
        for i in 0 ..< level {
            indent += "  "
        }
        var count = 0
        for subview in self.subviews {
            println("\(indent)\(count++). \(subview.frame)")
            subview.showSubviews(level: level + 1)
        }
    }
}

extension UIImageView {
    
    func tintColor(color: UIColor) {
        assert(self.image != nil, "Image must be set before calling tintColor")
        /*
        * Required because xcode IB doesn't handle template mode correctly for ios7
        * http://stackoverflow.com/questions/25997993/how-to-use-template-rendering-mode-in-xcode-6-interface-builder
        */
        if IOS7 {
            let templateImage: UIImage = self.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            self.image = templateImage
        }
        self.tintColor = color
    }
}

extension UIViewController {
    
    func handleError(error: ServerError, errorActionType: ErrorActionType = .AUTO, errorAction: ErrorAction = .NONE ) {
        
        /* Show any required ui */
        
        if errorActionType == .AUTO || errorActionType == .TOAST {
            self.Toast(error.description)
        }
        else if errorActionType == .ALERT {
            self.Alert(error.description)
        }
        
        /* Perform any follow-up actions */
        
        if errorAction == .SIGNOUT {
            /*
             * Error requires that the user signs in again.
             */
            DataController.proxibase.signOut {
                response, error in
                
                if error != nil {
                    NSLog("Error during logout \(error)")
                }
                
                /* Make sure state is cleared */
                LocationController.instance.locationLocked = nil
                
                let appDelegate               = UIApplication.sharedApplication().delegate as! AppDelegate
                let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as! UIViewController
                appDelegate.window!.setRootViewController(destinationViewController, animated: true)
            }
        }
        else if errorAction == .LOBBY {
            /* 
             * Mostly because a more current client version is required. 
             */
            LocationController.instance.locationLocked = nil
            
            let appDelegate               = UIApplication.sharedApplication().delegate as! AppDelegate
            let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("SplashNavigationController") as! UIViewController
            appDelegate.window!.setRootViewController(destinationViewController, animated: true)
        }
        
        println("Network Error Summary")
        println(error.message)
        println(error.code)
        println(error.description)
    }
    
    func Alert(title: String?, message: String? = nil, cancelButtonTitle: String = "OK") {
        
        if objc_getClass("UIAlertController") != nil {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true) {}
        }
        else {
            UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle).show()
        }
    }
    
    func ActionConfirmationAlert(title: String? = nil, message: String? = nil,
        actionTitle: String, cancelTitle: String,
        delegate: AnyObject? = nil, onDismiss: (Bool) -> Void) {
            
            if objc_getClass("UIAlertController") != nil {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: actionTitle, style: .Destructive, handler: { _ in onDismiss(true) }))
                alert.addAction(UIAlertAction(title: cancelTitle, style: .Cancel, handler: { _ in onDismiss(false) }))
                self.presentViewController(alert, animated: true) {}
            }
            else {
                var alert = UIAlertView(title: title, message: message, delegate: delegate, cancelButtonTitle: nil)
                alert.addButtonWithTitle(actionTitle)
                alert.addButtonWithTitle(cancelTitle)
                alert.show()
            }
    }
    
    func Toast(message: String?, duration: NSTimeInterval = 3.0) {
        
        if let controller = DataController.instance.getCurrentViewController() {
            var progress: MBProgressHUD
            progress = MBProgressHUD.showHUDAddedTo(controller.view, animated: true)
            progress.mode = MBProgressHUDMode.Text
            progress.detailsLabelText = message
            progress.margin = 10.0
            progress.yOffset = Float((UIScreen.mainScreen().bounds.size.height / 2) - 100)
            progress.opacity = 0.7
            progress.cornerRadius = 4.0
            progress.detailsLabelColor = Colors.windowColor
            progress.detailsLabelFont = UIFont(name:"HelveticaNeue-Light", size: 16)
            progress.removeFromSuperViewOnHide = true
            progress.userInteractionEnabled = false
            progress.hide(true, afterDelay: duration)
        }
    }
}

extension String {
    var length: Int {
        return count(self)
    }
}

enum ErrorActionType: Int {
    case AUTO
    case ALERT
    case TOAST
}

enum ErrorAction: Int {
    case NONE
    case SIGNOUT
    case LOBBY
}