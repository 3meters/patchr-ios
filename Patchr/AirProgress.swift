//
//  AirProgress.swift
//  Patchr
//
//  Created by Jay Massena on 10/4/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class AirProgress: MBProgressHUD {
    
    var shadow: Bool = false
	
	override init(view: UIView) {
		super.init(view: view)
		initialize()
	}
	
	init() {
		super.init(frame: CGRectZero)
		initialize()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("This view should never be loaded from storyboard")
	}
	
	func initialize() {
		self.isAccessibilityElement = true
	}
	
	static func addedTo(view: UIView) -> AirProgress {
		let hud = AirProgress(view: view)
		hud.removeFromSuperViewOnHide = true
		view.addSubview(hud)
		return hud
	}

    override func layoutSubviews() {
        super.layoutSubviews()
        if shadow {
            if let parent = self.superview {
                let x = CGFloat(parent.bounds.size.width - self.bezelView.frame.size.width) * 0.5
                let y = CGFloat(parent.bounds.size.height - self.bezelView.frame.size.height) * 0.5
                
                self.layer.masksToBounds = false
                self.layer.shadowOffset = CGSizeMake(2, 4)
                self.layer.shadowRadius = 3
                self.layer.shadowOpacity = 0.3
                let rect: CGRect = CGRectMake(x + CGFloat(self.offset.x), y + CGFloat(self.offset.y), self.bezelView.frame.size.width, self.bezelView.frame.size.height)
                let path: UIBezierPath = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(self.bezelView.layer.cornerRadius))
                self.layer.shadowPath = path.CGPath
            }
        }
    }
	
	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		return false
	}
    
    func styleAs(progressStyle: ProgressStyle) {
        
        self.label.font = Theme.fontComment
        self.detailsLabel.font = Theme.fontCommentSmall
		self.activityIndicatorColor = Theme.colorActivityIndicator
		
        if progressStyle == .ActivityWithText {
            self.animationType = MBProgressHUDAnimation.Zoom
            self.margin = 16
            self.bezelView.layer.cornerRadius = 8
            self.bezelView.color = Theme.colorBackgroundActivity
            self.label.textColor = Theme.colorTextActivity
            self.detailsLabel.textColor = Theme.colorTextActivity
            self.shadow = true
            self.square = true
        }
        else if progressStyle == .ToastLight {
            self.animationType = MBProgressHUDAnimation.Fade
            self.margin = 16.0
            self.bezelView.layer.cornerRadius = 24.0
            self.bezelView.alpha = 0.7
            self.bezelView.color = Theme.colorBackgroundToast
            self.label.textColor = Theme.colorTextToast
            self.detailsLabel.textColor = Theme.colorTextToast
            self.shadow = true
        }
        else if progressStyle == .ActivityOnly {
            self.animationType = MBProgressHUDAnimation.Fade
            self.bezelView.alpha = 0.0
            self.bezelView.color = Theme.colorBackgroundActivityOnly
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
