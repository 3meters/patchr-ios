//
//  AirPhotoBrowserViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class GalleryBrowser: PhotoBrowser {
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
		super.initialize()
		self.likeButton.hidden = false
    }
	
	override func bindEntity(entity: Entity?) {
		super.bindEntity(entity)
	}
}
