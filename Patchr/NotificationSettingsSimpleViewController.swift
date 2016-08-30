//
//  NotificationSettingsViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationSettingsSimpleViewController: UITableViewController {

    let userDefaults = {
        NSUserDefaults.standardUserDefaults()
    }()

    /* Notifications */

    var notificationSettingsCell = AirTableViewCell()
    var soundEffectsCell = AirTableViewCell()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewWillAppear(animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {
        Reporting.screen("NotificationSettings")

        self.navigationItem.title = "Notifications"
        self.view.accessibilityIdentifier = View.NotificationSettings

        self.tableView = UITableView(frame: self.tableView.frame, style: .Grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.notificationSettingsCell.textLabel?.text = "Notification settings"
        self.soundEffectsCell.textLabel!.text = "Play sound effects"
        
        self.soundEffectsCell.accessoryView = makeSwitch(.SoundEffects, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundEffects")))
    }

    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == Setting.SoundEffects.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("SoundEffects"))
            }
        }
    }

    func makeSwitch(notificationType: Setting, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: #selector(NotificationSettingsSimpleViewController.toggleAction(_:)), forControlEvents: UIControlEvents.ValueChanged)
        switchView.on = state
        return switchView
    }
}

extension NotificationSettingsSimpleViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        if selectedCell == self.notificationSettingsCell {
            UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 1
            case 1: return 1
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                return self.notificationSettingsCell
            case 1:
                return self.soundEffectsCell
            default: fatalError("Unknown section")
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return "Notifications".uppercaseString
            case 1: return "Sound".uppercaseString
            default: fatalError("Unknown section")
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}