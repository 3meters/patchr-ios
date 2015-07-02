//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PlaceDetailViewController: UITableViewController {
    
    var place:      Place!
    var placeId:    String?
    var progress: MBProgressHUD?

    /* Outlets are initialized before viewDidLoad is called */
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		if place != nil {
			placeId = place.id_
		}
		super.viewDidLoad()
        
        name.text = nil
        category.text = nil
        address.text = nil
        distance.text = nil
        
        /* Wacky activity control for body */
        progress = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().delegate?.window!, animated: true)
        progress!.mode = MBProgressHUDMode.Indeterminate
        progress!.square = true
        progress!.opacity = 0.0
        progress!.removeFromSuperViewOnHide = true
        progress!.userInteractionEnabled = false
        progress!.activityIndicatorColor = Colors.brandColorDark
        progress!.show(true)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
        if self.place != nil {
            draw()
        }
	}
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        address.preferredMaxLayoutWidth = address.frame.size.width
        self.view.layoutIfNeeded()
    }

    override func viewDidAppear(animated: Bool){
		super.viewDidAppear(animated)
		refresh(force: true)
	}

	private func refresh(force: Bool = false) {
		DataController.instance.withPlaceId(placeId!, refresh: force) {
			place in
			self.refreshControl?.endRefreshing()
            self.progress!.hide(true)
			if place != nil {
				self.place = place
				self.draw()
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

	func draw() {
        
        self.photo.setImageWithPhoto(place!.getPhotoManaged(), animate: photo.image == nil)
        
        if place!.name != nil {
            name.text = place!.name
        }
        
        if place!.type != nil {
            category.text = place!.type.uppercaseString
        }
        
        var addressString: String = ""
        if place!.address != nil {
            addressString = place!.addressBlock()
        }
        
        if place!.phone != nil {
            var phoneUtil = NBPhoneNumberUtil.sharedInstance()
            var errorPointer: NSError?
            var number: NBPhoneNumber = phoneUtil.parse(place!.phone, defaultRegion:"US", error:&errorPointer)
            addressString = addressString + "\n" + phoneUtil.format(number, numberFormat: NBEPhoneNumberFormatNATIONAL, error: &errorPointer)
        }
        
        address.text = addressString
        
        /* Distance */
        distance.text = "--"
        if let currentLocation = LocationController.instance.getLocation() {
            if let loc = place!.location {
                var placeLocation = CLLocation(latitude: loc.latValue, longitude: loc.lngValue)
                let dist = Float(currentLocation.distanceFromLocation(placeLocation))  // in meters
                distance.text = LocationController.instance.distancePretty(dist)
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