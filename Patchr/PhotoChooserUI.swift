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
    typealias CompletionHandler = (_ success:Bool) -> Void
    
    weak var hostViewController: UIViewController?
    var chosenPhotoFunction: PhotoButtonFunction?
    
    fileprivate var finishedChoosing: ((UIImage?, ImageResult?, PHAsset?, Bool) -> Void)? = nil

	fileprivate lazy var imagePickerController: UIImagePickerController = {
		return UIImagePickerController(rootViewController: self.hostViewController!)
	}()

	init(hostViewController: UIViewController) {
		self.hostViewController = hostViewController
		super.init()
	}

	func choosePhoto(sender: AnyObject, finishedChoosing: @escaping (UIImage?, ImageResult?, PHAsset?, Bool) -> Void) {
		
		self.finishedChoosing = finishedChoosing
		let cameraAvailable       = UIImagePickerController.isSourceTypeAvailable(.camera)
		let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
		
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
		
		let search = UIAlertAction(title: "Search for photos", style: .default) { action in
			self.searchForPhoto()
		}
		sheet.addAction(search)
		
		if photoLibraryAvailable {
			let library = UIAlertAction(title: "Select a library photo", style: .default) { action in
				self.choosePhotoFromLibrary()
			}
			sheet.addAction(library)
		}
		
		if cameraAvailable {
			let camera = UIAlertAction(title: "Take a new photo", style: .default) { action in
				self.takePhotoWithCamera()
			}
			sheet.addAction(camera)
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
			sheet.dismiss(animated: true, completion: nil)
			self.finishedChoosing!(nil, nil, nil, true)
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
                    let hostView = hostController.view {
                    presentationController.sourceView = hostView
                    presentationController.sourceRect = CGRect(x: hostView.frame.size.width / 2, y: hostView.frame.size.height / 4, width: 0, height: 0)
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
		self.hostViewController?.present(pickerController, animated: true, completion: nil)
	}

	private func searchForPhoto() {
        chosenPhotoFunction = .SearchPhoto
		let navController = AirNavigationController()
		let layout = UICollectionViewFlowLayout()
		let controller = PhotoSearchController(collectionViewLayout: layout)
		controller.pickerDelegate = self
		navController.viewControllers = [controller]
		self.hostViewController?.present(navController, animated: true, completion: nil)
	}

	fileprivate func addPhotoToAlbum(image: UIImage, toAlbum albumName: String, handler: @escaping CompletionHandler) {
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
    @objc optional func photoBrowseController(didFinishPickingPhoto: UIImage?, imageResult: ImageResult?, asset: PHAsset?) -> Void
    @objc optional func photoBrowseController(didLikePhoto liked: Bool) -> Void
    @objc optional func photoBrowseControllerDidCancel() -> Void
}

extension PhotoChooserUI: PhotoBrowseControllerDelegate {
    
    func photoBrowseController(didFinishPickingPhoto image: UIImage?, imageResult: ImageResult?, asset: PHAsset?) -> Void {
        hostViewController?.dismiss(animated: true, completion: nil)
        self.finishedChoosing!(image, imageResult, asset, false)
    }
    
    func photoBrowseController(didLikePhoto liked: Bool) { }
    
    func photoBrowseControllerDidCancel() {
        hostViewController?.dismiss(animated: true, completion: nil)
		self.finishedChoosing!(nil, nil, nil, true)
    }
}

extension PhotoChooserUI: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            var asset: PHAsset?
            if let url = info[UIImagePickerControllerReferenceURL] as? URL {
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
                asset = fetchResult.firstObject! as PHAsset
            }
            
			/* If the user took a photo then add it to the patchr photo album */
            if self.chosenPhotoFunction == .TakePhoto {
                hostViewController?.dismiss(animated: true, completion: nil)
                if PHPhotoLibrary.authorizationStatus() == .authorized {
                    self.addPhotoToAlbum(image: image, toAlbum: "Patchr") { success in
                        print("Image added to Patchr album: \(success)");
                        self.finishedChoosing!(image, nil, asset, false)
                    }
                }
                else {
                    self.finishedChoosing!(image, nil, asset, false)
                }
            }
            else {
                let photo = IDMPhoto(image: image)!
                let photos = Array([photo])
                let browser = PhotoBrowser(photos: photos as [AnyObject], animatedFrom: nil)
                
                browser?.mode = .preview
                browser?.usePopAnimation = true
                browser?.scaleImage = image  // Used because final image might have different aspect ratio than initially
                browser?.useWhiteBackgroundColor = true
                browser?.disableVerticalSwipe = false
                browser?.browseDelegate = self
                browser?.image = image
                browser?.asset = asset
                
                picker.present(browser!, animated:true, completion:nil)
            }
		}
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		hostViewController?.dismiss(animated: true, completion: nil)
	}
}
