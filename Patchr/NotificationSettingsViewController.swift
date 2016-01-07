//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class NotificationSettingsViewController: UITableViewController {    
    
    let userDefaults = { NSUserDefaults.standardUserDefaults() }()
    
    var patchesNearbyCell		= AirTableViewCell()
    var patchesWatchingCell		= AirTableViewCell()
    var sharingMessagesCell		= AirTableViewCell()
    var likeMessagesCell		= AirTableViewCell()
    var soundEffectsCell		= AirTableViewCell()
    var soundNotificationsCell	= AirTableViewCell()
    
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
		setScreenName("NotificationSettings")
		
		self.navigationItem.title = "Notifications"
		
		self.tableView = UITableView(frame: self.tableView.frame, style: .Grouped)
		self.tableView.rowHeight = 48
		self.tableView.tableFooterView = UIView()
		self.tableView.backgroundColor = Colors.gray95pcntColor
		self.tableView.sectionFooterHeight = 0
		
		self.patchesNearbyCell.textLabel?.text = "Created Nearby"
		self.patchesWatchingCell.textLabel?.text = "To Patches I\'m Watching"
		self.sharingMessagesCell.textLabel?.text = "Sharing a Patch or Message"
		self.likeMessagesCell.textLabel?.text = "Like My Messages"
		self.soundEffectsCell.textLabel?.text = "Notifications"
		self.soundNotificationsCell.textLabel?.text = "Sound Effects"
		
		self.patchesNearbyCell.accessoryView = makeSwitch(.PatchesCreatedNearby, state: userDefaults.boolForKey(PatchrUserDefaultKey("PatchesCreatedNearby")))
		self.patchesWatchingCell.accessoryView = makeSwitch(.MessagesForPatchesWatching, state: userDefaults.boolForKey(PatchrUserDefaultKey("MessagesForPatchesWatching")))
		self.sharingMessagesCell.accessoryView = makeSwitch(.MessagesSharing, state: userDefaults.boolForKey(PatchrUserDefaultKey("MessagesSharing")))
		self.likeMessagesCell.accessoryView = makeSwitch(.LikeMessage, state: userDefaults.boolForKey(PatchrUserDefaultKey("LikeMessage")))
		self.soundEffectsCell.accessoryView = makeSwitch(.SoundEffects, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundEffects")))
		self.soundNotificationsCell.accessoryView = makeSwitch(.SoundForNotifications, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundForNotifications")))
	}
	
    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == NotificationType.PatchesCreatedNearby.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("PatchesCreatedNearby"))
            }
            else if switcher.tag == NotificationType.MessagesForPatchesWatching.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("MessagesForPatchesWatching"))
            }
            else if switcher.tag == NotificationType.MessagesSharing.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("MessagesSharing"))
            }
            else if switcher.tag == NotificationType.LikeMessage.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("LikeMessage"))
            }
            else if switcher.tag == NotificationType.SoundEffects.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("SoundEffects"))
            }
            else if switcher.tag == NotificationType.SoundForNotifications.rawValue {
                userDefaults.setBool(switcher.on, forKey: PatchrUserDefaultKey("SoundForNotifications"))
            }
        }
    }
    
    func makeSwitch(notificationType: NotificationType, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: "toggleAction:", forControlEvents: UIControlEvents.ValueChanged)
        switchView.on = state
        return switchView
    }
}

extension NotificationSettingsViewController {
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 4
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch(section) {
			case 0: return 1
			case 1: return 2
			case 2: return 1
			case 3: return 2
			default: fatalError("Unknown number of sections")
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		switch(indexPath.section) {
			case 0:
				switch(indexPath.row) {
					case 0: return self.patchesNearbyCell
					default: fatalError("Unknown row in section 0")
				}
			case 1:
				switch(indexPath.row) {
					case 0: return self.patchesWatchingCell
					case 1: return self.sharingMessagesCell
					default: fatalError("Unknown row in section 1")
				}
			case 2:
				switch(indexPath.row) {
					case 0: return self.likeMessagesCell
					default: fatalError("Unknown row in section 2")
				}
			case 3:
				switch(indexPath.row) {
					case 0: return self.soundEffectsCell
					case 1: return self.soundNotificationsCell
					default: fatalError("Unknown row in section 3")
				}
			default: fatalError("Unknown section")
		}
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch(section) {
			case 0: return "Patches".uppercaseString
			case 1: return "Messages".uppercaseString
			case 2: return "Likes".uppercaseString
			case 3: return "Sounds".uppercaseString
			default: fatalError("Unknown section")
		}
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 48
	}
}

enum NotificationType: Int {
    case PatchesCreatedNearby
    case MessagesForPatchesWatching
    case MessagesSharing
    case LikeMessage
    case SoundEffects
    case SoundForNotifications
}