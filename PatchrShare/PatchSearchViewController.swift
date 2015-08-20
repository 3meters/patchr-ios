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

class PatchSearchViewController: UITableViewController {
    
    var patch = "None"
    var userId: String?
    var sessionKey: String?
    
    var headerView: UIView!
    
    let searchItems = NSMutableArray()
    let recentItems = NSMutableArray()
    var currentItems: NSMutableArray!
    
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
        
        self.navigationItem.title = "Search Patchr"
        
        self.searchEdit.layer.cornerRadius = 8.0
        self.searchEdit.layer.masksToBounds = true
        self.searchEdit.layer.borderColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1)).CGColor
        self.searchEdit.layer.borderWidth = 1.0
        self.searchEdit.attributedPlaceholder = NSAttributedString(string: "Search for patches",
            attributes: [NSForegroundColorAttributeName:UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1))])
        self.searchEdit.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)
        self.searchEdit.delegate = self
        
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
            self.sessionKey = groupDefaults.stringForKey(PatchrUserDefaultKey("sessionKey"))
            if var recentPatches = groupDefaults.arrayForKey(PatchrUserDefaultKey("recent.patches")) as? [[String:AnyObject]] {
                for recent in recentPatches {
                    self.recentItems.addObject(recent)
                }
            }
        }
        
        self.tableView.backgroundColor = UIColor.whiteColor()
        self.tableView.tableFooterView = UIView()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("dismissKeyboard"))
        gestureRecognizer.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(gestureRecognizer)
        
        // Reload the table
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("PatchSearch")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func textFieldDidChange(textField: UITextField) {
        
        self.searchEditing = (textField.text.length > 0)
        if textField.text.length == 0 {
            self.currentItems = self.recentItems
            self.tableView.reloadData()             // To reshow recents
        }
        else if textField.text.length >= 2 {
            /* To limit network activity, reload half a second after last key press. */
            if let timer = self.searchTimer {
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
        
        var endpoint: String = "https://api.aircandi.com/v1/suggest"
        var request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var body = [
            "patches":true,
            "input":searchString.lowercaseString,
            "provider":"google",
            "limit":10 ] as [String:AnyObject]
        
        if self.userId != nil {
            body["_user"] = self.userId!
        }
        
        if self.locationCurrent != nil {
            var coordinate = self.locationCurrent!.coordinate
            var location = [
                "lat":coordinate.latitude,
                "lng":coordinate.longitude
            ] as [String:AnyObject]
            body["location"] = location
            body["radius"] = 80000  // ~50 miles
            body["timeout"] = 2000  // two seconds
        }
        
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(body, options: nil, error: &err)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {
            data, response, error -> Void in
            
            self.searchInProgress = false
            self.searchItems.removeAllObjects()
            
            if error == nil {
                let json:JSON = JSON(data: data)
                let results = json["data"]
                for (index: String, subJson: JSON) in results {
                    let patch: AnyObject = subJson.object
                    self.searchItems.addObject(patch)
                }
                self.currentItems = self.searchItems
                dispatch_async(dispatch_get_main_queue(),{
                    tableView?.reloadData()
                })
            }
        })
        
        task.resume()
    }
    
    func dismissKeyboard() {
        self.searchEdit.endEditing(true)
    }
}

extension PatchSearchViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        self.searchEdit.resignFirstResponder()
    }
    func textFieldShouldClear(textField: UITextField) -> Bool {
        self.searchEdit.resignFirstResponder()
        return true
    }
}

extension PatchSearchViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? PatchSearchCell
        if cell == nil {
            let nib:Array = NSBundle.mainBundle().loadNibNamed("PatchSearchCell", owner: self, options: nil)
            cell = nib[0] as? PatchSearchCell
        }
        
        var patch: JSON = JSON(self.currentItems[indexPath.row])
        cell!.name.text = patch["name"].string
        
        if patch["photo"] != nil {
            
            let prefix = patch["photo"]["prefix"].string
            let source = patch["photo"]["source"].string
            
            let width = patch["photo"]["width"].int
            let height = patch["photo"]["height"].int
            
            var frameHeightPixels = Int(cell!.photo.frame.size.height * PIXEL_SCALE)
            var frameWidthPixels = Int(cell!.photo.frame.size.width * PIXEL_SCALE)
            
            let photoUrl = PhotoUtils.url(prefix!, source: source!)
            let photoUrlSized = PhotoUtils.urlSized(photoUrl, frameWidth: frameWidthPixels, frameHeight: frameHeightPixels, photoWidth: width, photoHeight: height)
            
            cell!.photo.sd_setImageWithURL(photoUrlSized)
        }
        else {
            cell!.photo.image = UIImage(named: "imgDefaultPatch")
            cell!.photo.updateConstraints()
        }
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! PatchSearchCell
        var patchJson: JSON = JSON(self.currentItems[indexPath.row])
        if let patch = patchJson.dictionaryObject {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let controller = storyboard.instantiateViewControllerWithIdentifier("PatchDetailViewController") as? PatchDetailViewController
            if let patchId = patch["id_"] as? String {
                controller!.patchId = patchId
            }
            else if let patchId = patch["_id"] as? String {
                controller!.patchId = patchId
            }
            if controller!.patchId != nil {
                self.navigationController?.pushViewController(controller!, animated: true)
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.currentItems == nil || self.currentItems.count == 0 {
            return 0
        }
        return 40
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UILabel(frame: CGRect(x: 10, y: 0, width: 100, height: 20))
        
        if section == 0 {
            
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16.0
            
            let attributes = NSMutableDictionary()
            attributes.setValue(style, forKey: NSParagraphStyleAttributeName)
            attributes.setValue(UIColor(white: 0.50, alpha: 1.0), forKey: NSForegroundColorAttributeName)
            attributes.setValue(-4.0, forKey: NSBaselineOffsetAttributeName)
            
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            attributes.setValue(font, forKey: NSFontAttributeName)
            
            let label = self.searchEditing ? "SUGGESTIONS" : "RECENTS"
            
            view.attributedText = NSMutableAttributedString(string: label, attributes: attributes as [NSObject:AnyObject])
        }
        
        self.headerView = view
        return view
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentItems != nil ? self.currentItems.count : 0
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let color = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0))
        if offsetY > 50 {
            let alpha = min(1, 1 - ((50 + 64 - offsetY) / 64))
            self.headerView?.backgroundColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(alpha))
        }
        else {
            self.headerView?.backgroundColor = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0))
        }
    }
}