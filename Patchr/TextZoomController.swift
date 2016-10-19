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
		self.messageHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 24, topPadding: 72, height: holderHeight)
		self.description_.fillSuperview(withLeftPadding: 24, rightPadding: 24, topPadding: 32, bottomPadding: 24)
		self.description_.setContentOffset(CGPoint.zero, animated: false)
		self.buttonCancel.anchorTopRight(withRightPadding: 0, topPadding: 0, width: 48, height: 48)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func cancelAction(sender: AnyObject?) {
		self.dismiss(animated: true, completion: nil)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("TextZoom")
		
		self.view.backgroundColor = Colors.clear
		self.scrollView.backgroundColor = Colors.opacity50pcntBlack
		self.view.addSubview(self.messageHolder)
		
		self.messageHolder.backgroundColor = Theme.colorBackgroundForm
		self.messageHolder.cornerRadius = 8
		
		self.description_.text = self.inputMessage!
		self.description_.isEditable = false
		self.description_.font = Theme.fontTextDisplay
		self.description_.contentMode = .top
		self.description_.isScrollEnabled = true
		
		self.buttonCancel.setImage(UIImage(named: "imgCancelDark"), for: .normal)
		self.buttonCancel.tintColor = Theme.colorTint
		
		self.messageHolder.addSubview(self.description_)
		self.messageHolder.addSubview(self.buttonCancel)

		self.buttonCancel.addTarget(self, action: #selector(TextZoomController.cancelAction(sender:)), for: .touchUpInside)
	}
}

