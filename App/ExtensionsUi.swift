//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//
import MBProgressHUD
import Photos

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
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func normalizedImage() -> UIImage {
        if self.imageOrientation == UIImageOrientation.up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
        self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: self.size))
        let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        return normalizedImage;
    }
    
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIAlertController {
	/*
	* http://http://stackoverflow.com/questions/31406820
	* Fix for iOS 9 bug that produces infinite recursion loop looking for
	* supportInterfaceOrientations.
	*/
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.portrait
	}
	
    override open var shouldAutorotate: Bool {
		return false
	}
}

public extension Bundle {
    static func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let view = Bundle.main.loadNibNamed(name, owner: nil, options: nil)?.first as? T {
            return view
        }
        fatalError("Could not load view with type " + String(describing: type))
    }
}

public extension UIView {
	
    func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, alpha: CGFloat = 1.0, completion: ((Bool) -> Void)? = nil) {
        if self.alpha != alpha {
            UIView.animate(withDuration: duration
				, delay: delay
				, options: [.curveEaseIn, .allowUserInteraction]
				, animations: {
					self.alpha = alpha
                }
				, completion: completion)
        }
    }
    
    func fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, alpha: CGFloat = 0.0, completion: ((Bool) -> Void)? = nil) {
        if self.alpha != alpha {
            UIView.animate(withDuration: duration
				, delay: delay
				, options: [.curveEaseIn, .allowUserInteraction]
				, animations: {
					self.alpha = alpha
                }
				, completion: completion)
        }
    }
	
	func scaleOut(duration: TimeInterval = 0.2, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
		UIView.animate(withDuration: duration
			, delay: delay
			, options: [.curveEaseOut]
			, animations: {
				/* Setting to zero seems to cancel the animation and to straight to gone */
				self.transform = CGAffineTransform(scaleX: CGFloat(0.0001), y: CGFloat(0.0001))
			}
			, completion: completion)
	}
	
	func scaleIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
		UIView.animate(withDuration: duration
			, delay: delay
			, usingSpringWithDamping: 0.8
			, initialSpringVelocity: 0.3
			, options: [.curveEaseIn]
			, animations: {
				/* Resets to original state */
				self.transform = CGAffineTransform.identity
			}
			, completion: completion)
	}
    
    func rotate(_ toValue: CGFloat, duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(rotationAngle: toValue)
        }
    }
    
    func slideUp(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration
            , delay: delay
            , usingSpringWithDamping: 0.8
            , initialSpringVelocity: 0.3
            , options: [.curveEaseIn]
            , animations: {
                self.transform = CGAffineTransform(translationX: 0, y: 100)
            }
            , completion: completion)
    }

    func slideDown(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration
            , delay: delay
            , usingSpringWithDamping: 0.8
            , initialSpringVelocity: 0.3
            , options: [.curveEaseIn]
            , animations: {
                /* Resets to original state */
                self.transform = CGAffineTransform.identity
            }
            , completion: completion)
    }
    
    func layoutIfNeeded(animated: Bool) {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    func align(toTheRightOf view: UIView, matchingCenterWithLeftPadding left: CGFloat, width: CGFloat, height: CGFloat, topPadding: CGFloat) {
        self.frame = CGRect(x: view.frame.maxX + left, y: (view.frame.midY - (height / 2.0) + topPadding), width: width, height: height);
    }

    func showShadow(offset: CGSize = CGSize(width: 0, height: 3), radius: CGFloat = 3.0, rounded: Bool = false, opacity: Float = 0.4, cornerRadius: CGFloat = 0) {
		
		self.layer.masksToBounds = false
		self.layer.shadowColor = Colors.black.cgColor
        self.layer.shadowOffset = offset
		self.layer.shadowOpacity = opacity
		self.layer.shadowRadius = radius // blur radius
		
		if rounded {
			self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
		}
		else {
			self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
		}
	}
    
    func removeShadow() {
        self.layer.shadowColor = Colors.black.cgColor
        self.layer.shadowOpacity = 0
        self.layer.shadowOffset = CGSize(width: 0, height: -3)
        self.layer.shadowRadius = 3
        self.layer.shadowPath = nil
        self.layer.masksToBounds = true
    }

	func snapshot() -> UIImage {
		UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
		drawHierarchy(in: self.bounds, afterScreenUpdates: true)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
    
    func removeSubviews() {
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
    }

    func resizeToFitSubviews(padding: CGFloat = 0) {
        var w: CGFloat = 0
        var h: CGFloat = 0
        
        for subview in subviews {
            if !subview.isHidden {
                let fw = subview.frame.origin.x + subview.frame.size.width
                let fh = subview.frame.origin.y + subview.frame.size.height
                w = max(fw, w)
                h = max(fh, h)
            }
        }
        
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: w + padding, height: h + padding)
    }

	func sizeThatFitsSubviews() -> CGSize {
		var w: CGFloat = 0
		var h: CGFloat = 0
		
		for subview in subviews {
			if !subview.isHidden {
				let fw = subview.frame.origin.x + subview.frame.size.width
				let fh = subview.frame.origin.y + subview.frame.size.height
				w = max(fw, w)
				h = max(fh, h)
			}
		}
		
        return CGSize(width:w, height:h)
	}
	
	class func disableRecursivelyAllSubviews(view: UIView) {
		view.isUserInteractionEnabled = false
		for subview in view.subviews {
			self.disableRecursivelyAllSubviews(view: subview)
		}
	}
	
	class func disableAllSubviewsOf(view: UIView) {
		for subview in view.subviews {
			self.disableRecursivelyAllSubviews(view: subview)
		}
	}
    
    class func fromNib<T : UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

extension UIWindow {
    
    func setRootViewController(rootViewController: UIViewController, animated: Bool = false, then: ((Bool) -> Void)? = nil) {
		
        self.rootViewController = nil
        
        if !animated {
            self.rootViewController = rootViewController
            then?(true)
            return
        }
        
        UIView.transition(with: self
            , duration: 0.65
            , options: [.transitionCrossDissolve]
            , animations: {
                /*
				 * The animation enabling/disabling are to address a status bar issue 
				 * on the destination view controller: http://stackoverflow.com/a/8505364/2247399
				 */
                let oldState = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                self.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            }
            , completion: { finished in
                then?(true)
            })
    }
}

extension UIViewController {
    
    var className: String {
        return NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!
    }
    
    var chromeHeight: CGFloat {
        let statusHeight = UIApplication.shared.statusBarFrame.size.height
        let navigationHeight = self.navigationController?.navigationBar.height() ?? 44
        return (statusHeight + navigationHeight)
    }

    var presented: Bool {
        if self.presentingViewController?.presentedViewController == self { return true }
        if let wrapper = self.navigationController {
            if (wrapper.viewControllers.count == 1 && self.presentingViewController?.presentedViewController == wrapper) { return true }
            if (wrapper.viewControllers.count > 1 && wrapper.topViewController == self) { return false }
            if wrapper.presentingViewController?.presentedViewController == wrapper { return true }
        }
        if self.tabBarController?.presentingViewController is UITabBarController { return true }
        return false
    }
    
    var orientationIsLandscape: Bool {
        return UIDeviceOrientationIsLandscape(UIDevice.current.orientation)
    }
    
    var containerController: ContainerController {
        return MainController.instance.containerController
    }
    
    class var root: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
    
    class var topController: UIViewController? {
        
        guard root != nil else { return nil }
        
        var pointedViewController = root
        
        while pointedViewController?.presentedViewController != nil {
            switch pointedViewController?.presentedViewController {
            case let navagationController as UINavigationController:
                pointedViewController = navagationController.viewControllers.last
            case let tabBarController as UITabBarController:
                pointedViewController = tabBarController.selectedViewController
            default:
                pointedViewController = pointedViewController?.presentedViewController
            }
        }
        return pointedViewController
        
    }
    
    class func topMostViewController() -> UIViewController? {
        // Returns the most recently presented UIViewController (visible)
        
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
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            
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
    
    class func getNavigationController() -> UINavigationController? {
        // Returns the navigation controller if it exists
        if let navigationController = UIApplication.shared.keyWindow?.rootViewController  {
            return navigationController as? UINavigationController
        }
        return nil
    }
    
    class func getTabBarController() -> UITabBarController? {
        // Returns the navigation controller if it exists
        if let controller = UIApplication.shared.keyWindow?.rootViewController  {
            return controller as? UITabBarController
        }
        return nil
    }
    
    func close(animated: Bool = true, root: Bool = false) {
        /* Override in subclasses for control of dismiss/pop process */
        if self.presented || self.popupController != nil {
            if self.navigationController != nil {
                self.navigationController!.dismiss(animated: animated, completion: nil)
            }
            else if self.popupController != nil {
                self.popupController!.dismiss()
            }
            else {
                self.dismiss(animated: animated, completion: nil)
            }
        }
        else {
            if root {
                let _ = self.navigationController?.popToRootViewController(animated: animated)
                return
            }
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    func dismissToast(sender: AnyObject) {
		if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
			hud.animationType = MBProgressHUDAnimation.zoomIn
			hud.hide(true)
		}
	}
        
	func alert(title: String?, message: String? = nil, cancelButtonTitle: String = "OK", onDismiss: (() -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { _ in onDismiss?() })
		alert.addAction(okAction)
		self.present(alert, animated: true) {}
	}
	
	func locationSettingsAlert(title: String? = nil, message: String? = nil,
		actionTitle: String, cancelTitle: String,
		delegate: AnyObject? = nil, onDismiss: @escaping (Bool) -> Void) {
			
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: actionTitle, style: .default, handler: { _ in onDismiss(true) })
			let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in onDismiss(false) })
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			self.present(alert, animated: true, completion: nil)
	}
	
	func updateConfirmationAlert(title: String? = nil, message: String? = nil,
		actionTitle: String, cancelTitle: String,
		delegate: Any? = nil, onDismiss: @escaping (Bool) -> Void) {
			
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: actionTitle, style: .default, handler: { _ in onDismiss(true) })
			let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in onDismiss(false) })
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			self.present(alert, animated: true, completion: nil)
	}
	
    func deleteConfirmationAlert(title: String? = nil, message: String? = nil,
								 actionTitle: String, cancelTitle: String, destructConfirmation: Bool = false,
								 delegate: Any? = nil, onDismiss: @escaping (Bool) -> Void) {
            
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: actionTitle, style: .destructive, handler: { _ in onDismiss(true) })
		let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in onDismiss(false) })
		alert.addAction(okAction)
		alert.addAction(cancelAction)
		if destructConfirmation {
			alert.addTextField() { textField in
				textField.addTarget(delegate, action: #selector(UIViewController.alertTextFieldDidChange(sender:)), for: .editingChanged)
			}
			okAction.isEnabled = false
		}
		self.present(alert, animated: true, completion: nil)
    }
	
    func prePermissionAlert(title: String? = nil, message: String? = nil,
                                 actionTitle: String, cancelTitle: String,
                                 onDismiss: @escaping (Bool) -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: actionTitle, style: .default, handler: { _ in onDismiss(true) })
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in onDismiss(false) })
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
	@objc func alertTextFieldDidChange(sender: AnyObject) {
		if let alertController: UIAlertController = self.presentedViewController as? UIAlertController {
			let confirm = alertController.textFields![0]
			let okAction = alertController.actions[0]
			okAction.isEnabled = confirm.text == "YES"
		}
	}

	func addActivityIndicatorTo(view: UIView, offsetY: Float = 0, style: UIActivityIndicatorViewStyle = .whiteLarge) -> UIActivityIndicatorView {
		/*
		 * Currently only called by PhotoPicker.
		 */
		let activity: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: style)
		activity.color = Theme.colorTint
		activity.hidesWhenStopped = true
		view.addSubview(activity)
		activity.anchorInCenter(withWidth: 20, height: 20)
		
		return activity
	}
}

