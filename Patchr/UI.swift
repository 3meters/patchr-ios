//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

public class AirUi: NSObject {

    public static let instance = AirUi()

    static let accentColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0.75), blue: CGFloat(1), alpha: CGFloat(1))
	static let brandColor: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.55), blue: CGFloat(0), alpha: CGFloat(1))
    static let brandColorLight: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.718), blue: CGFloat(0.302), alpha: CGFloat(1))
    static let brandColorDark: UIColor = UIColor(red: CGFloat(0.93), green: CGFloat(0.42), blue: CGFloat(0), alpha: CGFloat(1))
    static let windowColor: UIColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(1))
    static let hintColor: UIColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1))

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
    
    func showToast(message: String!) {
        var progress: MBProgressHUD?
        progress = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate?.window!, animated: true)
        progress!.mode = MBProgressHUDMode.Text
        progress!.labelText = message
        progress!.opacity = 0.8
        progress!.removeFromSuperViewOnHide = true
        progress!.userInteractionEnabled = false
        progress!.show(true)
    }
    
    func tabBarIsVisible(viewController: UIViewController) ->Bool {
        return viewController.tabBarController?.tabBar.frame.origin.y < CGRectGetMaxY(viewController.view.frame)
    }
}

extension UITextField {
    var isEmpty: Bool {
        return self.text == nil || self.text.isEmpty
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
        
        self.sd_setImageWithURL(url, forState:UIControlState.Normal, completed: { (image, error, cacheType, url) -> Void in
            
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
        })
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
        
        self.sd_setImageWithURL(url, completed: { (image, error, cacheType, url) -> Void in
            
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
            } else {
                self.image = image
            }            
        })
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

