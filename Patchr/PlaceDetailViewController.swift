//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PlaceDetailViewController: UITableViewController {
    
    var place:      Place?
    var placeId:    String?
    var progress:   AirProgress?

    /* Outlets are initialized before viewDidLoad is called */
    
    @IBOutlet weak var photo: AirImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		if self.place != nil {
			self.placeId = self.place!.id_
		}
        
		super.viewDidLoad()
        
        self.name.text = nil
        self.category.text = nil
        self.address.text = nil
        self.distance.text = nil
        
        /* Wacky activity control for body */
        self.progress = AirProgress(view: self.view)
        self.progress!.mode = MBProgressHUDMode.Indeterminate
        self.progress!.styleAs(.ActivityOnly)
        self.progress!.userInteractionEnabled = false
        self.view.addSubview(self.progress!)
        
        /* Use cached entity if available in the data model */
        if self.placeId != nil {
            if let place: Place? = Place.fetchOneById(self.placeId!, inManagedObjectContext: DataController.instance.managedObjectContext) {
                self.place = place
            }
        }
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        setScreenName("PlaceDetail")
        
        if self.place != nil {
            draw()
        }        
	}
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.address.preferredMaxLayoutWidth = self.address.frame.size.width
        self.view.layoutIfNeeded()
    }

    override func viewDidAppear(animated: Bool){
		super.viewDidAppear(animated)
		refresh(force: true)
	}

	private func refresh(force: Bool = false) {
        
        if (self.place == nil) {
            self.progress?.minShowTime = 1
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)
        }

		DataController.instance.withPlaceId(placeId!, refresh: force) {
			place, error in
			self.refreshControl?.endRefreshing()
            self.progress?.hide(true)
            
            if error == nil {
                if place != nil {
                    self.place = place
                    self.draw()
                }
                else {
                    Shared.Toast("Place has been deleted")
                    Utils.delay(2.0, closure: {
                        () -> () in
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                }
            }
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func draw() {
        
        self.photo.setImageWithPhoto(place!.getPhotoManaged(), animate: photo.image == nil)
        
        if self.place!.name != nil {
            self.name.text = self.place!.name
        }
        
        if self.place!.type != nil {
            self.category.text = self.place!.type.uppercaseString
        }
        
        var addressString: String = ""
        if self.place!.address != nil {
            addressString = self.place!.addressBlock()
        }
        
        if self.place!.phone != nil {
            var phoneUtil = NBPhoneNumberUtil.sharedInstance()
            var errorPointer: NSError?
            var number: NBPhoneNumber = phoneUtil.parse(self.place!.phone, defaultRegion:"US", error:&errorPointer)
            addressString = addressString + "\n" + phoneUtil.format(number, numberFormat: NBEPhoneNumberFormatNATIONAL, error: &errorPointer)
        }
        
        self.address.text = addressString
        
        /* Distance */
        self.distance.text = "--"
        if let lastLocation = LocationController.instance.lastLocationFromManager() {
            if let loc = self.place!.location {
                var placeLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
                let dist = Float(lastLocation.distanceFromLocation(placeLocation))  // in meters
                self.distance.text = LocationController.instance.distancePretty(dist)
            }
        }
        
        self.tableView.reloadData()
	}    
}

extension PlaceDetailViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var height = super.tableView(tableView, heightForRowAtIndexPath: indexPath) as CGFloat!
        if indexPath.row == 0 {
            /* Size so photo aspect ratio is 16:10 */
            height = UIScreen.mainScreen().bounds.size.width * 0.625
        }
        return height
    }
}