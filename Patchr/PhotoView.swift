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
	
	var usingPhotoDefault: Bool = true
	var photoDirty: Bool = false
	var photoActive: Bool = false
	var photoChosen: Bool = false
	var controller: UIViewController?
	
	var photoSchema: String?
	var photoDefaultId: String?
	
	var photoChooser: PhotoChooserUI?
    var photoMode: PhotoMode = .Empty
	
    var photoGroup			= UIView()
	var scrimGroup			= UIView()
    var imageButton			= AirImageButton()
    var setPhotoButton		= UIButton()
    var editPhotoButton		= UIButton()
    var clearPhotoButton	= UIButton()
	
	var clearButtonAlignment: NSTextAlignment = NSTextAlignment.Left
	var editButtonAlignment: NSTextAlignment = NSTextAlignment.Right
	var setButtonAlignment: NSTextAlignment = NSTextAlignment.Center
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
    required init(coder aDecoder: NSCoder) {
        /* Called when instantiated from XIB or Storyboard */
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect) {
        /* Called when instantiated from code */
        super.init(frame: frame)
        initialize()
    }
	
    func initialize() {
		
		self.backgroundColor = UIColor.clearColor()
		
		self.photoGroup.alpha = 0
		self.photoGroup.backgroundColor = Theme.colorBackgroundImage
		self.photoGroup.cornerRadius = 4
		self.photoGroup.clipsToBounds = true
		self.addSubview(self.photoGroup)
		
		self.imageButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
		self.imageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
		self.imageButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
		self.photoGroup.addSubview(self.imageButton)
		
		self.photoGroup.addSubview(self.scrimGroup)

		self.editPhotoButton.setImage(UIImage(named: "imgEdit2Light"), forState: .Normal)
		self.editPhotoButton.backgroundColor = Theme.colorScrimLighten
		self.editPhotoButton.cornerRadius = 18
		self.editPhotoButton.alpha = 0
		self.scrimGroup.addSubview(self.editPhotoButton)
		
		self.clearPhotoButton.setImage(UIImage(named: "imgCancelDark"), forState: .Normal)
		self.clearPhotoButton.backgroundColor = Theme.colorScrimLighten
		self.clearPhotoButton.cornerRadius = 18
		self.clearPhotoButton.alpha = 0
		self.scrimGroup.addSubview(self.clearPhotoButton)
		
		self.setPhotoButton.setImage(UIImage(named: "UIButtonCamera"), forState: .Normal)
		self.setPhotoButton.borderWidth = Theme.dimenButtonBorderWidth
		
		if photoMode == .Placeholder {
			self.setPhotoButton.backgroundColor = Theme.colorScrimLighten
			self.setPhotoButton.borderColor = UIColor.clearColor()
			self.setPhotoButton.cornerRadius = 24
		}
		else {
			self.setPhotoButton.backgroundColor = Theme.colorButtonFill
			self.setPhotoButton.borderColor = Theme.colorButtonBorder
			self.setPhotoButton.cornerRadius = Theme.dimenButtonCornerRadius
		}

        self.setPhotoButton.alpha = 0
		self.addSubview(self.setPhotoButton)
		
		self.editPhotoButton.addTarget(self, action: Selector("editPhotoAction:"), forControlEvents: .TouchUpInside)
		self.clearPhotoButton.addTarget(self, action: Selector("clearPhotoAction:"), forControlEvents: .TouchUpInside)
		self.setPhotoButton.addTarget(self, action: Selector("setPhotoAction:"), forControlEvents: .TouchUpInside)
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.photoGroup.fillSuperview()
		self.imageButton.fillSuperview()
		self.scrimGroup.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 48)
		
		if self.editButtonAlignment == .Right {
			self.editPhotoButton.anchorCenterRightWithRightPadding(6, width: 36, height: 36)
		}
		else if self.editButtonAlignment == .Left {
			self.editPhotoButton.anchorCenterLeftWithLeftPadding(6, width: 36, height: 36)
		}
		
		if self.clearButtonAlignment == .Right {
			self.clearPhotoButton.anchorCenterRightWithRightPadding(6, width: 36, height: 36)
		}
		else if self.clearButtonAlignment == .Left {
			self.clearPhotoButton.anchorCenterLeftWithLeftPadding(6, width: 36, height: 36)
		}
		
		if self.photoMode == .Placeholder {
			self.setPhotoButton.anchorInCenterWithWidth(48, height: 48)
		}
		else {
			self.setPhotoButton.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 48)
		}
	}
	
	func editPhotoAction(sender: AnyObject){
		if self.controller != nil {
			NSNotificationCenter.defaultCenter().postNotificationName(Events.PhotoViewHasFocus, object: nil)
			let controller = AdobeUXImageEditorViewController(image: self.imageButton.imageForState(.Normal))
			controller.delegate = self
			self.controller!.presentViewController(controller, animated: true, completion: nil)
		}
	}
	
	func clearPhotoAction(sender: AnyObject) {
		
		NSNotificationCenter.defaultCenter().postNotificationName(Events.PhotoViewHasFocus, object: nil)
		
		if self.photoSchema == Schema.ENTITY_MESSAGE {
			self.imageButton.setImage(nil, forState: .Normal)
			configureTo(.Empty)
		}
		else {
			let photo: Photo = Entity.getDefaultPhoto(self.photoSchema, id: self.photoDefaultId)
			self.imageButton.setImageWithPhoto(photo)
			self.usingPhotoDefault = true
			configureTo(.Placeholder)
		}
		
		self.photoActive = false
		self.photoDirty = true
		
		NSNotificationCenter.defaultCenter().postNotificationName(Events.PhotoDidChange, object: nil)
	}
	
	func setPhotoAction(sender: AnyObject) {
		NSNotificationCenter.defaultCenter().postNotificationName(Events.PhotoViewHasFocus, object: nil)
		self.photoChooser?.choosePhoto() {
			[weak self] image, imageResult, cancelled in
			
			if !cancelled {
				self?.photoChosen(image, imageResult: imageResult)
			}
		}
	}
	
	func photoChosen(image: UIImage?, imageResult: ImageResult?) -> Void {
		
		if image != nil {
			self.imageButton.setImage(image, forState: .Normal)
		}
		else {
			self.imageButton.setImageWithImageResult(imageResult!)  // Downloads and pushes into photoImage
		}
		
		self.usingPhotoDefault = false
		
		self.photoDirty = true
		self.photoActive = true
		self.photoChosen = true
		
		configureTo(.Photo)
		
		NSNotificationCenter.defaultCenter().postNotificationName(Events.PhotoDidChange, object: nil)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func bindPhoto(photo: Photo?, showDefault: Bool = false) {
		if photo != nil {
			self.imageButton.setImageWithPhoto(photo!)
			self.usingPhotoDefault = false
			self.photoActive = true
		}
		else if showDefault {
			let photo: Photo = Entity.getDefaultPhoto(self.photoSchema, id: self.photoDefaultId)
			self.imageButton.setImageWithPhoto(photo)
			self.usingPhotoDefault = true
			self.photoActive = false
		}
	}
	
	func setHostController(controller: UIViewController) {
		self.controller = controller
		self.photoChooser = PhotoChooserUI(hostViewController: controller)
	}
	
	func configureTo (photoMode: PhotoMode) {
		
        if photoMode == .Photo {
            self.editPhotoButton.fadeIn()
            self.clearPhotoButton.fadeIn()
            self.setPhotoButton.fadeOut()
			
            if self.photoMode == .Empty {
                self.photoGroup.fadeIn()
            }
        }
        else if photoMode == .Placeholder {
			self.setPhotoButton.borderColor = UIColor.clearColor()
			self.setPhotoButton.backgroundColor = Theme.colorScrimLighten
			self.setPhotoButton.cornerRadius = 24
			
            if self.photoMode == .Photo {				
				self.editPhotoButton.fadeOut()
				self.clearPhotoButton.fadeOut()
                self.setPhotoButton.fadeIn()
            }
            else if self.photoMode == .Empty {
                self.photoGroup.fadeIn()
                self.setPhotoButton.fadeIn()
            }
        }
        else if photoMode == .Empty {
			self.setPhotoButton.backgroundColor = Theme.colorButtonFill
			self.setPhotoButton.borderColor = Theme.colorButtonBorder
			self.setPhotoButton.cornerRadius = Theme.dimenButtonCornerRadius
			
            self.setPhotoButton.fadeIn()
			self.photoGroup.fadeOut()
        }
        self.photoMode = photoMode
		self.setNeedsLayout()
    }
}

extension PhotoView: AdobeUXImageEditorViewControllerDelegate {
	
	func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
		self.photoChosen(image, imageResult: nil)
		self.controller!.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
		self.controller!.dismissViewControllerAnimated(true, completion: nil)
	}
}

