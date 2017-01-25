//
//  PhotoTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 8/3/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import AWSS3
import Photos

enum PhotoMode: Int {
    case None
    case Empty
    case Placeholder
    case Photo
}

class PhotoEditView: UIView {
	
	override var layoutMargins: UIEdgeInsets {
		get { return UIEdgeInsets.zero }
		set (newVal) {}
	}
	
	var usingPhotoDefault: Bool = true
	var photoDirty: Bool = false
	var photoActive: Bool = false
	var photoChosen: Bool = false
	weak var controller: UIViewController?
	
	var photoSchema: String?
	
	var photoChooser: PhotoChooserUI?
    var photoMode: PhotoMode = .Empty
	
    var photoGroup			= UIView()
	var scrimGroup			= UIView()
    var imageButton			= AirImageView(frame: CGRect.zero)
    var setPhotoButton		= UIButton()
    var editPhotoButton		= UIButton()
    var clearPhotoButton	= UIButton()
    var progressView        = UIProgressView(progressViewStyle: .default)
    var progressBlock       : AWSS3TransferUtilityProgressBlock?
	
	var clearButtonAlignment: NSTextAlignment = NSTextAlignment.left
	var editButtonAlignment: NSTextAlignment = NSTextAlignment.right
	var setButtonAlignment: NSTextAlignment = NSTextAlignment.center
    
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
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.photoGroup.fillSuperview()
		self.imageButton.fillSuperview()
        self.progressView.anchorInCenter(withWidth: self.width() - 32, height: 12)
		self.scrimGroup.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
		
		if self.editButtonAlignment == .right {
			self.editPhotoButton.anchorCenterRight(withRightPadding: 6, width: 36, height: 36)
		}
		else if self.editButtonAlignment == .left {
			self.editPhotoButton.anchorCenterLeft(withLeftPadding: 6, width: 36, height: 36)
		}
		
		if self.clearButtonAlignment == .right {
			self.clearPhotoButton.anchorCenterRight(withRightPadding: 6, width: 36, height: 36)
		}
		else if self.clearButtonAlignment == .left {
			self.clearPhotoButton.anchorCenterLeft(withLeftPadding: 6, width: 36, height: 36)
		}
		
