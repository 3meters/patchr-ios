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
	fileprivate var finishedChoosing: ((UIImage?, ImageResult?, Bool) -> Void)? = nil
    fileprivate var library: ALAssetsLibrary?
    fileprivate var chosenPhotoFunction: PhotoButtonFunction?

	fileprivate lazy var imagePickerController: UIImagePickerController = {
		return UIImagePickerController(rootViewController: self.hostViewController!)
	}()

	init(hostViewController: UIViewController) {
		self.hostViewController = hostViewController
        library = ALAssetsLibrary()
		super.init()
	}

	func choosePhoto(sender: AnyObject, finishedChoosing: @escaping (UIImage?, ImageResult?, Bool) -> Void) {
		
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
			self.finishedChoosing!(nil, nil, true)
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
		self.hostViewController?.present(pickerController, animated: true, completion: nil)
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
            guard asset != nil else {
                assert(false, "Image asset is nil")
            }
            handler(true)
        }
	}

	private enum PhotoButtonFunction {
		case TakePhoto
		case ChooseLibraryPhoto
		case SearchPhoto
	}
}

@objc protocol PhotoBrowseControllerDelegate {
    @objc optional func photoBrowseController(didFinishPickingPhoto imageResult: ImageResult) -> Void
    @objc optional func photoBrowseController(didLikePhoto liked: Bool) -> Void
    @objc optional func photoBrowseControllerDidCancel() -> Void
}

extension PhotoChooserUI: PhotoBrowseControllerDelegate {
    
    func photoBrowseController(didFinishPickingPhoto imageResult: ImageResult) -> Void {
        hostViewController?.dismiss(animated: true, completion: nil)
        self.finishedChoosing!(nil, imageResult, false)
    }
    
    func photoBrowseController(didLikePhoto liked: Bool) { }
    
    func photoBrowseControllerDidCancel() {
        hostViewController?.dismiss(animated: true, completion: nil)
		self.finishedChoosing!(nil, nil, true)
    }
}

extension PhotoChooserUI: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
		hostViewController?.dismiss(animated: true, completion: nil)
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
			/* If the user took a photo then add it to the patchr photo album */
            if self.chosenPhotoFunction == .TakePhoto {
                self.addPhotoToAlbum(image: image, toAlbum: "Patchr") { success in
                    print("Image added to Patchr album: \(success)");
                    self.finishedChoosing!(image, nil, false)
                }
            }
            else {
                self.finishedChoosing!(image, nil, false)
            }
		}
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		hostViewController?.dismiss(animated: true, completion: nil)
	}
}
