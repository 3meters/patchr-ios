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

class NavigationViewController: UITableViewController {

    let searchActivities: NSMutableArray = []
    let totalActivities: NSMutableArray = []
    var currentActivities: NSMutableArray = []

    var searchInProgress = false
    var searchEditing = false

    var sectionHeaderView: UIView!
    var searchField = AirSearchField()
    var name = UILabel()
    var photo = UserPhotoView()
    var header = UIView(frame: CGRectMake(0, 0, 0, 64))

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.tableView.bounds.size.width = NAVIGATION_DRAWER_WIDTH + 60
        
        self.header.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 128)
        self.searchField.fillSuperviewWithLeftPadding(8, rightPadding: 8, topPadding: 8, bottomPadding: 72)
        self.photo.alignUnder(self.searchField, withLeftPadding: 8, topPadding: 8, width: 48, height: 48)
        self.name.sizeToFit()
        self.name.alignToTheRightOf(self.photo, matchingCenterWithLeftPadding: 8, width: self.name.width(), height: self.name.height())
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func textFieldDidChange(textField: UITextField) {

        self.searchEditing = (textField.text!.length > 0)

        if !self.searchEditing {
            self.currentActivities = self.totalActivities
            self.tableView.reloadData()             // To reshow recents
        }
        else if textField.text!.length >= 2 {
            search()
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("ActivitySearch")
        self.navigationItem.title = "Search Activities"

        self.view.accessibilityIdentifier = View.Navigation
        self.tableView!.accessibilityIdentifier = Table.Search

        self.currentActivities = self.totalActivities

        self.searchField.placeholder = "Search activities"
        self.searchField.addTarget(self, action: #selector(NavigationViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.searchField.delegate = self
        self.header.addSubview(self.searchField)

        /* Patch photo */
        self.header.addSubview(self.photo)

        /* Patch name */
        self.name.font = Theme.fontTitle
        self.name.numberOfLines = 1
        self.header.addSubview(self.name)

        self.tableView.tableHeaderView = self.header
        self.tableView.backgroundColor = UIColor.whiteColor()
        self.tableView.tableFooterView = UIView()   // Triggers data binding

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NavigationViewController.dismissKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(gestureRecognizer)
    }

    func search() {

        if self.searchInProgress {
            return
        }

        self.searchInProgress = true
        let searchString = self.searchField.text

        Log.d("Search activities: \(searchString!)")
    }

    func dismissKeyboard() {
        self.searchField.endEditing(true)
    }
}

extension NavigationViewController: UITextFieldDelegate {
    /*
    * UITextFieldDelegate
    */
    func textFieldDidEndEditing(textField: UITextField) {
        self.searchField.resignFirstResponder()
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        self.searchField.resignFirstResponder()
        return true
    }
}

extension NavigationViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? PatchSearchCell

        if cell == nil {
            let nib: Array = NSBundle.mainBundle().loadNibNamed("PatchSearchCell", owner: self, options: nil)
            cell = nib[0] as? PatchSearchCell
        }

        var patch: JSON = JSON(self.currentActivities[indexPath.row])
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
        return self.currentActivities.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        var patchJson: JSON = JSON(self.currentActivities[indexPath.row])
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
        return self.currentActivities.count == 0 ? 0 : 40
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UILabel(frame: CGRect(x: 10, y: 0, width: 100, height: 20))

        if section == 0 {
            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16.0

            let attributes = [
                    NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline),
                    NSUnderlineStyleAttributeName: 1,
                    NSParagraphStyleAttributeName: style,
                    NSForegroundColorAttributeName: UIColor(white: 0.50, alpha: 1.0),
                    NSBaselineOffsetAttributeName: -4.0]

            let label = self.searchEditing ? "SEARCH" : "ACTIVITIES"

            view.attributedText = NSMutableAttributedString(string: label, attributes: attributes)
        }

        self.sectionHeaderView = view
        return view
    }

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY > 0 {
            let alpha = min(1, 1 - ((40 - offsetY) / 40))
            self.sectionHeaderView?.backgroundColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(alpha))
        }
        else {
            self.sectionHeaderView?.backgroundColor = UIColor(red: CGFloat(1.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: CGFloat(0))
        }
    }
}