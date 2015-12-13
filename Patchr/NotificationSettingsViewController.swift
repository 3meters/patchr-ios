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
    
    @IBOutlet weak var patchesNearbyCell: UITableViewCell!
    @IBOutlet weak var patchesWatchingCell: UITableViewCell!
    @IBOutlet weak var sharingMessagesCell: UITableViewCell!
    @IBOutlet weak var likeMessagesCell: UITableViewCell!
    @IBOutlet weak var soundEffectsCell: UITableViewCell!
    @IBOutlet weak var soundNotificationsCell: UITableViewCell!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.patchesNearbyCell.textLabel!.font = Theme.fontTextDisplay
        self.patchesWatchingCell.textLabel!.font = Theme.fontTextDisplay
        self.sharingMessagesCell.textLabel!.font = Theme.fontTextDisplay
        self.likeMessagesCell.textLabel!.font = Theme.fontTextDisplay
        self.soundEffectsCell.textLabel!.font = Theme.fontTextDisplay
        self.soundNotificationsCell.textLabel!.font = Theme.fontTextDisplay
        
        self.patchesNearbyCell.accessoryView = makeSwitch(.PatchesCreatedNearby, state: userDefaults.boolForKey(PatchrUserDefaultKey("PatchesCreatedNearby")))
        self.patchesWatchingCell.accessoryView = makeSwitch(.MessagesForPatchesWatching, state: userDefaults.boolForKey(PatchrUserDefaultKey("MessagesForPatchesWatching")))
        self.sharingMessagesCell.accessoryView = makeSwitch(.MessagesSharing, state: userDefaults.boolForKey(PatchrUserDefaultKey("MessagesSharing")))
        self.likeMessagesCell.accessoryView = makeSwitch(.LikeMessage, state: userDefaults.boolForKey(PatchrUserDefaultKey("LikeMessage")))
        self.soundEffectsCell.accessoryView = makeSwitch(.SoundEffects, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundEffects")))
        self.soundNotificationsCell.accessoryView = makeSwitch(.SoundForNotifications, state: userDefaults.boolForKey(PatchrUserDefaultKey("SoundForNotifications")))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("NotificationSettings")        
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func toggle(sender: AnyObject?) {
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
        switchView.addTarget(self, action: "toggle:", forControlEvents: UIControlEvents.ValueChanged)
        switchView.on = state
        return switchView
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