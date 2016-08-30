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
import Lockbox
import SDWebImage
import Facade

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
    
    class func defaultPatch() -> String{
        return "None"
    }
    
    @IBOutlet weak var searchField: UITextField!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
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
            self.searchTimer = NSTimer(timeInterval:0.5, target:self, selector:#selector(PatchTargetViewController.suggest), userInfo:nil, repeats:false)
            NSRunLoop.currentRunLoop().addTimer(self.searchTimer!, forMode: "NSDefaultRunLoopMode")
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.title = "Choose Patch"

        let imageView = UIImageView(frame: CGRectMake(8, 0, 20, 20))
        imageView.image = UIImage(named: "imgSearchLight")

        let searchView = UIView(frame: CGRectMake(0, 0, 40, 40))
        searchView.alpha = 0.5
        searchView.addSubview(imageView)
        imageView.anchorInCenterWithWidth(24, height: 24)

        self.searchField.font = Theme.fontText
        self.searchField.textColor = Theme.colorText
        self.searchField.layer.cornerRadius = CGFloat(Theme.dimenButtonCornerRadius)
        self.searchField.layer.masksToBounds = true
        self.searchField.layer.borderColor = Theme.colorButtonBorder.CGColor
        self.searchField.layer.borderWidth = Theme.dimenButtonBorderWidth
        self.searchField.leftViewMode = UITextFieldViewMode.Always
        self.searchField.leftView = searchView
        self.searchField.clearButtonMode = UITextFieldViewMode.WhileEditing

        self.searchField.placeholder = "Search for patches"
        self.searchField.delegate = self
        self.searchField.addTarget(self, action: #selector(PatchTargetViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        // Recents
        self.currentItems = recentItems
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            self.userId = groupDefaults.stringForKey(PatchrUserDefaultKey("userId"))
            let lockbox = Lockbox(keyPrefix: KEYCHAIN_GROUP)
            self.sessionKey = lockbox.unarchiveObjectForKey("sessionKey") as? String
            if let recentPatches = groupDefaults.arrayForKey(PatchrUserDefaultKey("recent.patches")) as? [[String:AnyObject]] {
                for recent in recentPatches {
                    self.recentItems.addObject(recent)
                }
            }
        }
    }

    func suggest() {

        if self.searchInProgress {
            return
        }

        self.searchInProgress = true
        let searchString = self.searchField.text

        Log.d("Suggest call: \(searchString)")

        let endpoint: String = "https://api.aircandi.com/v1/suggest"
        let request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var body: [String: AnyObject] = [
            "patches": true,
            "input": searchString!.lowercaseString,
            "provider": "google",
            "limit": 10]
        
        if self.userId != nil {
            body["_user"] = self.userId!
        }
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(body, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTaskWithRequest(request, completionHandler: {
                data, response, error in
                
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

extension PatchTargetViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(textField: UITextField) {
        self.searchField.resignFirstResponder()
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
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
        else if patch["name"] != nil {
            let seed = Utils.numberFromName(patch["name"].string!)
            cell!.photo.backgroundColor = Utils.randomColor(seed)
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