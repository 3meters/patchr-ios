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

class PhotoChooserUI: NSObject,
                      UIActionSheetDelegate,
                      UIImagePickerControllerDelegate, UINavigationControllerDelegate // both needed for UIImagePicker
{
    private var hostViewController: UIViewController
    private var finishedChoosing: ((UIImage) -> Void)? = nil
    
    init(hostViewController: UIViewController)
    {
        self.hostViewController = hostViewController

        super.init()
    }
    
    // MARK: Photo UI
    
    private lazy var imagePickerController: UIImagePickerController = {
        return UIImagePickerController(rootViewController: self.hostViewController)
    }()
    
    private enum PhotoButtonFunction {
        case UseLatestPhoto
        case TakePhoto
        case ChoosePhoto
        case SearchPhoto
    }
    
    // Map from button indices to functions because some buttons aren't there all the time (for example, the camera
    // is not available on the simulator).
    //
    private var photoButtonFunctionMap = [Int:PhotoButtonFunction]()
    
    // choosePhoto
    //
    // Calling choosePhoto starts the process of choosing an image, and calls the finishedChoosing block
    // when an image has been selected.
    //
    func choosePhoto(finishedChoosing: (UIImage) -> Void) {
    
        self.finishedChoosing = finishedChoosing
        
        let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
        
        let cameraRollAvailable = UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum)
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.Camera)
        let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)
        let photoSearchAvailable = false // because not implemented yet
        
        if cameraRollAvailable
        {
            photoButtonFunctionMap[sheet.addButtonWithTitle(LocalizedString("Use Latest Photo"))] = .UseLatestPhoto
        }
        if cameraAvailable
        {
            photoButtonFunctionMap[sheet.addButtonWithTitle(LocalizedString("Take Photo"))] = .TakePhoto
        }
        if cameraRollAvailable
        {
            photoButtonFunctionMap[sheet.addButtonWithTitle(LocalizedString("Choose From Library"))] = .ChoosePhoto
        }
        if photoSearchAvailable
        {
            photoButtonFunctionMap[sheet.addButtonWithTitle(LocalizedString("Photo Search"))] = .SearchPhoto
        }
        
        sheet.showInView(hostViewController.view)
    }
    
    private func choosePhotoFromLibrary()
    {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        self.hostViewController.presentViewController(pickerController, animated: true, completion: nil)
    }

    private func takePhotoWithCamera()
    {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .Camera
        pickerController.delegate = self
        self.hostViewController.presentViewController(pickerController, animated: true, completion: nil)
    }

    private func searchForPhoto()
    {
        // TODO: searchForPhoto() unimplemented
    }
    
    private func useLatestPhoto()
    {
        let assetsLibrary = ALAssetsLibrary()
        var assetsGroup: ALAssetsGroup?
        var latestAsset: ALAsset?
        
        // This enumeration runs asynchronously, so this is a little weird.
        // At this point we assume that there's only one "Saved Photos" group, and that the photo we want is the last one
        // in the group. 
        
        assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos, usingBlock: { (group, stop) -> Void in
        
            if assetsGroup == nil {
                assetsGroup = group
                assetsGroup?.setAssetsFilter(ALAssetsFilter.allPhotos())
                assetsGroup?.enumerateAssetsUsingBlock({ (asset, index, stop) -> Void in
                    if asset != nil {
                        latestAsset = asset
                    } else {
                        // TODO: What if there are no photos at all?
                        
                        // asset is nil, so we're at the end of the group, which we assume means we've got the last photo.
                        let assetCGImage = latestAsset?.defaultRepresentation().fullScreenImage()
                        if let uiImage = UIImage(CGImage: assetCGImage?.takeUnretainedValue()) {
    /*!!!*/                 self.finishedChoosing!(uiImage)
                        }
                        // TODO: Taking an unretained value so I'm not sure it's safe. Need to think about this.
                    }
                })
                stop.memory = true // Is this working? We get a nil callback anyway.
            }
            
        }) { (error) -> Void in
            println("error: \(error)");
        }
        
    }
    
    // MARK: UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int)
    {
        if buttonIndex != actionSheet.cancelButtonIndex
        {
            switch photoButtonFunctionMap[buttonIndex]! {

            case .UseLatestPhoto:
                useLatestPhoto()
                
            case .TakePhoto:
                takePhotoWithCamera()
                
            case .ChoosePhoto:
                choosePhotoFromLibrary()
                
            case .SearchPhoto:
                searchForPhoto()
            }
        }
    }

    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject])
    {
        hostViewController.dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.finishedChoosing!(image)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        hostViewController.dismissViewControllerAnimated(true, completion: nil)
    }
 
}