//
//  NewCreateEditPatch.swift
//  Patchr
//
//  Created by Brent on 2015-03-10.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import MapKit

class CreateEditPatchViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate
{
    private let NameSection = 0
    private let BannerSection = 1
    private let InfoSection = 2
        private let PrivacyRow = 0
        private let LocationRow = 1
    private let TypeSection = 3
        private let DefaultTypeRow = 2 // "Place"
    private let ButtonSection = 4
        private let CreateButtonRow = 0
        private let DeleteButtonRow = 1 // in initial table view. Won't necessarily be at this index after viewDidLoad
    
    // Configured by previous scene
    
    var patch: Patch?
    
    // UI outlets and views
    
    @IBOutlet weak var patchNameField: UITextField!
    @IBOutlet weak var patchDescriptionField: UITextField!
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var publicPatchCell: UITableViewCell!
    @IBOutlet weak var patchLocationCell: UITableViewCell!
    @IBOutlet weak var customButtonCell: UITableViewCell!
    @IBOutlet weak var customButton: UIButton!

    @IBOutlet weak var saveButton: UIBarButtonItem!

    
    var patchSwitchView: UISwitch!
    
    // Photo Chooser helper
    lazy var photoChooser: PhotoChooserUI = PhotoChooserUI(hostViewController: self)
    
    // Patch Properties
    
    var patchName:String  { get { return patchNameField.text ?? "" }
                            set { patchNameField.text = newValue }}
    
    var patchDescription:String  { get { return patchDescriptionField.text ?? "" }
                                   set { patchDescriptionField.text = newValue }}
    
    var patchImage: UIImage { get { return patchImageView.image ?? UIImage(named: "Placeholder patch header")! }
                              set { patchImageView.image = newValue }}
    
    var patchPrivacy: String { get { return patchSwitchView.on ? "public" : "private" }
                               set { patchSwitchView.on = (newValue == "public") }}
    
    var patchLocation: CLLocation?
    
    // An array of the patch type IDs in the UI, indexed by row in the patch type section of the UI.
    let patchTypeIDs = ["event", "group", "place", "project"]
    
