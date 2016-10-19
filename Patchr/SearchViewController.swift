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
    
    var searchItems			= [Any]()
    var recentItems			= [Any]()
    var currentItems		= [Any]()
    
    var searchInProgress	= false
    var searchTimer			: Timer?
    var searchEditing		= false

    var inputState			: State? = State.Searching

    class func defaultPatch() -> String{
        return "None"
    }
    
    var searchField		= AirSearchField()
    var header			= UIView(frame: CGRect(x:0, y:0, width:0, height:64))
    
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
        self.header.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 64)
        self.searchField.fillSuperview(withLeftPadding: 8, rightPadding: 8, topPadding: 8, bottomPadding: 8)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecents() // In case there is something new while we were away
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func textFieldDidChange(_ textField: UITextField) {
        
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
            self.searchTimer = Timer(timeInterval:0.5, target:self, selector:#selector(SearchViewController.suggest), userInfo:nil, repeats:false)
            RunLoop.current.add(self.searchTimer!, forMode: RunLoopMode(rawValue: "NSDefaultRunLoopMode"))
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("PatchSearch")
        self.navigationItem.title = "Search Patchr"

        self.currentItems = self.recentItems

        self.searchField.placeholder = "Search for patches"
        self.searchField.addTarget(self, action: #selector(SearchViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.searchField.delegate = self
        self.header.addSubview(self.searchField)

        self.tableView.tableHeaderView = self.header
        self.tableView.backgroundColor = UIColor.white
        self.tableView.tableFooterView = UIView()   // Triggers data binding

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(gestureRecognizer)
    }

    func loadRecents() {
        self.recentItems.removeAll()
        if let groupDefaults = UserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            self.userId = groupDefaults.string(forKey: PatchrUserDefaultKey(subKey: "userId"))
            self.sessionKey = UserController.instance.lockbox!.unarchiveObject(forKey: "sessionKey") as? String
            if let recentPatches = groupDefaults.array(forKey: PatchrUserDefaultKey(subKey: "recent.patches")) as? [[String:Any]] {
                for recent in recentPatches {
                    self.recentItems.append(recent)
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

        let endpoint: String = "\(DataController.proxibase.serviceUri)suggest"
        var request = URLRequest(url: URL(string: endpoint)!)
        let session = URLSession.shared
        request.httpMethod = "POST"

        var body: [String:Any]?

        if self.inputState == .Searching {
            body = [
                "patches": true,
                "input": searchString!.lowercased(),
                "provider": "google",
                "limit": 10 ] as [String:Any]

            if self.userId != nil {
                body!["_user"] = self.userId!
            }
        }
        else {
            body = [
                "users": true,
                "input": searchString!.lowercased(),
                "limit":10 ] as [String:Any]
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body!, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTask(with: request, completionHandler: {
                data, response, error -> Void in
                
                self.searchInProgress = false
                self.searchItems.removeAll()
                
                if error == nil {
                    let json:JSON = JSON(data: data!)
                    let results = json["data"]
                    for (index: _, subJson) in results {
                        let patch: Any = subJson.object
                        self.searchItems.append(patch)
                    }
                    self.currentItems = self.searchItems
                    DispatchQueue.main.async(execute: {
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

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.searchField.resignFirstResponder()
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
    }
}

extension SearchViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: PatchSearchCell? = tableView.dequeueReusableCell(withIdentifier: (CELL_IDENTIFIER)) as? PatchSearchCell

        if cell == nil {
            cell = Bundle.main.loadNibNamed("PatchSearchCell", owner: self, options: nil)?[0] as! PatchSearchCell?
        }
        
        var patch: JSON = JSON(self.currentItems[indexPath.row])
        cell!.name.text = patch["name"].string
        
        if patch["photo"] != JSON.null {
            let prefix = patch["photo"]["prefix"].string
            let source = patch["photo"]["source"].string
            let photoUrl = PhotoUtils.url(prefix: prefix!, source: source!, category: SizeCategory.thumbnail)
            cell!.photo.sd_setImage(with: photoUrl)
        }
        else if patch["name"] != JSON.null {
            let seed = Utils.numberFromName(fullname: patch["name"].string!)
            cell!.photo.backgroundColor = Utils.randomColor(seed: seed)
            cell!.photo.updateConstraints()
        }

        return cell!
    }
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentItems.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.currentItems.count == 0 ? 0 : 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UILabel(frame: CGRect(x: 10, y: 0, width: 100, height: 20))
        
        if section == 0 {
            
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16.0
            
            let attributes = [
                NSFontAttributeName : UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline),
                NSUnderlineStyleAttributeName : 1,
                NSParagraphStyleAttributeName : style,
                NSForegroundColorAttributeName : UIColor(white: 0.50, alpha: 1.0),
                NSBaselineOffsetAttributeName : -4.0] as [String : Any]
            
            let label = self.searchEditing ? "SUGGESTIONS" : "RECENTS"
            
            view.attributedText = NSMutableAttributedString(string: label, attributes: attributes)
        }
        
        self.headerView = view
        return view
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
