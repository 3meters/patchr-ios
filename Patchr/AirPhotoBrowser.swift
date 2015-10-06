//
//  AirPhotoBrowserViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirPhotoBrowser: IDMPhotoBrowser {
    
    var browseDelegate: PhotoBrowseControllerDelegate?
    var imageResult: ImageResult?
    var likes: Bool = false
    var target: AnyObject?
    var likeButton: AirLikeButton = AirLikeButton()
    
    var entity: Entity?
    var linkedEntity: Entity? {
        set {
            self.entity = newValue
                self.likeButton.bindEntity(self.entity)
            likeButton.hidden = (self.entity == nil)
        }
        get {
            return self.entity
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayDoneButton = false
        configure()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func configure() {
        
        if self.entity?.creator != nil {
            super.shareMessage = "Photo by \(self.entity!.creator.name) on Patchr"
        }
        
        /* Configure toolbar */
        
        let toolbar: UIToolbar = super.toolbar
        
        let flexSpacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        let actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("actionButtonPressed:"))
        
        likeButton.frame = CGRectMake(0, 0, 44, 44)
        likeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right:8)
        likeButton.hidden = (self.entity == nil)
        
        fixedSpacer.width = 16
        
        let barLikeButton = UIBarButtonItem(customView: likeButton)
        barLikeButton.target = self
        barLikeButton.action = Selector("likeAction:")
        
        var items = [UIBarButtonItem]()
        items.append(flexSpacer)
        items.append(barLikeButton)
        items.append(flexSpacer)
        items.append(actionButton)
        
        toolbar.items = items
    }
}
