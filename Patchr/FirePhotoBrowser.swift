//
//  AirPhotoBrowserViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class FirePhotoBrowser: IDMPhotoBrowser {
    
    var likes : Bool = false
    var likeButton = AirLikeButton()
    var message	: FireMessage?
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		self.displayDoneButton = false	// Prevent display of non-navbar done button
        initialize()
    }
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {

        if self.message?.createdBy != nil {
			super.shareMessage = "Photo by \(self.message?.createdBy) on Patchr"
        }
        
        /* Configure bottom toolbar */
        
        let toolbar: UIToolbar = super.toolbar
        
        let flexSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
		let shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(IDMPhotoBrowser.actionButtonPressed(_:)))    // Handled by IDMPhotoBrowser
        
        self.likeButton.frame = CGRect(x:0, y:0, width:44, height:44)
        self.likeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right:8)
		self.likeButton.isHidden = (self.message == nil)
        
        fixedSpacer.width = 16
        
        let barLikeButton = UIBarButtonItem(customView: self.likeButton)

        var items = [UIBarButtonItem]()
        items.append(flexSpacer)
		items.append(flexSpacer)	// Doubled up hack to prevent jitters because of animation
        items.append(barLikeButton)
		items.append(flexSpacer)
		items.append(flexSpacer)
        items.append(shareButton)
        
        toolbar.items = items
    }
	
	func bind(message: FireMessage?) {
		self.message = message
		self.likeButton.bind(message: message)
		self.likeButton.isHidden = (message == nil)
	}
}
