//
//  AirPhotoBrowserViewController.swift
//  Patchr
//
//  Created by Jay Massena on 7/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirPhotoBrowser: IDMPhotoBrowser {
    
    var pickerDelegate: PhotoPickerControllerDelegate?
    var imageResult: ImageResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addToolbar() {
        
        /* Toolbar buttons */
        var selectButton = UIBarButtonItem(title: "Use photo", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("actionSelect"))
        var flexSpacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        var fixedSpacer = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        fixedSpacer.width = 16
        
        var items = [AnyObject]()
        items.append(flexSpacer)
        items.append(selectButton)
        items.append(flexSpacer)
        
        /* Toolbar */
        let toolbar = UIToolbar()
        toolbar.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 46)
        toolbar.sizeToFit()
        toolbar.clipsToBounds = true
        toolbar.translucent = true
        toolbar.setItems(items, animated: true)
        self.view.addSubview(toolbar)
    }
    
    func addNavigationBar() {
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44 + 20)) // nav height + status bar height
        navigationBar.translucent = true
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("doneButtonPressed:"))]
        navigationBar.items = [navigationItem]
        self.view.addSubview(navigationBar)
    }
    
    func actionSelect() {
        pickerDelegate?.photoPickerController(didFinishPickingPhoto: self.imageResult!)
    }
}
