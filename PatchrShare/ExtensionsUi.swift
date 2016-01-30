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
}

extension UIColor {
	
	public convenience init(hexString: String) {
		let r, g, b, a: CGFloat
		
		if hexString.hasPrefix("#") {
			let start = hexString.startIndex.advancedBy(1)
			let hexColor = hexString.substringFromIndex(start)
			
			if hexColor.characters.count == 8 {
				let scanner = NSScanner(string: hexColor)
				var hexNumber: UInt64 = 0
				
				if scanner.scanHexLongLong(&hexNumber) {
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