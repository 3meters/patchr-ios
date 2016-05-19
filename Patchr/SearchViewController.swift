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
    
    var patch				= "None"
    var userId				: String?
    var sessionKey			: String?
    
    var headerView			: UIView!
    
    let searchItems			: NSMutableArray = []
    let recentItems			: NSMutableArray = []
	var currentItems		: NSMutableArray = []
    
    var searchInProgress	= false
    var searchTimer			: NSTimer?
    var searchEditing		= false
	
	var inputState			: State? = State.Searching
	
    var locationCurrent		: CLLocation?
    var manager				: OneShotLocationManager?
    
    class func defaultPatch() -> String{
        return "None"
    }
    
    var searchField		= AirSearchField()
	var header			= UIView(frame: CGRectMake(0, 0, 0, 64))
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
		self.tableView.bounds.size.width = viewWidth
		self.header.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 64)
		self.searchField.fillSuperviewWithLeftPadding(8, rightPadding: 8, topPadding: 8, bottomPadding: 8)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		loadRecents() // In case there is something new while we were away
	}

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
		self.tableView.reloadData()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
    func textFieldDidChange(textField: UITextField) {
        
		if let timer = self.searchTimer {
			timer.invalidate()
		}
		
        self.searchEditing = (textField.text!.length > 0)
		
        if !self.searchEditing {
            self.currentItems = self.recentItems
            self.tableView.reloadData()             // To reshow recents
        }
        else if textField.text!.length >= 2 {
            /* To limit network activity, reload half a second after last key press. */
            self.searchTimer = NSTimer(timeInterval:0.5, target:self, selector:#selector(SearchViewController.suggest), userInfo:nil, repeats:false)
            NSRunLoop.currentRunLoop().addTimer(self.searchTimer!, forMode: "NSDefaultRunLoopMode")
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		Reporting.screen("PatchSearch")
		self.navigationItem.title = "Search Patchr"
		
		self.view.accessibilityIdentifier = View.Search
		self.tableView!.accessibilityIdentifier = Table.Search

		/* If already authorized then grab the location */
		let authorized = (CLLocationManager.authorizationStatus() == .AuthorizedAlways
			|| CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse)
		
		if authorized {
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
		
		self.currentItems = self.recentItems
		
		self.searchField.placeholder = "Search for patches"
		self.searchField.addTarget(self, action: #selector(SearchViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
		self.searchField.delegate = self		
		self.header.addSubview(self.searchField)
		
		self.tableView.tableHeaderView = self.header
		self.tableView.backgroundColor = UIColor.whiteColor()
		self.tableView.tableFooterView = UIView()   // Triggers data binding
		
		let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
		gestureRecognizer.cancelsTouchesInView = false
		self.tableView.addGestureRecognizer(gestureRecognizer)
	}
	
	func loadRecents() {
		self.recentItems.removeAllObjects()
		if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
			self.userId = groupDefaults.stringForKey(PatchrUserDefaultKey("userId"))
			self.sessionKey = UserController.instance.lockbox.unarchiveObjectForKey("sessionKey") as? String
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
		
        Log.d("Suggest call: \(searchString!)")
		
        let endpoint: String = "https://api.aircandi.com/v1/suggest"
        let request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
		
		var body: [String:AnyObject]?
		
		if self.inputState == .Searching {
			body = [
				"patches": true,
				"input": searchString!.lowercaseString,
				"provider": "google",
				"limit": 10 ] as [String:AnyObject]
			
			if self.userId != nil {
				body!["_user"] = self.userId!
			}
			
			if self.locationCurrent != nil {
				let coordinate = self.locationCurrent!.coordinate
				let location = [
					"lat":coordinate.latitude,
					"lng":coordinate.longitude
					] as [String:AnyObject]
				body!["location"] = location
				body!["radius"] = 80000  // ~50 miles
				body!["timeout"] = 2000  // two seconds
			}
		}
		else {
			body = [
				"users": true,
				"input": searchString!.lowercaseString,
				"limit":10 ] as [String:AnyObject]
		}
		
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(body!, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTaskWithRequest(request, completionHandler: {
                data, response, error -> Void in
                
                self.searchInProgress = false
                self.searchItems.removeAllObjects()
                
                if error == nil {
                    let json:JSON = JSON(data: data!)
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
    
    func dismissKeyboard() {
        self.searchField.endEditing(true)
    }
}

extension SearchViewController: UITextFieldDelegate {
	
    func textFieldDidEndEditing(textField: UITextField) {
        self.searchField.resignFirstResponder()
    }
	
    func textFieldShouldClear(textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
    }
}

extension SearchViewController {
    /*
    * UITableViewDelegate
    */
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
    
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.currentItems.count
	}
	
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
        var patchJson: JSON = JSON(self.currentItems[indexPath.row])
        if let patch = patchJson.dictionaryObject {
			let controller = PatchDetailViewController()
            if let patchId = patch["id_"] as? String {
                controller.entityId = patchId
            }
            else if let patchId = patch["_id"] as? String {
                controller.entityId = patchId
            }
            if controller.entityId != nil {
                self.navigationController?.pushViewController(controller, animated: true)
            }
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
        
        self.headerView = view
        return view
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY > 0 {
            let alpha = min(1, 1 - ((40 - offsetY) / 40))
            self.headerView?.backgroundColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(alpha))
        }
        else {
            self.headerView?.backgroundColor = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0))
        }
    }
}