//
//  AirProgress.swift
//  Patchr
//
//  Created by Jay Massena on 10/4/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirProgress: MBProgressHUD {
    
    var shadow: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if shadow {
            if let parent = self.superview {
                let x = CGFloat(parent.bounds.size.width - self.size.width) * 0.5
                let y = CGFloat(parent.bounds.size.height - self.size.height) * 0.5
                
                self.layer.masksToBounds = false
                self.layer.shadowOffset = CGSizeMake(2, 4)
                self.layer.shadowRadius = 3
                self.layer.shadowOpacity = 0.3
                let rect: CGRect = CGRectMake(x + CGFloat(self.xOffset), y + CGFloat(self.yOffset), self.size.width, self.size.height)
                let path: UIBezierPath = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(self.cornerRadius))
                self.layer.shadowPath = path.CGPath
            }
        }
    }
    
    func styleAs(progressStyle: ProgressStyle) {
        
        self.labelFont = UIFont(name:"HelveticaNeue-Light", size: 16)
        self.detailsLabelFont = UIFont(name:"HelveticaNeue-Light", size: 14)
        
        if progressStyle == .ActivityLight {
            self.animationType = MBProgressHUDAnimation.Zoom
            self.margin = 16
            self.cornerRadius = 8
            self.color = UIColor.whiteColor()
            self.labelColor = UIColor.blackColor()
            self.detailsLabelColor = UIColor.blackColor()
            self.activityIndicatorColor = Theme.colorActivity
            self.shadow = true
            self.square = true
        }
        else if progressStyle == .ToastLight {
            self.animationType = MBProgressHUDAnimation.Fade
            self.margin = 16.0
            self.cornerRadius = 24.0
            self.opacity = 0.7
            self.color = Colors.brandColorLight
            self.labelColor = UIColor.blackColor()
            self.detailsLabelColor = Colors.gray95pcntColor
            self.activityIndicatorColor = Theme.colorActivity
            self.shadow = true
        }
        else if progressStyle == .ActivityOnly {
            self.animationType = MBProgressHUDAnimation.Fade
            self.opacity = 0.0
            self.color = UIColor.clearColor()
            self.labelColor = UIColor.blackColor()
            self.detailsLabelColor = Colors.gray95pcntColor
            self.activityIndicatorColor = Theme.colorActivity
            self.shadow = false
            self.square = true
        }
    }
}

enum ProgressStyle: Int {
    case ActivityOnly
    case ActivityLight
    case ActivityDark
    case ToastLight
    case ToastDark
}
