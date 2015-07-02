//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

public class AirUi: NSObject {

    public static let instance = AirUi()

	func showPhotoBrowser(image: UIImage!, view: UIView!, viewController: UIViewController!){
        /*
        * Create browser (must be done each time photo browser is displayed. Photo
        * browser objects cannot be re-used)
        */
        var photo = IDMPhoto(image:image)
        var photos = Array([photo])
        var browser = IDMPhotoBrowser(photos:photos as [AnyObject], animatedFromView: view)
        
        browser.usePopAnimation = true
        browser.scaleImage = image
        browser.useWhiteBackgroundColor = false
        browser.disableVerticalSwipe = false
        browser.forceHideStatusBar = false
        
        viewController.presentViewController(browser, animated:true, completion:nil)
    }
    
    func setTabBarVisible(visible:Bool, animated:Bool, viewController: UIViewController!) {
        
        //* This cannot be called before viewDidLayoutSubviews(), because the frame is not set before this time
        
        // bail if the current state matches the desired state
        if (tabBarIsVisible(viewController) == visible) { return }
        
        // get a frame calculation ready
        let frame = viewController.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let offsetY = (visible ? -height! : height)
        
        // zero duration means no animation
        let duration:NSTimeInterval = (animated ? 0.3 : 0.0)
        
        //  animate the tabBar
        if frame != nil {
            UIView.animateWithDuration(duration) {
                viewController.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY!)
                return
            }
        }
    }
    
    func tabBarIsVisible(viewController: UIViewController) ->Bool {
        return viewController.tabBarController?.tabBar.frame.origin.y < CGRectGetMaxY(viewController.view.frame)
    }    
}

// Opportunity here to make this generic.

class TextViewChangeObserver {
    var observerObject: NSObjectProtocol
    
    init(_ textView: UITextView, action: () -> ()) {
        observerObject = NSNotificationCenter.defaultCenter().addObserverForName(UITextViewTextDidChangeNotification, object: textView, queue: nil) {
            note in
            
            action()
        }
    }
    
    func stopObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(observerObject)
    }
    
    deinit {
        print("-- deinit Change observer")
    }
}

class TextFieldChangeObserver {
    var observerObject: NSObjectProtocol
    
    init(_ textField: UITextField, action: () -> ()) {
        observerObject = NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: nil) {
            note in
            action()
        }
    }
    
    func stopObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(observerObject)
    }
}

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

extension UIButton {
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
        if photo.source == PhotoSource.resource.rawValue {
            if animate {
                UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: { () -> Void in
                        self.setImage(UIImage(named: photo.prefix), forState:UIControlState.Normal)
                    }, completion: nil)
            } else {
                self.setImage(UIImage(named: photo.prefix), forState:UIControlState.Normal)
            }
            return
        }
        
        var resizerHeight = self.frame.size.height * PIXEL_SCALE
        var resizerWidth = self.frame.size.width * PIXEL_SCALE
        
        photo.resizer(true, height: Int(resizerHeight), width: Int(resizerWidth))
        let url = photo.uriWrapped()

        if let imageButton = self as? AirImageButton {
            if imageButton.photo?.uri() == photo.uri() {
                return
            }
            imageButton.startActivity()
        }
        
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            completed: { image, error, cacheType, url in
            
                if let imageButton = self as? AirImageButton {
                    imageButton.stopActivity()
                }
                
                if error != nil {
                    println("Image fetch failed: " + error.localizedDescription)
                    println(url?.standardizedURL)
                    self.setImage(UIImage(named: "imgBroken250Light"), forState:UIControlState.Normal)
                    return
                }
                
                if let imageButton = self as? AirImageButton {
                    if imageButton.photo?.uri() == photo.uri() {
                        return
                    }
                    imageButton.photo = photo
                }
                
                if animate || cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
                    UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                        animations: { () -> Void in
                            self.setImage(image, forState:UIControlState.Normal)
                        }, completion: nil)
                } else {
                    self.setImage(image, forState:UIControlState.Normal)
                }
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        if let imageView = self as? AirImageButton {
            imageView.startActivity()
        }
        
        var url = NSURL(string: imageResult.mediaUrl!)
        
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            completed: { image, error, cacheType, url in
            
                if let imageView = self as? AirImageButton {
                    imageView.stopActivity()
                }
                
                if error != nil {
                    println("Image fetch failed: " + error.localizedDescription)
                    println(url?.standardizedURL)
                    self.setImage(UIImage(named: "imgBroken250Light"), forState:UIControlState.Normal)
                    return
                }
                
                if animate || cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
                    UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                        animations: { () -> Void in
                            self.setImage(image, forState:UIControlState.Normal)
                        }, completion: nil)
                } else {
                    self.setImage(image, forState:UIControlState.Normal)
                }
            }
        )
    }
}

