//
//  AirPhotoBrowserViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirPhotoPreview: AirPhotoBrowser {
    
    override func configure() {
        
        var toolbar: UIToolbar = super.toolbar
        
        /* Toolbar buttons */
        var selectButton = UIBarButtonItem(title: "Use photo", style: UIBarButtonItemStyle.Plain, target: target, action: Selector("selectAction"))
        var flexSpacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        var fixedSpacer = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        fixedSpacer.width = 16
        
        var items = [AnyObject]()
        items.append(flexSpacer)
        items.append(selectButton)
        items.append(flexSpacer)
        
        toolbar.items = items
    }
    
    func selectAction() {
        browseDelegate?.photoBrowseController!(didFinishPickingPhoto: self.imageResult!)
    }    
}
