//
//  NewCreateEditPatch.swift
//  Patchr
//
//  Created by Brent on 2015-03-10.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit

class PatchEditViewController: EntityEditViewController {

    // An array of the patch type IDs in the UI, indexed by row in the patch type section of the UI.
    let patchTypeIDs = ["event", "group", "place", "project"]

	var patchSwitchView: UISwitch!

	// UI outlets and views
    
	@IBOutlet weak var publicCell:       UITableViewCell!
	@IBOutlet weak var locationCell:     UITableViewCell!
    @IBOutlet weak var eventTypeCell:    UITableViewCell!
    @IBOutlet weak var groupTypeCell:    UITableViewCell!
    @IBOutlet weak var placeTypeCell:    UITableViewCell!
    @IBOutlet weak var projectTypeCell:  UITableViewCell!
    
	@IBOutlet weak var createButton:     UIButton!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collection = "patches"
        self.defaultPhotoName = "imgDefaultPatch"
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
		self.patchSwitchView = UISwitch()
		self.publicCell.accessoryView = patchSwitchView
        self.descriptionField.placeholder = "Tell people about your patch"
        self.photoView!.frame = CGRectMake(0, 0, self.photoHolder!.bounds.size.width, self.photoHolder!.bounds.size.height)
        
        if editMode {
            
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            self.cancelledLabel = "Update cancelled"
            
            navigationItem.title = Utils.LocalizedString("Edit patch")
            createButton.hidden = true
            
            /* Navigation bar buttons */
            let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
            let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [saveButton, spacer, deleteButton]            
        }
        else {
            
            self.progressStartLabel = "Patching"
            self.progressFinishLabel = "Activated!"
            self.cancelledLabel = "Activation cancelled"
            navigationItem.title = Utils.LocalizedString("Make patch")
            
            /* Use location managers last location fix */
            if let lastLocation = LocationController.instance.lastLocationFromManager() {
                updateLocation(lastLocation)
            }
            
            /* Big do it button */
            createButton.targetForAction(Selector("doneAction:"), withSender: nil)
            
            /* Public by default */
            patchSwitchView.on = true
            
            /* Navigation bar buttons */
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton]
		}
        
        bind()
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if editMode {
            setScreenName("PatchEdit")
        }
        else {
            setScreenName("PatchCreate")
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	@IBAction func unwindFromLocationEdit(segue: UIStoryboardSegue) {
		// Refresh location info when unwinding from location edit.
	}

	@IBAction func unwindFromPlacePicker(segue: UIStoryboardSegue) {
		// Refresh place link info when unwinding from place picker.
	}

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func bind() {
        super.bind()
        
        if let patch = entity as? Patch {
            
            /* Visibility */
            visibility = patch.visibility! ?? "private"
            
            /* Location */
            if let loc = patch.location {
                updateLocation(loc.locationValue)
            }
            
            /* Type */
            
            // Slight hack. Because the UI isn't displayed yet, the cells I am using to back
            // the patch type aren't loaded yet. They'll be loaded on the next turn of the runloop
            // so do this later.
            if patch.type != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.type = (patch.type)!
                }
            }
        }        
    }
    
    override func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        let parameters = super.gather(parameters)
        
        if editMode {
            if visibility != entity!.visibility {
                parameters["visibility"] = nilToNull(visibility)
            }
            if type != entity!.type {
                parameters["type"] = nilToNull(type)
            }
            if location != nil && entity!.location != nil {
                if location!.coordinate != entity!.location.locationValue.coordinate {
                    parameters["location"] = nilToNull(location)
                }
            }
        }
        else {
            parameters["visibility"] = nilToNull(visibility)   // required
            parameters["type"] = nilToNull(type)               // required
            parameters["location"] = nilToNull(location!)
        }
        return parameters
    }
    
	override func isDirty() -> Bool {
        
		if editMode {
            let patch = entity as! Patch
            
            if patch.type != type {
                return true
            }
            if patch.visibility != visibility {
                return true
            }
            if patch.location.locationValue.coordinate != location!.coordinate  {
                return true
            }
            return super.isDirty()
		}
		else {
            return super.isDirty()
		}
	}

	override func isValid() -> Bool {
        
        if nameField.isEmpty {
            Alert("Enter a name for the patch.", message: nil, cancelButtonTitle: "OK")
            return false
        }
        
		if type == nil {
			Alert("Select a patch type.", message: nil, cancelButtonTitle: "OK")
			return false
		}

        return true
    }

    func updateLocation(loc: CLLocation) {
        /* Gets calls externally from map view */
        location = loc
        CLGeocoder().reverseGeocodeLocation(loc) {  // Requires network
            placemarks, error in
            
            if let error = ServerError(error) {
                self.handleError(error)
            }
            else if placemarks != nil && placemarks!.count > 0 {
                let placemark = placemarks!.first
                self.locationCell.detailTextLabel?.text = placemark!.name
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Helpers
    *--------------------------------------------------------------------------------------------*/
    
    override func endFieldEditing() {
        /* Find and resign the first responder */
        for field in [nameField, descriptionField] {
            if field.isFirstResponder() {
                field.endEditing(false)
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Field wrappers
     *--------------------------------------------------------------------------------------------*/
    
    var visibility: String {
        get {
            return patchSwitchView.on ? "public" : "private"
        }
        set {
            patchSwitchView.on = (newValue == "public")
        }
    }
    
    private var location: CLLocation?
    
    var type: String? {
        get {
            if eventTypeCell.accessoryType == .Checkmark {
                return "event"
            }
            else if groupTypeCell.accessoryType == .Checkmark {
                return "group"
            }
            else if placeTypeCell.accessoryType == .Checkmark {
                return "place"
            }
            else if projectTypeCell.accessoryType == .Checkmark {
                return "project"
            }
            return nil
        }
        set {
            eventTypeCell.accessoryType = newValue == "event" ? .Checkmark : .None
            groupTypeCell.accessoryType = newValue == "group" ? .Checkmark : .None
            placeTypeCell.accessoryType = newValue == "place" ? .Checkmark : .None
            projectTypeCell.accessoryType = newValue == "project" ? .Checkmark : .None
        }
    }
}

extension PatchEditViewController: MapViewDelegate {
    
    func locationForMap() -> CLLocation? {
        return self.location
    }
    
    func locationChangedTo(location: CLLocation) -> Void {
        self.location = location
        updateLocation(location)
    }
    
    func locationEditable() -> Bool {
        return true
    }
    
    var locationTitle: String? {
        get {
            return self.name
        }
    }
    
    var locationSubtitle: String? {
        get {
            if let type = self.type {
                return type.uppercaseString + " PATCH"
            }
            return nil
        }
    }
    
    var locationPhoto: AnyObject? {
        get {
            return self.photo
        }
    }    
}

extension PatchEditViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                let height: CGFloat = textViewHeightForRowAtIndexPath(indexPath)
                return height < 48 ? 48 : height
            }
            else if indexPath.row == 2 {
                /* Size so photo aspect ratio is 16:10 */
                let height: CGFloat = ((UIScreen.mainScreen().bounds.size.width - 36) * 0.625) + 24
                return height
            }
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        let index = (indexPath.section, indexPath.row)
        
        switch index {
            case (0, 1):
                return indexPath
            case (0, 4):
                return indexPath
            case (0, 5):
                return indexPath
            case (1, _):
                return indexPath
            default:
                super.endFieldEditing()
                return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let index = (indexPath.section, indexPath.row)
        
        switch index {
            case (0, 4):
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchMapViewController") as? PatchMapViewController {
                    controller.locationDelegate = self
                    self.navigationController?.pushViewController(controller, animated: true)
                }

            case (0, 5):
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                Alert("Will launch place picker when implemented")
            
            case (1, let row):
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                type = patchTypeIDs[row].lowercaseString
            
            default: break
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UILabel(frame: CGRect(x: 10, y: 0, width: 100, height: 20))
        
        if section == 1 {
            
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16.0
            
            let attributes = [
                NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline),
                NSUnderlineStyleAttributeName : 1,
                NSParagraphStyleAttributeName : style,
                NSForegroundColorAttributeName : UIColor(white: 0.50, alpha: 1.0),
                NSBaselineOffsetAttributeName : -4.0]
            
            view.attributedText = NSMutableAttributedString(string: "PATCH TYPE", attributes: attributes)
        }
        
        view.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        return view
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            case 1: return 40
            default: return 0
        }
    }

    private func textViewHeightForRowAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
        let textViewWidth: CGFloat = descriptionField!.frame.size.width
        let size: CGSize = descriptionField.sizeThatFits(CGSizeMake(textViewWidth, CGFloat(FLT_MAX)))
        return size.height + 24;
    }
}