    // The patch 'category' id of the currently selected patch type. This value is stored in the UI as the
    // index in the type section of the table of the item with a checkmark.
    // Setting this value to an invalid category id will set it to the default value.
    var patchType: String {
        get {
            
            for row in 0..<patchTypeIDs.count {
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: TypeSection))
                if let theCell = cell {
                    if theCell.accessoryType == .Checkmark
                    {
                        return patchTypeIDs[row]
                    }
                }
            }
            assert(false, "No selected patch type")
            return patchTypeIDs[DefaultTypeRow]
        }
        set {
            var wasSet = false
            var defaultCell: UITableViewCell!
            
            for row in 0..<patchTypeIDs.count {
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: TypeSection))
                cell?.accessoryType = (patchTypeIDs[row] == newValue) ? .Checkmark : .None
                wasSet = wasSet || (patchTypeIDs[row] == newValue)
                if row == DefaultTypeRow {
                    defaultCell = cell
                }
            }
            if !wasSet
            {
                defaultCell.accessoryType = .Checkmark
            }
        }
    }


    private var isEditingPatch: Bool { return patch != nil }
    
    // When view loads, configure for create or edit.
    //
    override func viewDidLoad()
    {
        patchSwitchView = UISwitch()
        publicPatchCell.accessoryView = patchSwitchView
        
        if isEditingPatch
        {
            patchName = patch?.name ?? LocalizedString("Unknown Patch")
            patchDescription = patch?.description_ ?? ""
            patchImageView.setImageWithURL(patch?.photo.photoURL())
            patchPrivacy = patch?.privacy! ?? "private"
            patchLocation = patch?.location.locationValue
            patchType = (patch?.category.id_)!
            customButton.setTitle("Delete Patch", forState: .Normal)
            customButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        }
        else
        {
            let locationManager = AppDelegate.appDelegate().locationManager
            patchLocation = locationManager.location

            assert(navigationItem.rightBarButtonItem == saveButton)
            navigationItem.rightBarButtonItem = nil
            customButton.setTitle("Create Patch", forState: .Normal)
        
            patchSwitchView.on = true
        }
    }

    var observerObject: TextFieldChangeObserver?
    
    override func viewWillAppear(animated: Bool) {
        observerObject = TextFieldChangeObserver(patchNameField) { [unowned self] in
            self.updateCreatePatchButton()
        }
        updateCreatePatchButton()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        observerObject?.stopObserving()
    }
    
    func ActionConfirmationAlert(title: String, message: String, actionTitle: String, cancelTitle: String, onDismiss: (Bool) -> Void)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        alert.addAction(UIAlertAction(title: actionTitle, style: .Destructive, handler: { _ in onDismiss(true) }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .Cancel, handler: { _ in onDismiss(false) }))
        self.presentViewController(alert, animated: true) {}
    }

    func ErrorNotificationAlert(title: String, message: String, onDismiss: () -> Void)
    {
        let alert = UIAlertController(title: LocalizedString("Error"), message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: LocalizedString("OK"), style: .Cancel, handler: { _ in }))
        self.presentViewController(alert, animated: true) {}
    }

    @IBAction func changeBannerButtonAction(sender: AnyObject)
    {
        endFieldEditing()

        photoChooser.choosePhoto() { [unowned self] image in
            
            self.patchImageView.image = image
        }
    }
    
    @IBAction func customButtonAction(sender: AnyObject)
    {
        if isEditingPatch
        {
            deletePatchButtonAction(sender)
        }
        else
        {
            createPatchButtonAction(sender)
        }
    }
    


    func createPatchButtonAction(sender: AnyObject)
    {
        println("create patch button")
        println("patch name: \(patchName)")
        println("patch description: \(patchDescription)")
        println("patch type: \(patchType)")
        println("patch banner: \(patchImage)")
        println("patch privacy: \(patchPrivacy)")
        println("patch location: \(patchLocation)")
        
        let proxibase = ProxibaseClient.sharedInstance
        
        let parameters: NSDictionary = [
                "name": patchName,
                "visibility": patchPrivacy,
                "description": patchDescription,
                "category": proxibase.categories[patchType]! as AnyObject,
                "location": patchLocation! as AnyObject,
                "photo": patchImage as AnyObject,
                "links": [["_from": (ProxibaseClient.sharedInstance.userId)!, "type": "create"]]
               ]
        
        proxibase.createObject("data/patches", parameters: parameters) { response, error in
            dispatch_async(dispatch_get_main_queue())
            {
                if let error = ServerError(error) {
                    println("Create Patch Error")
                    println(error)

                    self.ErrorNotificationAlert(LocalizedString("Error"), message: error.message) {}
                }
                else
                {
                    println("Create Patch Successful")
                    println(response)
                    if let patchID = (response?["data"] as NSDictionary?)?["_id"] as? String
                    {
                        println("Created patch id \(patchID)")
                    }

                    self.performSegueWithIdentifier("UnwindFromCreateEditPatch", sender: nil)
                }
            }
        }
    }


    func deletePatchButtonAction(sender: AnyObject)
    {
        self.ActionConfirmationAlert(LocalizedString("Confirm Delete"), message: LocalizedString("Are you sure you want to delete this?"), actionTitle: LocalizedString("Delete"), cancelTitle: LocalizedString("Cancel")) { doIt in

            let patchPath = "data/patches/\((self.patch?.id_)!)"
            ProxibaseClient.sharedInstance.deleteObject(patchPath) { response, error in
                if let serverError = ServerError(error)
                {
                    println(error)
                    self.ErrorNotificationAlert(LocalizedString("Error"), message: serverError.message) {}
                }
                else
                {
                    println(response)
                    self.performSegueWithIdentifier("UnwindFromCreateEditPatch", sender: nil)
                    // TODO: This needs to unwind farther, since we need to unwind two levels
                }
            }
            
        }
        println("delete patch button")
    }

    @IBAction func saveButtonAction(sender: AnyObject) {
        println("save button")
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if patchName.utf16Count == 0 {
            patchNameField.becomeFirstResponder()
        }
        
        let userLocation = AppDelegate.appDelegate().locationManager.location
        
        var distanceString = ""
        
        if let patchLocation = patchLocation {
        
            let distanceFromPatch = patchLocation.distanceFromLocation(userLocation)
            if distanceFromPatch < 20.0
            {
                distanceString = LocalizedString("Here")
            }
            else if distanceFromPatch < 1500.0
            {
                distanceString = String(format:"%d meters", Int(distanceFromPatch))
            }
            else
            {
                distanceString = String(format:"%3.1f km", distanceFromPatch / 1000)
            }
        }
        patchLocationCell.detailTextLabel?.text = distanceString
    }

    private func endFieldEditing()
    {
        for field in [patchNameField, patchDescriptionField] {
            if field.isFirstResponder() {
                field.endEditing(false)
            }
        }
    }
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?
    {
        let index = (indexPath.section, indexPath.row)
        
        switch index {
            case (InfoSection, 1): return indexPath
            case (TypeSection, let row): return indexPath
            default:
                endFieldEditing()
                return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let index = (indexPath.section, indexPath.row)
        
        switch index {
            case (InfoSection, LocationRow):
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            case (TypeSection, let row):
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                patchType = patchTypeIDs[row]
            default: break
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView
    {
        let view = UILabel(frame: CGRect(x:10, y: 0, width: 100, height:20))
        
        if section == TypeSection
        {
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16.0

            let attributes = NSMutableDictionary()
            attributes.setValue(style, forKey: NSParagraphStyleAttributeName)
            attributes.setValue(UIColor(white: 0.50, alpha: 1.0), forKey: NSForegroundColorAttributeName)
            attributes.setValue(-4.0, forKey: NSBaselineOffsetAttributeName)
            
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            attributes.setValue(font, forKey: NSFontAttributeName)
            
            view.attributedText = NSMutableAttributedString(string: "PATCH TYPE", attributes: attributes)
        }
        view.backgroundColor = UIColor(white:0.92, alpha: 1.0)
        return view
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        switch section {
            case NameSection: return 30
            case TypeSection: return 40
            default: return 0
        }
    }
    
    func updateCreatePatchButton()
    {
        if isEditingPatch
        {
            saveButton.enabled = (patchName.utf16Count > 0)
        }
        else
        {
            customButton.enabled = (patchName.utf16Count > 0)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if let destinationViewController = segue.destinationViewController as? PatchMapViewController {
            destinationViewController.locationProvider = self
        }
    }
 
}