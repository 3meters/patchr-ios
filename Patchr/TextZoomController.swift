//
//  LobbyViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class TextZoomController: BaseViewController {
	
	var inputMessage	: String?
	var messageHolder	= UIView()
	var description_	= UITextView()
	var buttonCancel	= AirLinkButton()
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		self.messageHolder.bounds.size.width = self.view.width() - 48
		self.description_.bounds.size.width = self.messageHolder.width() - 48
		self.description_.sizeToFit()
		
		let holderHeight = min(self.view.height() - 96, self.description_.height() + 56)
		self.messageHolder.anchorTopCenterFillingWidthWithLeftAndRightPadding(24, topPadding: 72, height: holderHeight)
		self.description_.fillSuperviewWithLeftPadding(24, rightPadding: 24, topPadding: 32, bottomPadding: 24)
		self.description_.setContentOffset(CGPointZero, animated: false)
		self.buttonCancel.anchorTopRightWithRightPadding(0, topPadding: 0, width: 48, height: 48)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func cancelAction(sender: AnyObject?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("TextZoom")
		self.view.accessibilityIdentifier = View.TextZoom
		
		self.view.backgroundColor = Colors.clear
		self.scrollView.backgroundColor = Colors.opacity50pcntBlack
		self.view.addSubview(self.messageHolder)
		
		self.messageHolder.backgroundColor = Theme.colorBackgroundForm
		self.messageHolder.cornerRadius = 8
		
		self.description_.text = self.inputMessage!
		self.description_.editable = false
		self.description_.font = Theme.fontTextDisplay
		self.description_.contentMode = .Top
		self.description_.scrollEnabled = true
		
		self.buttonCancel.setImage(UIImage(named: "imgCancelDark"), forState: .Normal)
		self.buttonCancel.tintColor = Theme.colorTint
		
		self.messageHolder.addSubview(self.description_)
		self.messageHolder.addSubview(self.buttonCancel)

		self.buttonCancel.addTarget(self, action: Selector("cancelAction:"), forControlEvents: .TouchUpInside)
	}
}

