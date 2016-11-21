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
        UserDefaults.standard
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

    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
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

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.notificationSettingsCell.textLabel?.text = "Notification settings"
        self.soundEffectsCell.textLabel!.text = "Play sound effects"
        
        self.soundEffectsCell.accessoryView = makeSwitch(notificationType: .playSoundEffects, state: userDefaults.bool(forKey: PatchrUserDefaultKey(subKey: "SoundEffects")))
    }

    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == Setting.playSoundEffects.rawValue {
                userDefaults.set(switcher.isOn, forKey: PatchrUserDefaultKey(subKey: "SoundEffects"))
            }
        }
    }

    func makeSwitch(notificationType: Setting, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: #selector(NotificationSettingsSimpleViewController.toggleAction(sender:)), for: UIControlEvents.valueChanged)
        switchView.isOn = state
        return switchView
    }
}

extension NotificationSettingsSimpleViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        if selectedCell == self.notificationSettingsCell {
            UIApplication.shared.openURL(NSURL(string:UIApplicationOpenSettingsURLString)! as URL)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 1
            case 1: return 1
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                return self.notificationSettingsCell
            case 1:
                return self.soundEffectsCell
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return "Notifications".uppercased()
            case 1: return "Sound".uppercased()
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}
