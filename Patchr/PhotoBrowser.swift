//
//  AirPhotoBrowserViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser
import Firebase
import Photos

class PhotoBrowser: IDMPhotoBrowser {
    
    var likes : Bool = false
    var likeButton : AirLikeButton?
    var message	: FireMessage?  // Needed to make the like button work
    var mode: PhotoBrowserMode = .browse
    
    /* UI specialized for previewing photos from the photo picker. */
    var browseDelegate: PhotoBrowseControllerDelegate?  // Used by photo preview feature in photo search
    var imageResult: ImageResult?
    var image: UIImage? // Used to pass through if selected in preview mode
    var asset: Any?
    var target: AnyObject?
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayDoneButton = false	// Prevent display of non-navbar done button
        initialize()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func selectAction() {
        self.browseDelegate?.photoBrowseController!(didFinishPickingPhoto: self.image, imageResult: self.imageResult, asset: self.asset)
    }
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.trackTintColor = Colors.gray90pcntColor
        self.progressTintColor = Colors.accentColor
        
        if self.mode == .preview {
            /* Configure toolbar */
            
            let toolbar: UIToolbar = super.toolbar
            
            let selectButton = UIBarButtonItem(title: "Use photo", style: UIBarButtonItemStyle.plain, target: self.target, action: #selector(selectAction))
            let flexSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
            
            selectButton.tintColor = Theme.colorTint
            
            fixedSpacer.width = 16
            
            var items = [UIBarButtonItem]()
            items.append(flexSpacer)
            items.append(selectButton)
            items.append(flexSpacer)
            
            toolbar.items = items
        }
        else {
            if self.message?.createdBy != nil {
                super.shareMessage = "Photo by \(self.message?.createdBy) on Patchr"
            }
            
            /* Configure bottom toolbar */
            
            let toolbar: UIToolbar = super.toolbar
            
            let flexSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
            let shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(IDMPhotoBrowser.actionButtonPressed(_:)))    // Handled by IDMPhotoBrowser
            
            self.likeButton = AirLikeButton(frame: CGRect(x:0, y:0, width:44, height:44))
            self.likeButton!.imageEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right:8)
            self.likeButton!.isHidden = (self.message == nil)
            
            fixedSpacer.width = 16
            
            let barLikeButton = UIBarButtonItem(customView: self.likeButton!)
            
            var items = [UIBarButtonItem]()
            items.append(flexSpacer)
            items.append(flexSpacer)	// Doubled up hack to prevent jitters because of animation
            items.append(barLikeButton)
            items.append(flexSpacer)
            items.append(flexSpacer)
            items.append(shareButton)
            
            toolbar.items = items
            
            if self.mode == .gallery {
                self.likeButton!.isHidden = false
            }
        }
    }
    
    override func performLayout() {
        super.performLayout()
        if self.mode == .browse {
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(IDMPhotoBrowser.doneButtonPressed(_:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(IDMPhotoBrowser.doneButtonPressed(_:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
        }
    }
    
	func bind(message: FireMessage!) {
		self.message = message
        self.likeButton!.bind(message: message)
		self.likeButton!.isHidden = (message == nil)
	}
}

public enum PhotoBrowserMode: Int {
    case gallery
    case preview
    case browse
}
