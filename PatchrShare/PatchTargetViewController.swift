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
    var searchTimer: Timer?
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.title = "Choose Patch"

        let imageView = UIImageView(frame: CGRect(x:8, y:0, width:20, height:20))
        imageView.image = UIImage(named: "imgSearchLight")

        let searchView = UIView(frame: CGRect(x:8, y:0, width:40, height:40))
        searchView.alpha = 0.5
        searchView.addSubview(imageView)
        imageView.anchorInCenter(withWidth: 24, height: 24)

        self.searchField.font = Theme.fontText
        self.searchField.textColor = Theme.colorText
        self.searchField.layer.cornerRadius = CGFloat(Theme.dimenButtonCornerRadius)
        self.searchField.layer.masksToBounds = true
        self.searchField.layer.borderColor = Theme.colorButtonBorder.cgColor
        self.searchField.layer.borderWidth = Theme.dimenButtonBorderWidth
        self.searchField.leftViewMode = UITextFieldViewMode.always
        self.searchField.leftView = searchView
        self.searchField.clearButtonMode = UITextFieldViewMode.whileEditing

        self.searchField.placeholder = "Search for patches"
        self.searchField.delegate = self
        self.searchField.addTarget(self, action: #selector(PatchTargetViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        // Recents
        self.currentItems = recentItems
        if let groupDefaults = UserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            self.userId = groupDefaults.string(forKey: PatchrUserDefaultKey(subKey: "userId"))
            if let recentPatches = groupDefaults.array(forKey: PatchrUserDefaultKey(subKey: "recent.patches")) as? [[String:AnyObject]] {
                for recent in recentPatches {
                    self.recentItems.add(recent)
                }
            }
        }
    }

    func suggest() {

        if self.searchInProgress {
            return
        }

        self.searchInProgress = true
        let searchString = self.searchField.text!.lowercased()

        Log.d("Suggest call: \(searchString)")

        let endpoint: String = "https://api.aircandi.com/v1/suggest"
        let request = NSMutableURLRequest(url: NSURL(string: endpoint)! as URL)
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        var body: [String: Any] = [
            "patches": true,
            "input": searchString,
            "provider": "google",
            "limit": 10]
        
        if self.userId != nil {
            body["_user"] = self.userId!
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                data, response, error in
                
                self.searchInProgress = false
                self.searchItems.removeAllObjects()
                
                if error == nil {
                    let json = JSON(data: data!)
                    let results = json["data"]
                    for (index: _, subJson) in results {
                        let patch: AnyObject = subJson.object as AnyObject
                        self.searchItems.add(patch)
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
}

extension PatchTargetViewController: UITextFieldDelegate {

    func textFieldDidChange(_ textField: UITextField) {
        
        self.searchEditing = ((textField.text?.characters.count)! > 0)
        if textField.text!.characters.count == 0 {
            self.currentItems = self.recentItems
            self.tableView.reloadData()             // To reshow recents
        }
        else if textField.text!.characters.count >= 2 {
            /* To limit network activity, reload half a second after last key press. */
            if let _ = self.searchTimer {
                self.searchTimer?.invalidate()
            }
            self.searchTimer = Timer(timeInterval:0.5, target:self, selector:#selector(PatchTargetViewController.suggest), userInfo:nil, repeats:false)
            RunLoop.current.add(self.searchTimer!, forMode: RunLoopMode(rawValue: "NSDefaultRunLoopMode"))
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.searchField.resignFirstResponder()
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
    }
}

extension PatchTargetViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER) as? PatchSuggestCell
        if cell == nil {
            let nib:Array = Bundle.main.loadNibNamed("PatchSuggestCell", owner: self, options: nil)!
            cell = nib[0] as? PatchSuggestCell
            cell?.contentView.backgroundColor = UIColor.clear
            cell?.backgroundColor = UIColor.clear
        }
        
        var patch: JSON = JSON(self.currentItems[indexPath.row])
        cell!.name.text = patch["name"].string
        
        if patch["photo"] != JSON.null {
            let prefix = patch["photo"]["prefix"].string
            let source = patch["photo"]["source"].string
            let photoUrl = PhotoUtils.url(prefix: prefix!, source: source!, category: SizeCategory.thumbnail)
            cell!.photo.sd_setImage(with: photoUrl as URL!)
        }
        else if patch["name"] != JSON.null {
            let seed = Utils.numberFromName(fullname: patch["name"].string!)
            cell!.photo.backgroundColor = Utils.randomColor(seed: seed)
            cell!.photo.updateConstraints()
        }

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var patchJson: JSON = JSON(self.currentItems[indexPath.row])
        if let patch = patchJson.dictionaryObject {
            self.delegate?.patchPickerViewController(sender: self, selectedValue: patch as AnyObject)
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
        
        //        view.backgroundColor = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0.2))
        self.headerView = view
        return view
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentItems.count
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
