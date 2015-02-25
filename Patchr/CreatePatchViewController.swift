//
//  CreatePatchViewController.swift
//  Patchr
//
//  Created by Brent on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//


// TODO: There's a huge memory hit when you bring up this view controller

import Foundation
import AssetsLibrary
import MapKit

func LocalizedString(str: String, comment:String) -> String
{
    return NSLocalizedString(str, comment: comment)
}

func LocalizedString(str: String) -> String
{
    return LocalizedString("[]"+str, str)
}

// Utility to show some information about subview frames.

func showSubviews(view: UIView, level: Int = 0)
{
    var indent = ""
    for i in 0..<level {
        indent += "  "
    }
    var count = 0
    for subview in view.subviews {
        println("\(indent)\(count++). \(subview.frame)")
        showSubviews(subview as UIView, level: level + 1)
    }
}

class CreatePatchViewController: UIViewController,
    MKAnnotation, // lets us provide annotation information for map view
    MKMapViewDelegate,
    UIActionSheetDelegate, // for the action sheet used to choose an image source
    UIImagePickerControllerDelegate, UINavigationControllerDelegate, // both needed for UIImagePicker
    UITextFieldDelegate // For text field details
{

    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var patchTypeField: UITextField!
    @IBOutlet weak var patchNameField: UITextField!
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var patchImageTintView: UIImageView!
    @IBOutlet weak var privacyControl: UISegmentedControl!
    @IBOutlet weak var patchLocationMap: MKMapView!


    // MARK: UITextFieldDelegate
    
    // End editing on the fields when the "Done" key is pressed so the keyboard will hide

    func textFieldShouldReturn(textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        textField.endEditing(false)
        return false
    }
    
    // A stopgap for empty patch name/types
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text == "" {
            if textField == patchTypeField
            {
                textField.text = LocalizedString("Unknown Type")
            }
            else if textField == patchNameField
            {
                textField.text = LocalizedString("Untitled Patch")
            }
        }
    }


    override func viewWillAppear(animated: Bool)
    {
        // Get the map showing the region around the user
        
        var currentRegion = MKCoordinateRegionMakeWithDistance(self.coordinate, 2000, 2000)
        patchLocationMap.setRegion(currentRegion, animated: false)
        patchLocationMap.addAnnotation(self)
    }
    
    
    @IBAction func saveButton(sender: AnyObject) {

        let name = patchNameField.text
        let type = patchTypeField.text
        let privacy = privacyControl.selectedSegmentIndex
        let patchLocation = coordinate
        let patchImage = patchImageView.image
        
        println("SAVE PATCH")
        println("name:    \(name)")
        println("type:    \(type)")
        println("privacy: \(privacy)")
        println("location: \(patchLocation.latitude), \(patchLocation.longitude)")
        println("image:    \(patchImage)")
        
        // TODO: Actually do the save here

        self.performSegueWithIdentifier("CreatePatchUnwind", sender: nil)
    }
    
    
    // MARK: Mapping

    // A long press on the map will move the pin to the tapped location
    
    @IBAction func longPress(gr: UILongPressGestureRecognizer) {
    
        patchLocationMap.removeAnnotation(self)
        self.coordinate = patchLocationMap.convertPoint(gr.locationInView(patchLocationMap), toCoordinateFromView: patchLocationMap)
        patchLocationMap.addAnnotation(self)
    }
    
    
    // MARK: MKAnnotation
    
    lazy var coordinate: CLLocationCoordinate2D = {
        // Note: I have had this crash on me in the simulator (CLLocationManager().location returns nil), but
        // that seems like a bug because changing the location in the debug menu fixed it.
        // ...and now I saw it crash on the Phone too. So I'm going to see what happens with a default CLLocation
        let locationManager = CLLocationManager()
                let location = CLLocationManager().location
        return location != nil ? location.coordinate : CLLocation().coordinate

    }()
    
    // MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
    {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.animatesDrop = true
        return annotationView
    }
    
    // MARK: Photo UI
    
    lazy var imagePickerController: UIImagePickerController = {
        return UIImagePickerController(rootViewController: self)
    }()
    
    enum PhotoButtonFunction {
        case UseLatestPhoto
        case TakePhoto
        case ChoosePhoto
        case SearchPhoto
    }
    
    // Map from button indices to functions because some buttons aren't there all the time (for example, the camera
    // is not available on the simulator).
    //
    var photoButtonFunctionMap = [Int:PhotoButtonFunction]()
    
    @IBAction func photoButtonTapped(sender: AnyObject) {
    
        let sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
        
        let cameraRollAvailable = UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum)
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.Camera)
        let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)
                
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
        
        photoButtonFunctionMap[sheet.addButtonWithTitle(LocalizedString("Photo Search"))] = .SearchPhoto
        
        sheet.showInView(self.view)
    }
    
    func choosePhotoFromLibrary()
    {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        self.presentViewController(pickerController, animated: true, completion: nil)
    }

    func takePhotoWithCamera()
    {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .Camera
        pickerController.delegate = self
        self.presentViewController(pickerController, animated: true, completion: nil)
    }

    func searchForPhoto()
    {
    }
    
    func useLatestPhoto()
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
/*!!!*/                 self.patchImageView.image = UIImage(CGImage: assetCGImage?.takeUnretainedValue())
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
        self.dismissViewControllerAnimated(true, completion: nil)
        
        patchImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

}