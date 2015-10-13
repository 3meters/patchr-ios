//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

extension UITextField {
    var isEmpty: Bool {
        return self.text == nil || self.text!.isEmpty
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
        if self.alpha != alpha {
            UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.alpha = alpha
                }, completion: completion)
        }
    }
    
    func fadeOut(duration: NSTimeInterval = 0.3, delay: NSTimeInterval = 0.0, alpha: CGFloat = 0.0, completion: (Bool) -> Void = {(finished: Bool) -> Void in}) {
        if self.alpha != alpha {
            UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.alpha = alpha
                }, completion: completion)
        }
    }

    func showSubviews(level: Int = 0) {
        /* 
         * Utility to show some information about subview frames.
         */
        var indent = ""
        for _ in 0 ..< level {
            indent += "  "
        }
        var count = 0
        for subview in self.subviews {
            Log.d("\(indent)\(count++). \(subview.frame)")
            subview.showSubviews(level + 1)
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

extension UIWindow {
    
    func setRootViewController(rootViewController: UIViewController, animated: Bool) {
        
        if !animated {
            self.rootViewController = rootViewController
            return
        }
        
        UIView.transitionWithView(self,
            duration: 0.65,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: {
                () -> Void in
                
                // The animation enabling/disabling are to address a status bar
                // issue on the destination view controller. http://stackoverflow.com/a/8505364/2247399
                let oldState = UIView.areAnimationsEnabled()
                UIView.setAnimationsEnabled(false)
                self.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            })
            { (_) -> Void in } // Trailing closure
    }
}

extension UIViewController {
    
    // Returns the most recently presented UIViewController (visible)
    class func topMostViewController() -> UIViewController? {
        
        // If the root view is a navigation controller, we can just return the visible ViewController
        if let tabBarController = getTabBarController() {
            if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                return navigationController.visibleViewController
            }
            return tabBarController.selectedViewController
        }
        
        // If the root view is a navigation controller, we can just return the visible ViewController
        if let navigationController = getNavigationController() {
            return navigationController.visibleViewController
        }
        
        // Otherwise, we must get the root UIViewController and iterate through presented views
        if let rootController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            
            var currentController: UIViewController! = rootController
            
            // Each ViewController keeps track of the views it has presented, so we
            // can move from the head to the tail, which will always be the current view
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            
            return currentController
        }
        return nil
    }
    
    // Returns the navigation controller if it exists
    class func getNavigationController() -> UINavigationController? {
        
        if let navigationController = UIApplication.sharedApplication().keyWindow?.rootViewController  {
            return navigationController as? UINavigationController
        }
        return nil
    }
    
    // Returns the navigation controller if it exists
    class func getTabBarController() -> UITabBarController? {
        
        if let controller = UIApplication.sharedApplication().keyWindow?.rootViewController  {
            return controller as? UITabBarController
        }
        return nil
    }
    
    func handleError(error: ServerError, errorActionType: ErrorActionType = .AUTO, var errorAction: ErrorAction = .NONE ) {
        
        /* Show any required ui */
        let alertMessage: String = (error.message != nil ? error.message : error.description != nil ? error.description : "Unknown error")!
        
        if errorActionType == .AUTO || errorActionType == .TOAST {
            Shared.Toast(alertMessage)
            if error.code == .UNAUTHORIZED_SESSION_EXPIRED || error.code == .UNAUTHORIZED_CREDENTIALS {
                errorAction = .SIGNOUT
            }
        }
        else if errorActionType == .ALERT {
            self.Alert(alertMessage)
        }
        
        /* Perform any follow-up actions */
        
        if errorAction == .SIGNOUT {
            /*
             * Error requires that the user signs in again.
             */
            DataController.proxibase.signOut {
                response, error in
                
                if error != nil {
                    Log.w("Error during logout \(error)")
                }
                
                /* Make sure state is cleared */
                LocationController.instance.clearLastLocationAccepted()
                
                let appDelegate               = UIApplication.sharedApplication().delegate as! AppDelegate
                let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("LobbyNavigationController") 
                appDelegate.window!.setRootViewController(destinationViewController, animated: true)
            }
        }
        else if errorAction == .LOBBY {
            /* 
             * Mostly because a more current client version is required. 
             */
            LocationController.instance.clearLastLocationAccepted()
            
            let appDelegate               = UIApplication.sharedApplication().delegate as! AppDelegate
            let destinationViewController = UIStoryboard(name: "Lobby", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("LobbyNavigationController") 
            appDelegate.window!.setRootViewController(destinationViewController, animated: true)
        }
        
        Log.w("Network Error Summary")
        Log.w(error.message)
        Log.w(error.code.rawValue.description)
        Log.w(error.description)
    }
    
    func Alert(title: String?, message: String? = nil, cancelButtonTitle: String = "OK") {
		let alert = AirAlertController(title: title, message: message, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .Cancel, handler: nil))
		self.presentViewController(alert, animated: true) {}
    }
    
    func ActionConfirmationAlert(title: String? = nil, message: String? = nil,
        actionTitle: String, cancelTitle: String, destructConfirmation: Bool = false,
        delegate: AnyObject? = nil, onDismiss: (Bool) -> Void) {
            
		let alert = AirAlertController(title: title, message: message, preferredStyle: .Alert)
		let okAction = UIAlertAction(title: actionTitle, style: .Destructive, handler: { _ in onDismiss(true) })
		let cancelAction = UIAlertAction(title: cancelTitle, style: .Cancel, handler: { _ in onDismiss(false) })
		alert.addAction(okAction)
		alert.addAction(cancelAction)
		if destructConfirmation {
			alert.addTextFieldWithConfigurationHandler() {
				textField in
				textField.addTarget(delegate, action: Selector("alertTextFieldDidChange:"), forControlEvents: .EditingChanged)
			}
			okAction.enabled = false
		}
		self.presentViewController(alert, animated: true, completion: nil)
    }

	func addActivityIndicatorTo(view: UIView, offsetY: Float = 0) -> UIActivityIndicatorView {
		
		let activity: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
		activity.translatesAutoresizingMaskIntoConstraints = false
		activity.color = Colors.brandColorDark
		activity.hidesWhenStopped = true
		view.addSubview(activity)
		
		let centerConstraintX = NSLayoutConstraint(item: activity, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
		let centerConstraintY = NSLayoutConstraint(item: activity, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1, constant: CGFloat(offsetY))
		let widthConstraint = NSLayoutConstraint(item: activity, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
		let heightConstraint = NSLayoutConstraint(item: activity, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
		
		self.view.addConstraints([centerConstraintX, centerConstraintY, widthConstraint, heightConstraint])
		return activity
	}
	
    func setScreenName(name: String) {
        self.sendScreenView(name)
    }
    
    func sendScreenView(name: String) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: name)
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
        let tracker = GAI.sharedInstance().defaultTracker
        let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build()
        tracker.send(trackDictionary as [NSObject: AnyObject])
    }
}

extension UINavigationController {
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if visibleViewController != nil {
            return visibleViewController!.supportedInterfaceOrientations()
        }
        return super.supportedInterfaceOrientations()
    }
    
    public override func shouldAutorotate() -> Bool {
        if visibleViewController != nil {
            return visibleViewController!.shouldAutorotate()
        }
        return super.shouldAutorotate()
    }
}

extension UITabBarController {
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let selected = selectedViewController {
            return selected.supportedInterfaceOrientations()
        }
        return super.supportedInterfaceOrientations()
    }
    
    public override func shouldAutorotate() -> Bool {
        if let selected = selectedViewController {
            return selected.shouldAutorotate()
        }
        return super.shouldAutorotate()
    }
}

extension String {
    
    var length: Int {
        return characters.count
    }
    
    var md5: String! {
        
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format: hash as String)
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

enum ErrorActionType: Int {
    case AUTO
    case ALERT
    case TOAST
    case SILENT
}

enum ErrorAction: Int {
    case NONE
    case SIGNOUT
    case LOBBY
}