		if self.photoMode == .Placeholder {
			self.setPhotoButton.anchorInCenter(withWidth: 48, height: 48)
		}
		else {
			self.setPhotoButton.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 48)
		}
	}
	
	func imageNotFoundAction(sender: AnyObject) {
		if self.photoSchema == Schema.ENTITY_MESSAGE {
			self.imageButton.image = nil
			configureTo(photoMode: .Empty)
		}
		else {
			self.imageButton.image = nil
			self.usingPhotoDefault = true
			configureTo(photoMode: .Placeholder)
		}
		
		self.photoActive = false
	}
	
	func editPhotoAction(sender: AnyObject){
        if self.controller != nil, let image = self.imageButton.image {
			let controller = AdobeUXImageEditorViewController(image: image)
			controller.delegate = self
			self.controller!.present(controller, animated: true, completion: nil)
		}
	}
	
	func clearPhotoAction(sender: AnyObject) {
		if self.photoSchema == Schema.ENTITY_MESSAGE {
			self.imageButton.image = nil
			configureTo(photoMode: .Empty)
		}
		else {
			self.imageButton.image = nil
			self.usingPhotoDefault = true
			configureTo(photoMode: .Placeholder)
		}
		
		self.photoActive = false
		self.photoDirty = true
		
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: self)
	}
	
	func setPhotoAction(sender: AnyObject) {
		self.photoChooser?.choosePhoto(sender: sender) { [weak self] image, imageResult, asset, cancelled in
			if !cancelled {
                DispatchQueue.main.async {
                    self?.photoChosen(image: image, imageResult: imageResult, asset: asset)
                }
			}
		}
	}
	
    func photoChosen(image: UIImage?, imageResult: ImageResult?, asset: Any?) -> Void {
		
        self.usingPhotoDefault = false
        self.photoDirty = true
        self.photoActive = true
        self.photoChosen = true
        
        configureTo(photoMode: .Photo)
        
		if image != nil {
			self.imageButton.image = image
            self.imageButton.asset = asset
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: self)
		}
		else if imageResult != nil {
			/*
			 * Request image via resizer so size is capped. We don't use imgix because it only uses
			 * known image sources that we setup like our buckets on s3.
			 */
			let dimension = imageResult!.width! >= imageResult!.height! ? ResizeDimension.width : ResizeDimension.height
			let url = URL(string: GooglePlusProxy.convert(uri: imageResult!.contentUrl!, size: Int(IMAGE_DIMENSION_MAX), dimension: dimension))
            self.imageButton.setImageWithUrl(url: url!, fallbackUrl: nil) { [weak self] success in
                if self != nil {
                    if success {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: self)
                    }
                    else {
                        UIShared.Toast(message: "Unable to download image")
                    }
                }
            }  // Downloads and pushes into photoImage
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {
		
		NotificationCenter.default.addObserver(self, selector: #selector(PhotoEditView.imageNotFoundAction(sender:)), name: NSNotification.Name(rawValue: Events.ImageNotFound), object: self.imageButton)
		
		self.backgroundColor = Colors.clear
        
        self.progressView.isHidden = true
        self.progressBlock = { task, progress in
            DispatchQueue.main.async {
                self.progressView.progress = Float(progress.fractionCompleted)
                self.progressView.isHidden = (progress.fractionCompleted == 1.0)
            }
        }
        
		self.photoGroup.alpha = 0
		self.photoGroup.backgroundColor = Theme.colorBackgroundImage
		self.photoGroup.cornerRadius = 4
		self.photoGroup.clipsToBounds = true
		
		self.imageButton.contentMode = .scaleAspectFill
		self.imageButton.sizeCategory = SizeCategory.standard
		
		self.editPhotoButton.setImage(UIImage(named: "imgEdit2Light"), for: .normal)
		self.editPhotoButton.backgroundColor = Theme.colorScrimLighten
		self.editPhotoButton.cornerRadius = 18
		self.editPhotoButton.alpha = 0
		
		self.clearPhotoButton.setImage(UIImage(named: "imgCancelDark"), for: .normal)
		self.clearPhotoButton.backgroundColor = Theme.colorScrimLighten
		self.clearPhotoButton.cornerRadius = 18
		self.clearPhotoButton.alpha = 0
		
		self.setPhotoButton.setImage(UIImage(named: "UIButtonCamera"), for: .normal)
		self.setPhotoButton.borderWidth = Theme.dimenButtonBorderWidth
		
		if photoMode == .Placeholder {
			self.setPhotoButton.backgroundColor = Theme.colorScrimLighten
			self.setPhotoButton.borderColor = Colors.clear
			self.setPhotoButton.cornerRadius = 24
		}
		else {
			self.setPhotoButton.backgroundColor = Theme.colorButtonFill
			self.setPhotoButton.borderColor = Theme.colorButtonBorder
			self.setPhotoButton.cornerRadius = Theme.dimenButtonCornerRadius
		}
		
		self.setPhotoButton.alpha = 0
        
        self.addSubview(self.photoGroup)
        self.photoGroup.addSubview(self.imageButton)
        self.photoGroup.addSubview(self.scrimGroup)
        self.photoGroup.addSubview(self.progressView)
        self.scrimGroup.addSubview(self.editPhotoButton)
        self.scrimGroup.addSubview(self.clearPhotoButton)
		self.addSubview(self.setPhotoButton)
		
		self.editPhotoButton.addTarget(self, action: #selector(editPhotoAction(sender:)), for: .touchUpInside)
		self.clearPhotoButton.addTarget(self, action: #selector(clearPhotoAction(sender:)), for: .touchUpInside)
		self.setPhotoButton.addTarget(self, action: #selector(setPhotoAction(sender:)), for: .touchUpInside)
	}
	
    func bind(url: URL, fallbackUrl: URL?, uploading: Bool = false) {
        if uploading {
            self.imageButton.setImageFromCache(url: url, animate: true)
        }
        else {
            self.imageButton.setImageWithUrl(url: url, fallbackUrl: fallbackUrl, animate: true)
        }
        self.usingPhotoDefault = false
        self.photoActive = true
    }
    
    func reset() {
        self.imageButton.image = nil
        configureTo(photoMode: .Empty)
        self.photoDirty = false
        self.photoActive = false
        self.photoChosen = false
    }

    func setHost(controller: UIViewController, view: UIView?) {
		self.controller = controller
        self.photoChooser = PhotoChooserUI(hostViewController: controller, hostView: view)
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
			self.setPhotoButton.borderColor = Colors.clear
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
		self.setNeedsLayout()	// Needed because dimensions can change
    }
}

extension PhotoEditView: AdobeUXImageEditorViewControllerDelegate {
	
	func photoEditor(_ editor: AdobeUXImageEditorViewController, finishedWith image: UIImage?) {
        self.photoChosen(image: image, imageResult: nil, asset: self.imageButton.asset)
		Reporting.track("Edited Photo")
		self.controller!.dismiss(animated: true, completion: nil)
	}
	
	func photoEditorCanceled(_ editor: AdobeUXImageEditorViewController) {
		self.controller!.dismiss(animated: true, completion: nil)
	}
}

