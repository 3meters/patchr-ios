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
	case placeholder
	case photo
}

@objc protocol PhotoEditDelegate: class {
    @objc optional func didClearPhoto()
    @objc optional func didSetPhoto()
    @objc optional func willSetPhoto()
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
    
    var photoDelegate: PhotoEditDelegate?

	var usingPhotoDefault: Bool = true
	var photoDirty: Bool = false
	var photoActive: Bool = false
	var photoChosen: Bool = false
	var photoSchema: String?
	var photoChooser: PhotoChooserUI?
	var photoMode: PhotoMode = .placeholder

    var photoGroup: UIView!
    var imageView: AirImageView!
    var setPhotoButton: UIButton!
    var editPhotoButton: UIButton!
    var clearPhotoButton: UIButton!
	var progressBlock: AWSS3TransferUtilityProgressBlock?

	var clearButtonAlignment: NSTextAlignment = .left
	var editButtonAlignment: NSTextAlignment = .right
	var setButtonAlignment: NSTextAlignment = .center

	/*--------------------------------------------------------------------------------------------
	* MARK: - Lifecycle
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
	* MARK: - Events
	*--------------------------------------------------------------------------------------------*/

	override func layoutSubviews() {
		super.layoutSubviews()

		self.photoGroup.fillSuperview()
		self.imageView.fillSuperview()
        self.imageView.progressView.anchorInCenter(withWidth: 150, height: 20)

        self.editPhotoButton.anchorBottomRight(withRightPadding: 6, bottomPadding: 6, width: 36, height: 36)
        self.clearPhotoButton.anchorBottomLeft(withLeftPadding: 6, bottomPadding: 6, width: 36, height: 36)

		if self.photoMode == .placeholder {
			self.setPhotoButton.anchorInCenter(withWidth: 48, height: 48)
		} else {
			self.setPhotoButton.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 48)
		}
	}

	func imageNotFoundAction(sender: AnyObject) {
        self.imageView.image = nil
        self.usingPhotoDefault = true
        configureTo(photoMode: .placeholder)
		self.photoActive = false
	}

	func editPhotoAction(sender: AnyObject) {
        Reporting.track("view_photo_editor")
		if self.controller != nil, let image = self.imageView.image {
			let controller = AdobeUXImageEditorViewController(image: image)
			controller.delegate = self
			self.controller!.present(controller, animated: true, completion: nil)
		}
	}

	func clearPhotoAction(sender: AnyObject) {
        Reporting.track("clear_photo")
        self.imageView.image = nil
        self.usingPhotoDefault = true
        configureTo(photoMode: .placeholder)
		self.photoActive = false
		self.photoDirty = true
        self.photoDelegate?.didClearPhoto?()
	}

	func setPhotoAction(sender: AnyObject) {
        Reporting.track("open_photo_options")
		self.photoChooser?.choosePhoto(sender: sender) { [weak self] image, imageResult, asset, cancelled in
            guard let this = self else { return }
			if !cancelled {
				DispatchQueue.main.async {
					this.photoChosen(image: image, imageResult: imageResult, asset: asset)
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
            self.photoDelegate?.didSetPhoto?()
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
                    this.photoDelegate?.didSetPhoto?()
                }
            }
            else {
                let dimension = imageResult!.width! >= imageResult!.height! ? ResizeDimension.width : ResizeDimension.height
                let url = GooglePlusProxy.url(url: imageResult!.contentUrl!, category: SizeCategory.profile, dimension: dimension)
                self.imageView.setImageWithUrl(url: url) { [weak self] success in
                    guard let this = self else { return }
                    if success {
                        this.photoDelegate?.didSetPhoto?()
                    }
                    else {
                        UIShared.toast(message: "Unable to download image")
                    }
                }  // Downloads and pushes into photoImage
            }
		}
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {

		NotificationCenter.default.addObserver(self
            , selector: #selector(self.imageNotFoundAction(sender:))
            , name: NSNotification.Name(rawValue: Events.ImageNotFound)
            , object: self.imageView)

		self.backgroundColor = Colors.clear

		self.progressBlock = { [weak self] task, progress in
            guard let this = self else { return }
			DispatchQueue.main.async {
				this.imageView.progressView.progress = CGFloat(progress.fractionCompleted)
                if progress.fractionCompleted == 1.0 {
                    this.imageView.hideProgress()
                }
			}
		}
        
        self.photoGroup = UIView()
		self.photoGroup.backgroundColor = Theme.colorBackgroundImage
		self.photoGroup.cornerRadius = 4
        self.photoGroup.clipsToBounds = true
        
        self.imageView = AirImageView(frame: CGRect.zero)
		self.imageView.contentMode = .scaleAspectFill

        self.editPhotoButton = UIButton(type: .custom)
		self.editPhotoButton.setImage(UIImage(named: "imgEdit2Light"), for: .normal)
		self.editPhotoButton.backgroundColor = Theme.colorScrimLighten
		self.editPhotoButton.cornerRadius = 18
		self.editPhotoButton.alpha = 0

        self.clearPhotoButton = UIButton(type: .custom)
		self.clearPhotoButton.setImage(UIImage(named: "imgCancelDark"), for: .normal)
		self.clearPhotoButton.backgroundColor = Theme.colorScrimLighten
		self.clearPhotoButton.cornerRadius = 18
		self.clearPhotoButton.alpha = 0

        self.setPhotoButton = UIButton(type: .custom)
		self.setPhotoButton.setImage(UIImage(named: "UIButtonCamera"), for: .normal)
        self.setPhotoButton.backgroundColor = (photoMode == .placeholder) ? Theme.colorScrimLighten : Theme.colorButtonFill
        self.setPhotoButton.cornerRadius = (photoMode == .placeholder) ? 24 : Theme.dimenButtonCornerRadius
        self.setPhotoButton.borderWidth = Theme.dimenButtonBorderWidth
        self.setPhotoButton.borderColor = (photoMode == .placeholder) ? Colors.clear : Theme.colorButtonBorder
		self.setPhotoButton.alpha = 0

		self.photoGroup.addSubview(self.imageView)
        self.addSubview(self.photoGroup)
        self.addSubview(self.setPhotoButton)
        self.addSubview(self.editPhotoButton)
        self.addSubview(self.clearPhotoButton)
        
		self.editPhotoButton.addTarget(self, action: #selector(editPhotoAction(sender:)), for: .touchUpInside)
		self.clearPhotoButton.addTarget(self, action: #selector(clearPhotoAction(sender:)), for: .touchUpInside)
		self.setPhotoButton.addTarget(self, action: #selector(setPhotoAction(sender:)), for: .touchUpInside)
	}

	func bind(url: URL, uploading: Bool? = false) {
        self.photoDelegate?.willSetPhoto?()
		self.imageView.setImageWithUrl(url: url, animate: true)
		self.usingPhotoDefault = false
		self.photoActive = true
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
		}
		else if photoMode == .placeholder {
            self.editPhotoButton.fadeOut()
            self.clearPhotoButton.fadeOut()
            self.setPhotoButton.fadeIn()
		}
		self.photoMode = photoMode
		self.setNeedsLayout()    // Needed because dimensions can change
	}
}

extension PhotoEditView: AdobeUXImageEditorViewControllerDelegate {

	func photoEditor(_ editor: AdobeUXImageEditorViewController, finishedWith image: UIImage?) {
		self.photoChosen(image: image, imageResult: nil, asset: self.imageView.asset)
		Reporting.track("edited_photo")
		self.controller!.dismiss(animated: true, completion: nil)
	}

	func photoEditorCanceled(_ editor: AdobeUXImageEditorViewController) {
        Reporting.track("cancel_photo_edit")
		self.controller!.dismiss(animated: true, completion: nil)
	}
}

