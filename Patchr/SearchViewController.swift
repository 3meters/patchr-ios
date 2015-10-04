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

class SearchViewController: UITableViewController {
    
    var suggestItems: [NSObject: AnyObject] = [:]
    
    var _filterSuggestItems = [NSObject]()
    var filterSuggestItems: [NSObject] {
        get {
            var itemsCopy: [NSObject]!
            dispatch_sync(concurrentQueue) {
                itemsCopy = Array(self._filterSuggestItems)
            }
            return itemsCopy
        }
        set {
            dispatch_barrier_async(concurrentQueue) {
                self._filterSuggestItems = newValue
            }
        }
    }
    
    let searchItems = NSMutableArray()
    var searchInProgress = false
    var searchTimer: NSTimer?
    var searchEditing = false
    var searchString: String!
    
    var userId: String!
    var sessionKey: String!
    var selectedPatchId: String!
    
    var locationCurrent : CLLocation?
    var manager: OneShotLocationManager?
    var emptyLabel: AirLabel = AirLabel(frame: CGRectMake(100, 100, 100, 100))
    var progress: MBProgressHUD?    
    private let concurrentQueue = dispatch_queue_create("com.3meters.patchr.ios.queue", DISPATCH_QUEUE_CONCURRENT)
    
    @IBOutlet weak var superSearchBar: UISearchBar!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let searches = NSUserDefaults.standardUserDefaults().dictionaryForKey(PatchrUserDefaultKey("searches")) {
            suggestItems = searches
        }
        
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
                
        self.userId = NSUserDefaults.standardUserDefaults().stringForKey(PatchrUserDefaultKey("userId"))
        self.sessionKey = NSUserDefaults.standardUserDefaults().stringForKey(PatchrUserDefaultKey("sessionKey"))
        self.searchDisplayController?.displaysSearchBarInNavigationBar = true
        
        let window = UIApplication.sharedApplication().delegate?.window!
        
        /* Wacky activity control for body */
        progress = MBProgressHUD.showHUDAddedTo(window, animated: true)
        progress!.mode = MBProgressHUDMode.Indeterminate
        progress!.square = true
        progress!.opacity = 0.0
        progress!.removeFromSuperViewOnHide = true
        progress!.userInteractionEnabled = false
        progress!.activityIndicatorColor = Colors.brandColorDark
        progress!.hide(false)
        
