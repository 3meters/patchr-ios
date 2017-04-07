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
	case none
	case empty
	case placeholder
	case photo
}

class PhotoEditView: UIView {

    weak var controller: UIViewController?
    
	override var layoutMargins: UIEdgeInsets {
		get {
			return UIEdgeInsets.zero
		}
		set(newVal) {
		}
	}

	var usingPhotoDefault: Bool = true
	var photoDirty: Bool = false
	var photoActive: Bool = false
	var photoChosen: Bool = false
	var photoSchema: String?
	var photoChooser: PhotoChooserUI?
	var photoMode: PhotoMode = .empty

	var photoGroup = UIView()
	var scrimGroup = UIView()
	var imageView = AirImageView(frame: CGRect.zero)
	var setPhotoButton = UIButton()
	var editPhotoButton = UIButton()
	var clearPhotoButton = UIButton()
	var progressBlock: AWSS3TransferUtilityProgressBlock?

	var clearButtonAlignment: NSTextAlignment = .left
	var editButtonAlignment: NSTextAlignment = .right
	var setButtonAlignment: NSTextAlignment = .center

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
		self.imageView.fillSuperview()
        self.imageView.progressView.anchorInCenter(withWidth: 150, height: 20)
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

		if self.photoMode == .placeholder {
			self.setPhotoButton.anchorInCenter(withWidth: 48, height: 48)
		}
		else {
			self.setPhotoButton.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 48)
		}
	}

	func imageNotFoundAction(sender: AnyObject) {
		if self.photoSchema == Schema.entityMessage {
			self.imageView.image = nil
			configureTo(photoMode: .empty)
		}
		else {
			self.imageView.image = nil
			self.usingPhotoDefault = true
			configureTo(photoMode: .placeholder)
		}

		self.photoActive = false
	}

	func editPhotoAction(sender: AnyObject) {
		if self.controller != nil, let image = self.imageView.image {
			let controller = AdobeUXImageEditorViewController(image: image)
			controller.delegate = self
			self.controller!.present(controller, animated: true, completion: nil)
		}
	}

	func clearPhotoAction(sender: AnyObject) {
		if self.photoSchema == Schema.entityMessage {
			self.imageView.image = nil
			configureTo(photoMode: .empty)
		}
		else {
			self.imageView.image = nil
			self.usingPhotoDefault = true
			configureTo(photoMode: .placeholder)
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

		configureTo(photoMode: .photo)

		if image != nil {
			self.imageView.image = image
			self.imageView.asset = asset
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: self)
		}
		else if imageResult != nil {
			/*
			 * Request image via resizer so size is capped. We don't use imgix because it only uses
			 * known image sources that we setup like our buckets on s3.
			 */
            if imageResult!.encodingFormat == "animatedgif" {
                self.imageView.setImageWithUrl(url: URL(string: imageResult!.contentUrl!)!, imageType: .animatedGif) { [weak self] success in
                    guard let this = self else { return }
                    if !success {
                        UIShared.toast(message: "Unable to download image")
                        return
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: this)
                }
            }
            else {
                let dimension = imageResult!.width! >= imageResult!.height! ? ResizeDimension.width : ResizeDimension.height
                let url = URL(string: GooglePlusProxy.convert(uri: imageResult!.contentUrl!, size: Int(Config.imageDimensionMax), dimension: dimension))
                self.imageView.setImageWithUrl(url: url!) { [weak self] success in
                    if self != nil {
                        if success {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: self)
                        }
                        else {
                            UIShared.toast(message: "Unable to download image")
                        }
                    }
                }  // Downloads and pushes into photoImage
            }
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {

		NotificationCenter.default.addObserver(self
            , selector: #selector(self.imageNotFoundAction(sender:))
            , name: NSNotification.Name(rawValue: Events.ImageNotFound)
            , object: self.imageView)

		self.backgroundColor = Colors.clear

		self.progressBlock = { [weak self] task, progress in
			DispatchQueue.main.async {
				self?.imageView.progressView.progress = CGFloat(progress.fractionCompleted)
                if progress.fractionCompleted == 1.0 {
                    self?.imageView.hideProgress()
                }
			}
		}

		self.photoGroup.alpha = 0
		self.photoGroup.backgroundColor = Theme.colorBackgroundImage
		self.photoGroup.cornerRadius = 4
		self.photoGroup.clipsToBounds = true

		self.imageView.contentMode = .scaleAspectFill

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

		if photoMode == .placeholder {
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
		self.photoGroup.addSubview(self.imageView)
		self.photoGroup.addSubview(self.scrimGroup)
		self.scrimGroup.addSubview(self.editPhotoButton)
		self.scrimGroup.addSubview(self.clearPhotoButton)
		self.addSubview(self.setPhotoButton)

		self.editPhotoButton.addTarget(self, action: #selector(editPhotoAction(sender:)), for: .touchUpInside)
		self.clearPhotoButton.addTarget(self, action: #selector(clearPhotoAction(sender:)), for: .touchUpInside)
		self.setPhotoButton.addTarget(self, action: #selector(setPhotoAction(sender:)), for: .touchUpInside)
	}

	func bind(url: URL, uploading: Bool? = false) {
		self.imageView.setImageWithUrl(url: url, animate: true)
		self.usingPhotoDefault = false
		self.photoActive = true
	}

	func reset() {
		self.imageView.image = nil
		configureTo(photoMode: .empty)
		self.photoDirty = false
		self.photoActive = false
		self.photoChosen = false
	}

	func setHost(controller: UIViewController?, view: UIView?) {
		self.controller = controller
		self.photoChooser = PhotoChooserUI(hostViewController: self.controller, hostView: view)
	}

	func configureTo(photoMode: PhotoMode) {

		if photoMode == .photo {
			self.editPhotoButton.fadeIn()
			self.clearPhotoButton.fadeIn()
			self.setPhotoButton.fadeOut()

			if self.photoMode == .empty {
				self.photoGroup.fadeIn()
			}
		}
		else if photoMode == .placeholder {
			self.setPhotoButton.borderColor = Colors.clear
			self.setPhotoButton.backgroundColor = Theme.colorScrimLighten
			self.setPhotoButton.cornerRadius = 24

			if self.photoMode == .photo {
				self.editPhotoButton.fadeOut()
				self.clearPhotoButton.fadeOut()
				self.setPhotoButton.fadeIn()
			}
			else if self.photoMode == .empty {
				self.photoGroup.fadeIn()
				self.setPhotoButton.fadeIn()
			}
		}
		else if photoMode == .empty {
			self.setPhotoButton.backgroundColor = Theme.colorButtonFill
			self.setPhotoButton.borderColor = Theme.colorButtonBorder
			self.setPhotoButton.cornerRadius = Theme.dimenButtonCornerRadius

			self.setPhotoButton.fadeIn()
			self.photoGroup.fadeOut()
		}
		self.photoMode = photoMode
		self.setNeedsLayout()    // Needed because dimensions can change
	}
}

extension PhotoEditView: AdobeUXImageEditorViewControllerDelegate {

	func photoEditor(_ editor: AdobeUXImageEditorViewController, finishedWith image: UIImage?) {
		self.photoChosen(image: image, imageResult: nil, asset: self.imageView.asset)
		Reporting.track("Edited Photo")
		self.controller!.dismiss(animated: true, completion: nil)
	}

	func photoEditorCanceled(_ editor: AdobeUXImageEditorViewController) {
		self.controller!.dismiss(animated: true, completion: nil)
	}
}

