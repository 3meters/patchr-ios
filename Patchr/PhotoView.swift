//
//  PhotoTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 8/3/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

enum PhotoMode: Int {
    case None
    case Empty
    case Placeholder
    case Photo
}

class PhotoView: UIView {
    
    override var layoutMargins: UIEdgeInsets {
        get { return UIEdgeInsetsZero }
        set (newVal) {}
    }
    
    var photoMode: PhotoMode = .Empty
    
    @IBOutlet weak var photoGroup:   	 UIView?
    @IBOutlet weak var imageView:   	 AirImageButton?
    @IBOutlet weak var setPhotoButton:   UIButton?
    @IBOutlet weak var editPhotoButton:  UIButton?
    @IBOutlet weak var clearPhotoButton: UIButton?
    
    required init(coder aDecoder: NSCoder) {
        /* Called when instantiated from XIB or Storyboard */
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        /* Called when instantiated from code */
        super.init(frame: frame)
        initialize()
    }
    
    override func awakeFromNib() {
        initialize()
    }
    
    func initialize() {
        
        self.imageView?.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        self.imageView?.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
        self.imageView?.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
        
        self.setPhotoButton?.alpha = 0
        self.editPhotoButton?.alpha = 0
        self.clearPhotoButton?.alpha = 0
        self.photoGroup?.alpha = 0
    }
    
    func configureTo (photoMode: PhotoMode) {
        
        if photoMode == .Photo {
            self.editPhotoButton?.fadeIn()
            self.clearPhotoButton?.fadeIn()
            self.setPhotoButton?.fadeOut()
            if self.photoMode == .Empty {
                self.photoGroup?.fadeIn()
            }
        }
        else if photoMode == .Placeholder {
            self.setPhotoButton?.imageView?.tintColor = UIColor.whiteColor()
            if self.photoMode == .Photo {
                self.editPhotoButton?.fadeOut()
                self.clearPhotoButton?.fadeOut()
                self.setPhotoButton?.fadeIn()
            }
            else if self.photoMode == .Empty {
                self.photoGroup?.fadeIn()
                self.setPhotoButton?.fadeIn()
            }
        }
        else if photoMode == .Empty {
            self.photoGroup?.fadeOut()
            self.setPhotoButton?.fadeIn()
        }
        self.photoMode = photoMode
    }
}
