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
        
        self.labelFont = Theme.fontComment
        self.detailsLabelFont = Theme.fontCommentSmall
        
        if progressStyle == .ActivityWithText {
            self.animationType = MBProgressHUDAnimation.Zoom
            self.margin = 16
            self.cornerRadius = 8
            self.color = Theme.colorBackgroundActivity
            self.labelColor = Theme.colorTextActivity
            self.detailsLabelColor = Theme.colorTextActivity
            self.activityIndicatorColor = Theme.colorActivityIndicator
            self.shadow = true
            self.square = true
        }
        else if progressStyle == .ToastLight {
            self.animationType = MBProgressHUDAnimation.Fade
            self.margin = 16.0
            self.cornerRadius = 24.0
            self.opacity = 0.7
            self.color = Theme.colorBackgroundToast
            self.labelColor = Theme.colorTextToast
            self.detailsLabelColor = Theme.colorTextToast
            self.activityIndicatorColor = Theme.colorActivityIndicator
            self.shadow = true
        }
        else if progressStyle == .ActivityOnly {
            self.animationType = MBProgressHUDAnimation.Fade
            self.opacity = 0.0
            self.color = Theme.colorBackgroundActivityOnly
            self.activityIndicatorColor = Theme.colorActivityIndicator
            self.shadow = false
            self.square = true
        }
    }
}

enum ProgressStyle: Int {
    case ActivityOnly
    case ActivityWithText
    case ActivityDark
    case ToastLight
    case ToastDark
}
