//
//  PatchTargetViewController.swift
//  Patchr
//
//  Created by Jay Massena on 8/2/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

//
//  ShareViewController.swift
//  share
//
//  Created by Jay Massena on 7/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

protocol PatchTargetViewControllerDelegate{
     func patchPickerViewController(
        sender: PatchTargetViewController,
        selectedValue: AnyObject)
}

class PatchTargetViewController: UITableViewController {
    
    var delegate: PatchTargetViewControllerDelegate?
    
    var patch = "None"
    var userId: String?
    var sessionKey: String?
    
    var headerView: UIView!
    
	let searchItems: NSMutableArray = []
	let recentItems: NSMutableArray = []
	var currentItems: NSMutableArray = []
	
    var searchInProgress = false
    var searchTimer: NSTimer?
    var searchEditing = false
    
    var locationCurrent : CLLocation?
    var manager: OneShotLocationManager?
    
    class func defaultPatch() -> String{
        return "None"
    }
    
    @IBOutlet weak var searchEdit: UITextField!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* If already authorized then grab the location */
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways
            || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
                
                self.manager = OneShotLocationManager()
                self.manager!.fetchWithCompletion {
                    location, error in
                    
                    if let loc = location {
                        Log.d("One shot location received")
                        self.locationCurrent = loc
                    }
                    self.manager = nil
                }
        }
        
        self.title = "Choose Patch"
        
        self.searchEdit.layer.cornerRadius = 8.0
        self.searchEdit.layer.masksToBounds = true
        self.searchEdit.layer.borderColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1)).CGColor
        self.searchEdit.layer.borderWidth = 1.0
        self.searchEdit.attributedPlaceholder = NSAttributedString(string: "Search for patches",
            attributes: [NSForegroundColorAttributeName:UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1))])
        self.searchEdit.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)
        
        let searchView = UIView(frame: CGRectMake(0, 0, 32, 24))
        let imageView = UIImageView(frame: CGRectMake(8, 0, 24, 24))
        imageView.image = UIImage(named: "imgSearchLight")
        searchView.addSubview(imageView)
        searchView.alpha = 0.5
        
        self.searchEdit.leftViewMode = UITextFieldViewMode.Always
        self.searchEdit.leftView = searchView
        
        // Recents
        self.currentItems = recentItems
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            self.userId = groupDefaults.stringForKey(PatchrUserDefaultKey("userId"))
			let lockbox = Lockbox(keyPrefix: KEYCHAIN_GROUP)
			self.sessionKey = lockbox.stringForKey("sessionKey") as String?

            self.sessionKey = groupDefaults.stringForKey(PatchrUserDefaultKey("sessionKey"))
            if let recentPatches = groupDefaults.arrayForKey(PatchrUserDefaultKey("recent.patches")) as? [[String:AnyObject]] {
                for recent in recentPatches {
                    self.recentItems.addObject(recent)
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		self.tableView.reloadData()
    }
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func textFieldDidChange(textField: UITextField) {
        
        self.searchEditing = (textField.text?.characters.count > 0)
        if textField.text!.characters.count == 0 {
            self.currentItems = self.recentItems
            self.tableView.reloadData()             // To reshow recents
        }
        else if textField.text!.characters.count >= 2 {
            /* To limit network activity, reload half a second after last key press. */
            if let _ = self.searchTimer {
                self.searchTimer?.invalidate()
            }
            self.searchTimer = NSTimer(timeInterval:0.5, target:self, selector:Selector("suggest"), userInfo:nil, repeats:false)
            NSRunLoop.currentRunLoop().addTimer(self.searchTimer!, forMode: "NSDefaultRunLoopMode")
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func suggest() {
        
        if self.searchInProgress {
            return
        }
        
        self.searchInProgress = true
        let searchString = self.searchEdit.text
        
        Log.d("Suggest call: \(searchString)")
        
        let endpoint: String = "https://api.aircandi.com/v1/suggest"
        let request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var body = [
            "patches": true,
            "input": searchString!.lowercaseString,
            "provider": "google",
            "limit": 10
        ] as [String: AnyObject]
        
        if self.userId != nil {
            body["_user"] = self.userId!
        }
        
        if self.locationCurrent != nil {
            let coordinate = self.locationCurrent!.coordinate
            let location = [
                "lat":coordinate.latitude,
                "lng":coordinate.longitude
                ] as [String:AnyObject]
            body["location"] = location
            body["radius"] = 80000  // ~50 miles
            body["timeout"] = 2000  // two seconds
        }
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(body, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTaskWithRequest(request, completionHandler: {
                data, response, error -> Void in
                
                self.searchInProgress = false
                self.searchItems.removeAllObjects()
                
                if error == nil {
                    let json = JSON(data: data!)
                    let results = json["data"]
                    for (index: _, subJson) in results {
                        let patch: AnyObject = subJson.object
                        self.searchItems.addObject(patch)
                    }
                    self.currentItems = self.searchItems
                    dispatch_async(dispatch_get_main_queue(),{
                        self.tableView?.reloadData()
                    })
                }
            })
            
            task.resume()
        }
        catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
    }
}

extension PatchTargetViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? PatchSuggestCell
        if cell == nil {
            let nib:Array = NSBundle.mainBundle().loadNibNamed("PatchSuggestCell", owner: self, options: nil)
            cell = nib[0] as? PatchSuggestCell
            cell?.contentView.backgroundColor = UIColor.clearColor()
            cell?.backgroundColor = UIColor.clearColor()
        }
        
        var patch: JSON = JSON(self.currentItems[indexPath.row])
        cell!.name.text = patch["name"].string
        
        if patch["photo"] != nil {
            
            let prefix = patch["photo"]["prefix"].string
            let source = patch["photo"]["source"].string
            let photoUrl = PhotoUtils.url(prefix!, source: source!, category: SizeCategory.thumbnail)
            cell!.photo.sd_setImageWithURL(photoUrl)
        }
        else {
            cell!.photo.image = UIImage(named: "imgDefaultPatch")
            cell!.photo.updateConstraints()
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var patchJson: JSON = JSON(self.currentItems[indexPath.row])
        if let patch = patchJson.dictionaryObject {
            self.delegate?.patchPickerViewController(self, selectedValue: patch)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return self.currentItems.count == 0 ? 0 : 40
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UILabel(frame: CGRect(x: 10, y: 0, width: 100, height: 20))
        
        if section == 0 {
            
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16.0
            
            let attributes = [
                NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline),
                NSUnderlineStyleAttributeName : 1,
                NSParagraphStyleAttributeName : style,
                NSForegroundColorAttributeName : UIColor(white: 0.50, alpha: 1.0),
                NSBaselineOffsetAttributeName : -4.0]
            
            let label = self.searchEditing ? "SUGGESTIONS" : "RECENTS"
            
            view.attributedText = NSMutableAttributedString(string: label, attributes: attributes)
        }
        
        //        view.backgroundColor = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0.2))
        self.headerView = view
        return view
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentItems.count
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY > 50 {
            let alpha = min(1, 1 - ((50 + 64 - offsetY) / 64))
            self.headerView?.backgroundColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(alpha))
        }
        else {
            self.headerView?.backgroundColor = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0))
        }
    }
}