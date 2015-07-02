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
    @IBOutlet weak var linkedPlaceCell:  UITableViewCell!
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
        
        if editMode {
            
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated!"
            navigationItem.title = LocalizedString("Edit patch")
            createButton.hidden = true
            
            /* Navigation bar buttons */
            var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
            var saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [saveButton, spacer, deleteButton]
            
        }
        else {
            
            self.progressStartLabel = "Patching"
            self.progressFinishLabel = "Activated!"
            navigationItem.title = LocalizedString("Make patch")
            
            /* Use current location */
            if let loc = LocationController.instance.getLocation() {
                updateLocation(loc)
            }
            
            /* Big do it button */
            createButton.targetForAction(Selector("doneAction:"), withSender: nil)
            
            /* Public by default */
            patchSwitchView.on = true
            
            /* Navigation bar buttons */
            var saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [saveButton]
		}
        
        bind()
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
        
        var parameters = super.gather(parameters)
        
        if editMode {
            if visibility != entity!.visibility {
                parameters["visibility"] = nilToNull(visibility)
            }
            if type != entity!.type {
                parameters["type"] = nilToNull(type)
            }
            if location!.coordinate != entity!.location.locationValue.coordinate {
                parameters["location"] = nilToNull(location)
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
            case "LocationEditSegue":
                if let destinationViewController = segue.destinationViewController as? PatchMapViewController {
                    destinationViewController.locationProvider = self
                }
            default: ()
        }
    }

    func updateLocation(loc: CLLocation) {
        /* Gets calls externally from map view */
        location = loc
        CLGeocoder().reverseGeocodeLocation(loc) {  // Requires network
            placemarks, error in
            
            if let error = ServerError(error) {
                self.handleError(error)
            }
            else {
                if placemarks.count > 0 {
                    let pm = placemarks[0] as! CLPlacemark
                    self.locationCell.detailTextLabel?.text = pm.name
                    return
                }
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
    
    var location: CLLocation?
    
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

extension PatchEditViewController: UITableViewDelegate{
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                var height: CGFloat = textViewHeightForRowAtIndexPath(indexPath)
                return height < 48 ? 48 : height
            }
            else if indexPath.row == 2 {
                /* Size so photo aspect ratio is 16:10 */
                var height: CGFloat = ((UIScreen.mainScreen().bounds.size.width - 36) * 0.625) + 24
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
            case (1, let row):
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
                performSegueWithIdentifier("LocationEditSegue", sender: self)
            
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
            
            let attributes = NSMutableDictionary()
            attributes.setValue(style, forKey: NSParagraphStyleAttributeName)
            attributes.setValue(UIColor(white: 0.50, alpha: 1.0), forKey: NSForegroundColorAttributeName)
            attributes.setValue(-4.0, forKey: NSBaselineOffsetAttributeName)
            
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            attributes.setValue(font, forKey: NSFontAttributeName)
            
            view.attributedText = NSMutableAttributedString(string: "PATCH TYPE", attributes: attributes as [NSObject:AnyObject])
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
        return size.height + 48;
    }
}