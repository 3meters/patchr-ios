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


    func locationDictionary(coordinate: CLLocationCoordinate2D) -> NSDictionary
    {
        // TODO: 25 is bogus. What should this be? Maybe work with a CLLocation object to get accuracy values.
        // Q: How is geometry different from lat/lng
        return ["accuracy":25, "geometry":[coordinate.longitude, coordinate.latitude], "lat": coordinate.latitude, "lng":coordinate.longitude]
    }
    
    @IBAction func saveButton(sender: AnyObject) {

        let name = patchNameField.text
        let type = patchTypeField.text
        let privacy = privacyControl.selectedSegmentIndex == 0 ? "private" : "public"
        let patchLocation = coordinate
        let patchImage = patchImageView.image
        
        let proxibase = ProxibaseClient.sharedInstance
        
        let parameters: NSDictionary = ["name": name,
                                        "visibility": privacy,
                                        "category": proxibase.categories[type]! as AnyObject,
                                        "location": locationDictionary(patchLocation) as AnyObject,
                                        "photo": patchImage! as AnyObject
                                       ]
        
        proxibase.createObject("data/patches", parameters: parameters) { response, error in
            dispatch_async(dispatch_get_main_queue())
            {
                if let error = ServerError(error) {
                    println("Create Patch Error")
                    println(error)

                    let alert = UIAlertController(title: LocalizedString("Error"), message: error.message, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: LocalizedString("OK"), style: .Cancel, handler: { _ in }))
                    self.presentViewController(alert, animated: true) {}
                }
                else
                {
                    println("Create Patch Successful")
                    println(response)
                    if let patchID = (response?["data"] as NSDictionary?)?["_id"] as? String
                    {
                        println("Created patch id \(patchID)")
                        proxibase.createLink(fromType:.User, fromID: nil, linkType:.Create, toType:.Patch, toID: patchID) {_, _ in }
                    }

                    self.performSegueWithIdentifier("CreatePatchUnwind", sender: nil)
                }
            }
        }
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