//
//  CreatePatchViewController.swift
//  Patchr
//
//  Created by Brent on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit


class CreatePatchViewController: UIViewController,
                                 MKAnnotation, // lets us provide annotation information for map view
                                 MKMapViewDelegate,
                                 UITextFieldDelegate // For text field details
{
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var patchTypeField: UITextField!
    @IBOutlet weak var patchNameField: UITextField!
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var patchImageTintView: UIImageView!
    @IBOutlet weak var privacyControl: UISegmentedControl!
    @IBOutlet weak var patchLocationMap: MKMapView!

    lazy var photoChooserUI: PhotoChooserUI = { return PhotoChooserUI(hostViewController:self) }()

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

    @IBAction func photoButtonTapped(sender: AnyObject) {
    
        photoChooserUI.choosePhoto() { uiImage in
            self.patchImageView.image = uiImage
        }
    }

}