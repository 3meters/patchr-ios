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
    typealias CompletionHandler = (success:Bool) -> Void
    
    private weak var hostViewController: UIViewController?
	private var finishedChoosing: ((UIImage?, ImageResult?, Bool) -> Void)? = nil
    private var library: ALAssetsLibrary?
    private var chosenPhotoFunction: PhotoButtonFunction?

	private lazy var imagePickerController: UIImagePickerController = {
		return UIImagePickerController(rootViewController: self.hostViewController!)
	}()

	init(hostViewController: UIViewController) {
		self.hostViewController = hostViewController
        library = ALAssetsLibrary()
		super.init()
	}

	func choosePhoto(finishedChoosing: (UIImage?, ImageResult?, Bool) -> Void) {

		self.finishedChoosing = finishedChoosing
		let cameraAvailable       = UIImagePickerController.isSourceTypeAvailable(.Camera)
		let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)
		
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
		
		let search = UIAlertAction(title: "Search for photos", style: .Default) { action in
			self.searchForPhoto()
		}
		sheet.addAction(search)
		
		if photoLibraryAvailable {
			let library = UIAlertAction(title: "Select a library photo", style: .Default) { action in
				self.choosePhotoFromLibrary()
			}
			sheet.addAction(library)
		}
		
		if cameraAvailable {
			let camera = UIAlertAction(title: "Take a new photo", style: .Default) { action in
				self.takePhotoWithCamera()
			}
			sheet.addAction(camera)
		}
		
		let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { action in
			sheet.dismissViewControllerAnimated(true, completion: nil)
			self.finishedChoosing!(nil, nil, true)
		}
		
		sheet.addAction(cancel)
		
		hostViewController?.presentViewController(sheet, animated: true, completion: nil)
	}

	private func choosePhotoFromLibrary() {
        chosenPhotoFunction = .ChooseLibraryPhoto
		let pickerController = UIImagePickerController()
        pickerController.sourceType = .PhotoLibrary
		pickerController.delegate = self
		pickerController.mediaTypes = [kUTTypeImage as String]
		self.hostViewController?.presentViewController(pickerController, animated: true, completion: nil)
	}

	private func takePhotoWithCamera() {
        chosenPhotoFunction = .TakePhoto
		let pickerController = UIImagePickerController()
		pickerController.sourceType = .Camera
		pickerController.delegate = self
		pickerController.mediaTypes = [kUTTypeImage as String]
		self.hostViewController?.presentViewController(pickerController, animated: true, completion: nil)
	}

	private func searchForPhoto() {
        chosenPhotoFunction = .SearchPhoto
		let navController = UINavigationController()
		let layout = UICollectionViewFlowLayout()
		let controller = PhotoPickerViewController(collectionViewLayout: layout)
		controller.pickerDelegate = self
		navController.viewControllers = [controller]
		self.hostViewController?.presentViewController(navController, animated: true, completion: nil)
	}

	private func addPhotoToAlbum(image: UIImage, toAlbum albumName: String, handler: CompletionHandler) {

        let orientation : ALAssetOrientation = ALAssetOrientation(rawValue:image.imageOrientation.rawValue)!
        
		self.library?.addAssetsGroupAlbumWithName(albumName, resultBlock: {
			(group: ALAssetsGroup!) -> Void in
            
			/*-- Find Group --*/
			var groupToAddTo: ALAssetsGroup?;
            
            self.library?.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
                usingBlock: {
                    (group: ALAssetsGroup?, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                    
                    if (group != nil) {
                        if group!.valueForProperty(ALAssetsGroupPropertyName) as! String == albumName {
                            groupToAddTo = group;
                            
                            self.library?.writeImageToSavedPhotosAlbum(image.CGImage,
                                orientation: orientation,
                                completionBlock: { (assetURL: NSURL!, error: NSError!) -> Void in
                                
                                if (error == nil) {
                                    self.library?.assetForURL(assetURL,
                                        resultBlock: {
                                            (asset: ALAsset!) -> Void in
                                            let yes: Bool? = groupToAddTo?.addAsset(asset);
                                            if (yes == true) {
                                                handler(success: true);
                                            }
                                        },
                                        failureBlock: {
                                            (error2: NSError!) -> Void in
                                            print("Failed to add asset");
                                            handler(success: false);
                                    });
                                }
                            });
                        }
                    } /*Group Is Not nil*/
                },
                failureBlock: {
                    (error: NSError!) -> Void in
                    print("Failed to find group");
                    handler(success: false);
            });
            
            }, failureBlock: {
                (error: NSError!) -> Void in
                print("Failed to create \(error)");
                handler(success: false);
        });
	}

	private enum PhotoButtonFunction {
		case TakePhoto
		case ChooseLibraryPhoto
		case SearchPhoto
	}
}

@objc protocol PhotoBrowseControllerDelegate {
    optional func photoBrowseController(didFinishPickingPhoto imageResult: ImageResult) -> Void
    optional func photoBrowseController(didLikePhoto liked: Bool) -> Void
    optional func photoBrowseControllerDidCancel() -> Void
}

extension PhotoChooserUI: PhotoBrowseControllerDelegate {
    
    func photoBrowseController(didFinishPickingPhoto imageResult: ImageResult) -> Void {
        hostViewController?.dismissViewControllerAnimated(true, completion: nil)
        self.finishedChoosing!(nil, imageResult, false)
    }
    
    func photoBrowseController(didLikePhoto liked: Bool) { }
    
    func photoBrowseControllerDidCancel() {
        hostViewController?.dismissViewControllerAnimated(true, completion: nil)
		self.finishedChoosing!(nil, nil, true)
    }
}

extension PhotoChooserUI: UIImagePickerControllerDelegate {
    
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:AnyObject]) {
        
		hostViewController?.dismissViewControllerAnimated(true, completion: nil)
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
			/* If the user took a photo then add it to the patchr photo album */
            if self.chosenPhotoFunction == .TakePhoto {
                self.addPhotoToAlbum(image, toAlbum: "Patchr") {
                    (success) -> Void in
                    print("Image added to Patchr album: \(success)");
                    self.finishedChoosing!(image, nil, false)
                }
            }
            else {
                self.finishedChoosing!(image, nil, false)
            }
		}
	}

	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		hostViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
}