extension UINavigationController {
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if visibleViewController != nil {
            return visibleViewController!.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
    override open var shouldAutorotate: Bool {
        if visibleViewController != nil {
            return visibleViewController!.shouldAutorotate
        }
        return super.shouldAutorotate
    }
}

extension UITabBarController {
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let selected = selectedViewController {
            return selected.supportedInterfaceOrientations
        }
        return super.supportedInterfaceOrientations
    }
    
    override open var shouldAutorotate: Bool {
        if let selected = selectedViewController {
            return selected.shouldAutorotate
        }
        return super.shouldAutorotate
    }
}

extension UIColor {
	
	public convenience init(hexString: String) {
		let r, g, b, a: CGFloat
		
		if hexString.hasPrefix("#") {
			let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
			
			if hexColor.count == 8 {
				let scanner = Scanner(string: hexColor)
				var hexNumber: UInt64 = 0
				
				if scanner.scanHexInt64(&hexNumber) {
					r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
					g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
					b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
					a = CGFloat(hexNumber & 0x000000ff) / 255
					
					self.init(red: r, green: g, blue: b, alpha: a)
					return
				}
			}
		}
		self.init(red: 0, green: 0, blue: 0, alpha: 1)
		return
	}
}

extension Array {
    
    func at(_ index: Int?) -> Element? {
        if let index = index , index >= 0 && index < endIndex {
            return self[index]
        }
        else {
            return nil
        }
    }
}

