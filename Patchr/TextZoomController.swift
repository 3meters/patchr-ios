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
	var description_	= AirTextView()
	var buttonCancel	= AirLinkButton()
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.messageHolder.bounds.size.width = self.view.width() - 48
		self.description_.bounds.size.width = self.messageHolder.width() - 48
		self.messageHolder.fillSuperviewWithLeftPadding(24, rightPadding: 24, topPadding: 72, bottomPadding: 24)
		self.description_.fillSuperviewWithLeftPadding(24, rightPadding: 24, topPadding: 32, bottomPadding: 24)
		self.buttonCancel.anchorTopRightWithRightPadding(0, topPadding: 0, width: 48, height: 48)
	}
	
	func cancelAction(sender: AnyObject?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		setScreenName("TextZoom")
		
		self.view.backgroundColor = Colors.opacity50pcntBlack
		self.view.addSubview(self.messageHolder)
		
		self.messageHolder.backgroundColor = Theme.colorBackgroundForm
		self.messageHolder.cornerRadius = 8
		
		self.description_.text = self.inputMessage!
		self.description_.editable = false
		self.description_.font = Theme.fontTextDisplay
		self.description_.contentMode = .Top
		
		self.buttonCancel.setImage(UIImage(named: "imgCancelDark"), forState: .Normal)
		self.buttonCancel.tintColor = Theme.colorTint
		
		self.messageHolder.addSubview(self.description_)
		self.messageHolder.addSubview(self.buttonCancel)

		self.buttonCancel.addTarget(self, action: Selector("cancelAction:"), forControlEvents: .TouchUpInside)
	}
}