        /* Empty label */
        self.emptyLabel.alpha = 0
        self.emptyLabel.layer.borderWidth = 1
        self.emptyLabel.layer.borderColor = Colors.hintColor.CGColor
        self.emptyLabel.font = UIFont(name: "HelveticaNeue-Light", size: 19)
        self.emptyLabel.text = "No results"
        self.emptyLabel.bounds.size.width = 160
        self.emptyLabel.bounds.size.height = 160
        self.emptyLabel.numberOfLines = 0
        self.view.addSubview(self.emptyLabel)
        self.emptyLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width / 2, (UIScreen.mainScreen().bounds.size.height / 2) - 44);
        self.emptyLabel.textAlignment = NSTextAlignment.Center
        self.emptyLabel.textColor = UIColor(red: CGFloat(0.6), green: CGFloat(0.6), blue: CGFloat(0.6), alpha: CGFloat(1))
        self.emptyLabel.layer.backgroundColor = UIColor.whiteColor().CGColor
        self.emptyLabel.layer.cornerRadius = self.emptyLabel.bounds.size.width / 2

        /* Hack to hide empty row separators */
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsSelection = true
        self.searchDisplayController?.searchResultsTitle = "SUGGESTIONS"
        
        // Reload the table
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.progress?.hide(false)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func filterContentForSearchText(searchText: String) {
        var keys: Array = self.suggestItems.keys.array
        self.filterSuggestItems = keys.filter({( item: NSObject) -> Bool in
            let suggest = item as! String
            let stringMatch = suggest.rangeOfString(searchText)
            return stringMatch != nil
        })
    }
    
    func search() {
        
        if self.searchInProgress {
            return
        }
        
        if self.emptyLabel.alpha > 0 {
            self.emptyLabel.fadeOut()
        }
        
        self.searchInProgress = true
        self.searchEditing = (self.superSearchBar.text.length > 0)
        self.progress?.show(true)
        let searchString: String = self.searchString!
        
        Log.d("Search call: \(searchString)")
        
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
            self.progress?.hide(true)
            
            if error == nil {
                let json:JSON = JSON(data: data)
                let results = json["data"]
                for (index: String, subJson: JSON) in results {
                    let patch: AnyObject = subJson.object
                    self.searchItems.addObject(patch)
                }
                
                /* Add to stashed search string */
                if var searches = NSUserDefaults.standardUserDefaults().dictionaryForKey(PatchrUserDefaultKey("searches")) {
                    searches[searchString] = true
                    NSUserDefaults.standardUserDefaults().setObject(searches, forKey:PatchrUserDefaultKey("searches"))
                    NSUserDefaults.standardUserDefaults().synchronize()
                    self.suggestItems = searches
                }

                else {
                    var searches: [NSObject: AnyObject] = [searchString: true]
                    NSUserDefaults.standardUserDefaults().setObject(searches, forKey:PatchrUserDefaultKey("searches"))
                    NSUserDefaults.standardUserDefaults().synchronize()
                    self.suggestItems = searches
                }
                
                dispatch_async(dispatch_get_main_queue(),{
                    self.tableView.reloadData()
                    if self.searchItems.count == 0 {
                        self.emptyLabel.fadeIn()
                    }
                })
            }
        })
        
        task.resume()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == nil {
            return
        }
        
        switch segue.identifier! {
            case "PatchDetailSegue":
                if let controller = segue.destinationViewController as? PatchDetailViewController {
                    controller.entityId = self.selectedPatchId
                }
            default: ()
        }
    }

}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchItems.removeAllObjects()
        self.tableView.reloadData()
        self.superSearchBar.showsCancelButton = true
        self.emptyLabel.fadeOut()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        self.superSearchBar.showsCancelButton = false
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchString = self.superSearchBar.text
        self.superSearchBar.resignFirstResponder()
        self.searchDisplayController?.setActive(false, animated: true)
        search()
    }
}

extension SearchViewController: UISearchDisplayDelegate {
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, didShowSearchResultsTableView tableView: UITableView) {
        let frame = tableView.frame
        let newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 300)
        tableView.frame = newFrame
    }
}

extension SearchViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == self.searchDisplayController!.searchResultsTableView {
            
            var cell = tableView.dequeueReusableCellWithIdentifier("suggestcell") as? UITableViewCell
            if cell == nil {
                cell = UITableViewCell()
            }
            
            var item = self.filterSuggestItems[indexPath.row] as! String
            cell!.textLabel!.text = item
            return cell!
        }
        else {
        
            var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? PatchSearchCell
            if cell == nil {
                let nib:Array = NSBundle.mainBundle().loadNibNamed("PatchSearchCell", owner: self, options: nil)
                cell = nib[0] as? PatchSearchCell
                cell?.contentView.backgroundColor = UIColor.clearColor()
                cell?.backgroundColor = UIColor.clearColor()
            }
            
            var patch: JSON = JSON(self.searchItems[indexPath.row])
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
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            let filterItems = self.filterSuggestItems
            self.superSearchBar.text = filterItems[indexPath.row] as! String
            self.searchString = filterItems[indexPath.row] as! String
            self.superSearchBar.resignFirstResponder()
            self.searchDisplayController?.setActive(false, animated: true)
            search()
        }
        else {
            let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! PatchSearchCell
            var patchJson: JSON = JSON(self.searchItems[indexPath.row])
            self.selectedPatchId = patchJson["_id"].string
            self.performSegueWithIdentifier("PatchDetailSegue", sender: self)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filterSuggestItems.count
        }
        else {
            return self.searchItems.count
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
}