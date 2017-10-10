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
    
    var likes: Bool = false
    var reactionToolbar: AirReactionToolbar!
    var message: FireMessage?  // Needed to make the reaction button work
    var mode: PhotoBrowserMode = .browse
    var selectButton: UIBarButtonItem?
    
    /* UI specialized for previewing photos from the photo picker. */
    var browseDelegate: PhotoBrowseControllerDelegate?  // Used by photo preview feature in photo search
    var imageResult: ImageResult?
    var image: UIImage? // Used to pass through if selected in preview mode
    var asset: Any?
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.displayDoneButton = false	// Prevent display of non-navbar done button
        initialize()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    @objc func selectAction(sender: AnyObject?) {
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
            if let toolbar = super.toolbar {
                
                self.selectButton = UIBarButtonItem(title: nil, style: UIBarButtonItemStyle.plain, target: self, action: #selector(selectAction(sender:)))
                self.selectButton!.tintColor = Theme.colorTint
                
                var items = [UIBarButtonItem]()
                items.append(UI.spacerFlex)
                items.append(selectButton!)
                items.append(UI.spacerFlex)
                toolbar.items = items
            }
        }
        else {
            if self.message?.createdBy != nil {
                let createdBy = (self.message?.createdBy)!
                super.shareMessage = "photo_share_message".localizedFormat(createdBy, Strings.appName)
            }
            
            /* Configure bottom toolbar */
            
            if let toolbar = super.toolbar {
                let shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(IDMPhotoBrowser.actionButtonPressed(_:)))    // Handled by IDMPhotoBrowser
                self.reactionToolbar = AirReactionToolbar()
                self.reactionToolbar.bounds.size = CGSize(width: Config.screenWidth - 96, height: 32)
                self.reactionToolbar.isHidden = (self.message == nil)
                
                let barReactionButton = UIBarButtonItem(customView: self.reactionToolbar)
                
                var items = [UIBarButtonItem]()
                items.append(barReactionButton)
                items.append(UI.spacerFlex)    // Doubled up hack to prevent jitters because of animation
                items.append(UI.spacerFlex)
                items.append(shareButton)
                toolbar.items = items
                
                if self.mode == .gallery {
                    self.reactionToolbar.isHidden = false
                }
            }
        }
        bindLanguage()
    }
    
    func bindLanguage() {
        self.selectButton?.title = "photo_use".localized()
    }
    
    override func performLayout() {
        super.performLayout()
        if self.mode == .browse {
            let doneButton = UIBarButtonItem(title: "done".localized(), style: .plain, target: self, action: #selector(IDMPhotoBrowser.doneButtonPressed(_:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(IDMPhotoBrowser.doneButtonPressed(_:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
    }
}

public enum PhotoBrowserMode: Int {
    case gallery
    case preview
    case browse
}
