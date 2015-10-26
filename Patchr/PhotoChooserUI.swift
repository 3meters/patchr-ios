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
	private var photoButtonFunctionMap = [Int: PhotoButtonFunction]()
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

		let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)

		let cameraAvailable       = UIImagePickerController.isSourceTypeAvailable(.Camera)
		let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)
		let photoSearchAvailable  = true

		if photoSearchAvailable {
			photoButtonFunctionMap[sheet.addButtonWithTitle("Search for photos")] = .SearchPhoto
		}
        if photoLibraryAvailable {
            photoButtonFunctionMap[sheet.addButtonWithTitle("Select a library photo")] = .ChooseLibraryPhoto
        }
		if cameraAvailable {
			photoButtonFunctionMap[sheet.addButtonWithTitle("Take a new photo")] = .TakePhoto
		}
        
        sheet.addButtonWithTitle("Cancel")
        sheet.cancelButtonIndex = sheet.numberOfButtons - 1
		sheet.showInView((hostViewController?.view)!)
	}

	private func choosePhotoFromLibrary() {
        chosenPhotoFunction = .ChooseLibraryPhoto
		let pickerController = UIImagePickerController()
        pickerController.sourceType = .PhotoLibrary
		pickerController.delegate = self
		self.hostViewController?.presentViewController(pickerController, animated: true, completion: nil)
	}

	private func takePhotoWithCamera() {
        chosenPhotoFunction = .TakePhoto
		let pickerController = UIImagePickerController()
		pickerController.sourceType = .Camera
		pickerController.delegate = self
		self.hostViewController?.presentViewController(pickerController, animated: true, completion: nil)
	}

	private func searchForPhoto() {
        chosenPhotoFunction = .SearchPhoto
        let pickerNavController = UIStoryboard(
            name: "Main",
            bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("PhotoPickerNavController") as? UINavigationController
        if let pickerController = pickerNavController?.topViewController as? PhotoPickerViewController {
            pickerController.pickerDelegate = self
            self.hostViewController?.presentViewController(pickerNavController!, animated: true, completion: nil)
        }
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

extension PhotoChooserUI: UIActionSheetDelegate {
    
	func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
		if buttonIndex != actionSheet.cancelButtonIndex {
			// There are some strange visual artifacts with the share sheet and the presented
			// view controllers. Adding a small delay seems to prevent them.
            Utils.delay(0.4) {
				switch self.photoButtonFunctionMap[buttonIndex]! {
					case .TakePhoto:
						self.takePhotoWithCamera()

					case .ChooseLibraryPhoto:
						self.choosePhotoFromLibrary()

					case .SearchPhoto:
						self.searchForPhoto()
				}
			}
		}
		else {
			self.finishedChoosing!(nil, nil, true)
		}
	}
}