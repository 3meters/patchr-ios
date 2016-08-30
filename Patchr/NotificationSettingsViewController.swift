//
//  NotificationSettingsViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationSettingsViewController: UITableViewController {

    let userDefaults = {
        NSUserDefaults.standardUserDefaults()
    }()

    /* Notifications */

    var typeAllCell = AirTableViewCell()
    var typeMessagesOnlyCell = AirTableViewCell()
    var typeNoneCell = AirTableViewCell()
    var soundCell = AirTableViewCell()
    var vibrateCell = AirTableViewCell()
    var soundEffectsCell = AirTableViewCell()

    var typeValue: String? = nil

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

        self.typeAllCell.textLabel?.text = "Activity of any kind"
        self.typeMessagesOnlyCell.textLabel?.text = "Only messages"
        self.typeNoneCell.textLabel?.text = "Nothing (push notifications off)"
        self.soundCell.textLabel?.text = "Sound"
        self.vibrateCell.textLabel?.text = "Vibrate"
        self.soundEffectsCell.textLabel!.text = "Play sound effects"
        
        self.typeAllCell.selectionStyle = .None
        self.typeMessagesOnlyCell.selectionStyle = .None
        self.typeNoneCell.selectionStyle = .None

        let notificationType = userDefaults.stringForKey(PatchrUserDefaultKey("NotificationType"))
        self.typeAllCell.accessoryType = notificationType == "all" ? .Checkmark : .None
        self.typeMessagesOnlyCell.accessoryType = notificationType == "messages_only" ? .Checkmark : .None
        self.typeNoneCell.accessoryType = notificationType == "none" ? .Checkmark : .None
        self.soundCell.accessoryView = makeSwitch(.SoundForNotifications, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundForNotifications")))
        self.vibrateCell.accessoryView = makeSwitch(.VibrateForNotifications, state: userDefaults.boolForKey(PatchrUserDefaultKey("VibrateForNotifications")))
        self.soundEffectsCell.accessoryView = makeSwitch(.SoundEffects, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundEffects")))
    }

    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == Setting.SoundForNotifications.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("SoundForNotifications"))
            }
            else if switcher.tag == Setting.VibrateForNotifications.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("VibrateForNotifications"))
            }
            else if switcher.tag == Setting.SoundEffects.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("SoundEffects"))
            }
        }
    }

    func makeSwitch(notificationType: Setting, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: #selector(NotificationSettingsViewController.toggleAction(_:)), forControlEvents: UIControlEvents.ValueChanged)
        switchView.on = state
        return switchView
    }
}

extension NotificationSettingsViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        self.typeAllCell.accessoryType = .None
        self.typeMessagesOnlyCell.accessoryType = .None
        self.typeNoneCell.accessoryType = .None
        selectedCell!.accessoryType = .Checkmark
        
        if selectedCell == self.typeAllCell {
            userDefaults.setObject("all", forKey: PatchrUserDefaultKey("NotificationType"))
        }
        else if selectedCell == self.typeMessagesOnlyCell {
            userDefaults.setObject("messages_only", forKey: PatchrUserDefaultKey("NotificationType"))
        }
        else if selectedCell == self.typeNoneCell {
            userDefaults.setObject("none", forKey: PatchrUserDefaultKey("NotificationType"))
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 3
            case 1: return 2
            case 2: return 1
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0: return self.typeAllCell
                    case 1: return self.typeMessagesOnlyCell
                    case 2: return self.typeNoneCell
                    default: fatalError("Unknown row in section 0")
                }
            case 1:
                switch (indexPath.row) {
                    case 0: return self.soundCell
                    case 1: return self.vibrateCell
                    default: fatalError("Unknown row in section 1")
                }
            case 2:
                return self.soundEffectsCell
            default: fatalError("Unknown section")
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return "Send me push notifications for".uppercaseString
            case 1: return "Notification type".uppercaseString
            case 2: return "Sound".uppercaseString
            default: fatalError("Unknown section")
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}

enum Setting: Int {
    case SoundForNotifications
    case VibrateForNotifications
    case SoundEffects
}