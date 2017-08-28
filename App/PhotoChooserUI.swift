//
//  PhotoChooserUI.swift
//  Patchr
//
//  Created by Brent on 2015-03-03.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import AssetsLibrary
import Foundation
import UIKit
import MobileCoreServices
import Photos
import IDMPhotoBrowser

// PhotoChooserUI
//
// This class manages the sequence of events that take place when a user needs to select an image for use
// within the app.
//

class PhotoChooserUI: NSObject, UINavigationControllerDelegate {
	/*
	 * Map from button indices to functions because some buttons aren't there all the
	 * time (for example, the camera is not available on the simulator).
	 */
    weak var hostViewController: UIViewController?
    weak var hostView: UIView?
    var chosenPhotoFunction: PhotoButtonFunction?
    
    fileprivate var completion: ((UIImage?, ImageResult?, Any?, Bool) -> Void)!

	fileprivate lazy var imagePickerController: UIImagePickerController = { [unowned self] in
		return UIImagePickerController(rootViewController: self.hostViewController!)
	}()

    init(hostViewController: UIViewController?, hostView: UIView?) {
		self.hostViewController = hostViewController
        self.hostView = hostView
		super.init()
	}

	func choosePhoto(sender: AnyObject, completion: @escaping (UIImage?, ImageResult?, Any?, Bool) -> Void) {
		
		self.completion = completion
        
		let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
		let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
		
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
		
		let search = UIAlertAction(title: "Search for photos", style: .default) { [weak self] action in
            guard let this = self else { return }
            this.searchForPhoto(imageType: .photo)
		}
		sheet.addAction(search)

		if photoLibraryAvailable {
			let library = UIAlertAction(title: "Select a library photo", style: .default) { [weak self] action in
                guard let this = self else { return }
				this.choosePhotoFromLibrary()
			}
			sheet.addAction(library)
		}
		
		if cameraAvailable {
			let camera = UIAlertAction(title: "Take a new photo", style: .default) { [weak self] action in
                guard let this = self else { return }
				this.takePhotoWithCamera()
			}
			sheet.addAction(camera)
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] action in
            guard let this = self else { return }
			sheet.dismiss(animated: true, completion: nil)
			this.completion!(nil, nil, nil, true)
		}
		
		sheet.addAction(cancel)
		
		if let presenter = sheet.popoverPresentationController {
			if let button = sender as? UIBarButtonItem {
				presenter.barButtonItem = button
			}
			else if let button = sender as? UIView {
				presenter.sourceView = button;
				presenter.sourceRect = button.bounds;
			}
		}
		
		hostViewController?.present(sheet, animated: true, completion: nil)
	}

	private func choosePhotoFromLibrary() {
        Reporting.track("choose_photo_from_library")
        chosenPhotoFunction = .ChooseLibraryPhoto
		let pickerController = UIImagePickerController()
        pickerController.sourceType = .photoLibrary
		pickerController.delegate = self
		pickerController.mediaTypes = [kUTTypeImage as String]
        
        if let hostController = self.hostViewController {
            if UIDevice.current.userInterfaceIdiom == .phone {
                hostController.present(pickerController, animated: true, completion: nil)
            }
            else {
                pickerController.modalPresentationStyle = .popover
                hostController.present(pickerController, animated: true, completion: nil)
                if let presentationController = pickerController.popoverPresentationController,
                    let hostView = self.hostView {
                    presentationController.sourceView = hostView
                    presentationController.sourceRect = hostView.bounds
                    presentationController.permittedArrowDirections = UIPopoverArrowDirection.any
                }
            }
        }
	}

	private func takePhotoWithCamera() {
        chosenPhotoFunction = .TakePhoto
		let pickerController = UIImagePickerController()
		pickerController.sourceType = .camera
		pickerController.delegate = self
		pickerController.mediaTypes = [kUTTypeImage as String]
        Reporting.track("take_photo_with_device")
		self.hostViewController?.present(pickerController, animated: true, completion: nil)
	}

    private func searchForPhoto(imageType: ImageType) {
        chosenPhotoFunction = .SearchPhoto
		let navController = AirNavigationController()
		let layout = UICollectionViewFlowLayout()
		let controller = PhotoSearchController(collectionViewLayout: layout)
        controller.inputImageType = imageType
		controller.pickerDelegate = self
		navController.viewControllers = [controller]
        Reporting.track("search_photos")
		self.hostViewController?.present(navController, animated: true, completion: nil)
	}

	fileprivate func addPhotoToAlbum(image: UIImage, toAlbum albumName: String, handler: @escaping (_ success: Bool) -> Void) {
        PHPhotoLibrary.saveImage(image: image, albumName: albumName) { asset in
            handler(asset != nil)
        }
	}

	enum PhotoButtonFunction {
		case TakePhoto
		case ChooseLibraryPhoto
		case SearchPhoto
	}
}

@objc protocol PhotoBrowseControllerDelegate {
    @objc optional func photoBrowseController(didFinishPickingPhoto: UIImage?, imageResult: ImageResult?, asset: Any?) -> Void
    @objc optional func photoBrowseController(didLikePhoto liked: Bool) -> Void
    @objc optional func photoBrowseControllerDidCancel() -> Void
}

extension PhotoChooserUI: PhotoBrowseControllerDelegate {
    
    func photoBrowseController(didFinishPickingPhoto image: UIImage?, imageResult: ImageResult?, asset: Any?) -> Void {
        hostViewController?.dismiss(animated: true, completion: nil)
        self.completion!(image, imageResult, asset, false)
    }
    
    func photoBrowseController(didLikePhoto liked: Bool) { }
    
    func photoBrowseControllerDidCancel() {
        hostViewController?.dismiss(animated: true, completion: nil)
		self.completion!(nil, nil, nil, true)
    }
}

extension PhotoChooserUI: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            var asset: Any?
            if let url = info[UIImagePickerControllerReferenceURL] as? URL {
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
                asset = fetchResult.firstObject! as PHAsset
            }
            else {
                asset = ["taken_at": DateUtils.now()] 
            }
            
			/* If the user took a photo then add it to the app photo album */
            if self.chosenPhotoFunction == .TakePhoto {
                hostViewController?.dismiss(animated: true, completion: nil)
                if PHPhotoLibrary.authorizationStatus() == .authorized {
                    self.addPhotoToAlbum(image: image, toAlbum: Strings.appName) { success in
                        print("Image added to \(Strings.appName) album: \(success)");
                        self.completion!(image, nil, asset, false)
                    }
                }
                else {
                    self.completion!(image, nil, asset, false)
                }
            }
            else {
                let photo = DisplayPhoto(image: image)!
                let browser = PhotoBrowser(photos: [photo] as [Any], animatedFrom: nil)
                
                browser?.mode = .preview
                browser?.usePopAnimation = true
                browser?.scaleImage = image  // Used because final image might have different aspect ratio than initially
                browser?.useWhiteBackgroundColor = true
                browser?.disableVerticalSwipe = false
                browser?.browseDelegate = self
                browser?.image = image // To pass through if selected
                browser?.asset = asset
                
                picker.present(browser!, animated:true, completion:nil)
            }
		}
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		hostViewController?.dismiss(animated: true, completion: nil)
	}
}
