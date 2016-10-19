//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

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

extension UIView {
    
    func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, alpha: CGFloat = 1.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        if self.alpha != alpha {
            UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.alpha = alpha
                }, completion: completion)
        }
    }
    
    func fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0, alpha: CGFloat = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        if self.alpha != alpha {
            UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.alpha = alpha
                }, completion: completion)
        }
    }
}

extension UIColor {
	
	public convenience init(hexString: String) {
		let r, g, b, a: CGFloat
		
		if hexString.hasPrefix("#") {
			let start = hexString.index(hexString.startIndex, offsetBy: 1)
			let hexColor = hexString.substring(from: start)
			
			if hexColor.characters.count == 8 {
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
