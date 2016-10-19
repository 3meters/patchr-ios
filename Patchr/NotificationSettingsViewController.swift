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
        UserDefaults.standard
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

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
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
        
        self.typeAllCell.selectionStyle = .none
        self.typeMessagesOnlyCell.selectionStyle = .none
        self.typeNoneCell.selectionStyle = .none

        let notificationType = userDefaults.string(forKey: PatchrUserDefaultKey(subKey: "NotificationType"))
        self.typeAllCell.accessoryType = notificationType == "all" ? .checkmark : .none
        self.typeMessagesOnlyCell.accessoryType = notificationType == "messages_only" ? .checkmark : .none
        self.typeNoneCell.accessoryType = notificationType == "none" ? .checkmark : .none
        self.soundCell.accessoryView = makeSwitch(notificationType: .SoundForNotifications, state: userDefaults.bool(forKey: PatchrUserDefaultKey(subKey: "SoundForNotifications")))
        self.vibrateCell.accessoryView = makeSwitch(notificationType: .VibrateForNotifications, state: userDefaults.bool(forKey: PatchrUserDefaultKey(subKey: "VibrateForNotifications")))
        self.soundEffectsCell.accessoryView = makeSwitch(notificationType: .SoundEffects, state: userDefaults.bool(forKey: PatchrUserDefaultKey(subKey: "SoundEffects")))
    }

    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == Setting.SoundForNotifications.rawValue {
                userDefaults.set(switcher.isOn, forKey: PatchrUserDefaultKey(subKey: "SoundForNotifications"))
            }
            else if switcher.tag == Setting.VibrateForNotifications.rawValue {
                userDefaults.set(switcher.isOn, forKey: PatchrUserDefaultKey(subKey: "VibrateForNotifications"))
            }
            else if switcher.tag == Setting.SoundEffects.rawValue {
                userDefaults.set(switcher.isOn, forKey: PatchrUserDefaultKey(subKey: "SoundEffects"))
            }
        }
    }

    func makeSwitch(notificationType: Setting, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: #selector(NotificationSettingsViewController.toggleAction(sender:)), for: UIControlEvents.valueChanged)
        switchView.isOn = state
        return switchView
    }
}

extension NotificationSettingsViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        self.typeAllCell.accessoryType = .none
        self.typeMessagesOnlyCell.accessoryType = .none
        self.typeNoneCell.accessoryType = .none
        selectedCell!.accessoryType = .checkmark
        
        if selectedCell == self.typeAllCell {
            userDefaults.set("all", forKey: PatchrUserDefaultKey(subKey: "NotificationType"))
        }
        else if selectedCell == self.typeMessagesOnlyCell {
            userDefaults.set("messages_only", forKey: PatchrUserDefaultKey(subKey: "NotificationType"))
        }
        else if selectedCell == self.typeNoneCell {
            userDefaults.set("none", forKey: PatchrUserDefaultKey(subKey: "NotificationType"))
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 3
            case 1: return 2
            case 2: return 1
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return "Send me push notifications for".uppercased()
            case 1: return "Notification type".uppercased()
            case 2: return "Sound".uppercased()
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}

enum Setting: Int {
    case SoundForNotifications
    case VibrateForNotifications
    case SoundEffects
}