extension String {
    
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
    
    func stringByAddingPercentEncodingForUrl() -> String? {
        let unreserved = "-._~"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
    
    public func stringByAddingPercentEncodingForFormData(plusForSpace: Bool=false) -> String? {
        let unreserved = "*-._"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        
        if plusForSpace {
            allowed.addCharacters(in: " ")
        }
        
        var encoded = addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
        if plusForSpace {
            encoded = encoded?.replacingOccurrences(of: " ", with: "+")
        }
        return encoded
    }
    
	func isEmail() -> Bool {
		if self.isEmpty {
			return false
		}
		
		guard let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: [.caseInsensitive]) else {
			return false
		}
		
		return regex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, utf16.count)) == 1
	}
	
    var md5: String! {
		
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
		
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deallocate(capacity: digestLen)
        
        return String(format: hash as String)
    }
    
    var numbersOnly: String! {
        let str = self.replacingOccurrences(of: "[^0-9]", with: "", options: String.CompareOptions.regularExpression, range: nil)
        return str.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    
    var length: Int {
        return self.count
    }
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(startIndex, offsetBy: r.lowerBound)
        let end = self.index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[(start ..< end)])
    }
    
    subscript (r: CountableClosedRange<Int>) -> String {
        let start = self.index(startIndex, offsetBy: r.lowerBound)
        let end = self.index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[(start ... end)])
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

func += <KeyType, ValueType> ( left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
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

/**
	MissingHashMarkAsPrefix:   "Invalid RGB string, missing '#' as prefix"
	UnableToScanHexValue:      "Scan hex error"
	MismatchedHexStringLength: "Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8"
*/
public enum UIColorInputError : Error {
	case MissingHashMarkAsPrefix,
	UnableToScanHexValue,
	MismatchedHexStringLength
}