extension UIImageView {
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
        if let imageView = self as? AirImageView {
            if imageView.photo != nil {
                if imageView.photo?.uri() == photo.uri() {
                    return
                }
            }
            imageView.startActivity()
        }
        
        if photo.source == PhotoSource.resource.rawValue {
            if animate {
                UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: { () -> Void in
                        self.image = UIImage(named: photo.prefix)
                    }, completion: nil)
            } else {
                self.image = UIImage(named: photo.prefix)
            }
            if let imageView = self as? AirImageView {
                imageView.photo = photo
                imageView.stopActivity()
            }
            return
        }
        
        var resizerHeight = self.frame.size.height * PIXEL_SCALE
        var resizerWidth = self.frame.size.width * PIXEL_SCALE
        
        photo.resizer(true, height: Int(resizerHeight), width: Int(resizerWidth))
        let url = photo.uriWrapped()
        
        self.sd_setImageWithURL(url,
            placeholderImage: nil,
            options: nil,
            completed: { image, error, cacheType, url in
            
                if let imageView = self as? AirImageView {
                    imageView.stopActivity()
                }
                
                if error != nil {
                    println("Image fetch failed: " + error.localizedDescription)
                    println(url?.standardizedURL)
                    self.image = UIImage(named: "imgBroken250Light")
                    return
                }
                
                if let imageView = self as? AirImageView {
                    if imageView.photo != nil {
                        if imageView.photo?.uri() == photo.uri() {
                            return
                        }
                    }
                    imageView.photo = photo
                }
                
                if animate || cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
                    UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                        animations: { () -> Void in
                            self.image = image
                        }, completion: nil)
                }
                else {
                    self.image = image
                }            
            }
        )
    }
    
    func setImageWithThumbnail(thumbnail: Thumbnail, animate: Bool = true) {
        
        if let imageView = self as? AirImageView {
            imageView.startActivity()
        }
        
        var url = NSURL(string: thumbnail.mediaUrl!)
        
        self.sd_setImageWithURL(url,
            completed: { image, error, cacheType, url in
            
                if let imageView = self as? AirImageView {
                    imageView.stopActivity()
                }
                
                if error != nil {
                    println("Image fetch failed: " + error.localizedDescription)
                    println(url?.standardizedURL)
                    self.image = UIImage(named: "imgBroken250Light")
                    return
                }
                
                if !animate {
                    self.image = image
                }
                else {
                    if cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
                        UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                            animations: { () -> Void in
                                self.image = image
                            }, completion: nil)
                    }
                    else {
                        self.image = image
                    }
                }
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        if let imageView = self as? AirImageView {
            imageView.startActivity()
        }
        
        var url = NSURL(string: imageResult.mediaUrl!)
        
        self.sd_setImageWithURL(url,
            completed: { image, error, cacheType, url in
            
                if let imageView = self as? AirImageView {
                    imageView.stopActivity()
                }
                
                if error != nil {
                    println("Image fetch failed: " + error.localizedDescription)
                    println(url?.standardizedURL)
                    self.image = UIImage(named: "imgBroken250Light")
                    return
                }
                
                if animate || cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
                    UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve,
                        animations: { () -> Void in
                            self.image = image
                        }, completion: nil)
                } else {
                    self.image = image
                }
            }
        )
    }
    
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

