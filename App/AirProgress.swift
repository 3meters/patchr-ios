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
		super.init(frame: CGRect.zero)
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
                let x = CGFloat(parent.bounds.size.width - self.size.width) * 0.5
                let y = CGFloat(parent.bounds.size.height - self.size.height) * 0.5
                
                self.layer.masksToBounds = false
                self.layer.shadowOffset = CGSize(width:2, height:4)
                self.layer.shadowRadius = 3
                self.layer.shadowOpacity = 0.3
                let rect: CGRect = CGRect(x:x + CGFloat(self.xOffset), y:y + CGFloat(self.yOffset), width:self.size.width, height:self.size.height)
                let path: UIBezierPath = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(self.cornerRadius))
                self.layer.shadowPath = path.cgPath
            }
        }
    }
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return false
	}
    
    func styleAs(progressStyle: ProgressStyle) {
        
        self.labelFont = Theme.fontComment
        self.detailsLabelFont = Theme.fontCommentSmall
		self.activityIndicatorColor = Theme.colorActivityIndicator
		
        if progressStyle == .activityWithText {
            self.animationType = MBProgressHUDAnimation.zoom
            self.margin = 16
            self.cornerRadius = 8
            self.color = Theme.colorBackgroundActivity
            self.labelColor = Theme.colorTextActivity
            self.detailsLabelColor = Theme.colorTextActivity
            self.shadow = true
            self.isSquare = true
        }
        else if progressStyle == .toastLight {
            self.animationType = MBProgressHUDAnimation.fade
            self.margin = 16.0
            self.cornerRadius = 24.0
            self.opacity = 0.7
            self.color = Theme.colorBackgroundToast
            self.labelColor = Theme.colorTextToast
            self.detailsLabelColor = Theme.colorTextToast
            self.shadow = true
        }
        else if progressStyle == .stickyToastLight {
            self.animationType = MBProgressHUDAnimation.fade
            self.margin = 16.0
            self.cornerRadius = 24.0
            self.opacity = 0.7
            self.color = Theme.colorBackgroundToast
            self.labelColor = Theme.colorTextToast
            self.detailsLabelColor = Theme.colorTextToast
            self.shadow = true
            self.detailsLabelFont = self.labelFont
        }
        else if progressStyle == .activityOnly {
            self.animationType = MBProgressHUDAnimation.fade
            self.opacity = 0.0
            self.color = Theme.colorBackgroundActivityOnly
            self.shadow = false
            self.isSquare = true
        }
    }
}

enum ProgressStyle: Int {
    case activityOnly
    case activityWithText
    case activityDark
    case toastLight
    case toastDark
    case stickyToastLight
}
