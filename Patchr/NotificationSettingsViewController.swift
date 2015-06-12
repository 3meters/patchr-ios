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
    @IBOutlet weak var patchesOwnsCell: UITableViewCell!
    @IBOutlet weak var sharingMessagesCell: UITableViewCell!
    @IBOutlet weak var likePatchesCell: UITableViewCell!
    @IBOutlet weak var likeMessagesCell: UITableViewCell!
    @IBOutlet weak var soundEffectsCell: UITableViewCell!
    @IBOutlet weak var soundNotificationsCell: UITableViewCell!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.patchesNearbyCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.patchesWatchingCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.patchesOwnsCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.sharingMessagesCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.likePatchesCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.likeMessagesCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.soundEffectsCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.soundNotificationsCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)        
        
        self.patchesNearbyCell.accessoryView = makeSwitch(.MessagesForPatchesNearby, state: userDefaults.boolForKey("com.3meters.patchr.ios.MessagesForPatchesNearby"))
        self.patchesWatchingCell.accessoryView = makeSwitch(.MessagesForPatchesWatching, state: userDefaults.boolForKey("com.3meters.patchr.ios.MessagesForPatchesWatching"))
        self.patchesOwnsCell.accessoryView = makeSwitch(.MessagesForPatchesOwns, state: userDefaults.boolForKey("com.3meters.patchr.ios.MessagesForPatchesOwns"))
        self.sharingMessagesCell.accessoryView = makeSwitch(.MessagesSharing, state: userDefaults.boolForKey("com.3meters.patchr.ios.MessagesSharing"))
        self.likePatchesCell.accessoryView = makeSwitch(.LikePatch, state: userDefaults.boolForKey("com.3meters.patchr.ios.LikePatch"))
        self.likeMessagesCell.accessoryView = makeSwitch(.LikeMessage, state: userDefaults.boolForKey("com.3meters.patchr.ios.LikeMessage"))
        self.soundEffectsCell.accessoryView = makeSwitch(.SoundEffects, state: userDefaults.boolForKey("com.3meters.patchr.ios.SoundEffects"))
        self.soundNotificationsCell.accessoryView = makeSwitch(.SoundForNotifications, state: userDefaults.boolForKey("com.3meters.patchr.ios.SoundForNotifications"))
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func toggle(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == NotificationType.MessagesForPatchesNearby.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.MessagesForPatchesNearby")
            }
            else if switcher.tag == NotificationType.MessagesForPatchesWatching.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.MessagesForPatchesWatching")
            }
            else if switcher.tag == NotificationType.MessagesForPatchesOwns.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.MessagesForPatchesOwns")
            }
            else if switcher.tag == NotificationType.MessagesSharing.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.MessagesSharing")
            }
            else if switcher.tag == NotificationType.LikePatch.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.LikePatch")
            }
            else if switcher.tag == NotificationType.LikeMessage.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.LikeMessage")
            }
            else if switcher.tag == NotificationType.SoundEffects.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.SoundEffects")
            }
            else if switcher.tag == NotificationType.SoundForNotifications.rawValue {
                userDefaults.setBool(switcher.on, forKey: "com.3meters.patchr.ios.SoundForNotifications")
            }
        }
    }
    
    func makeSwitch(notificationType: NotificationType, state: Bool = false) -> UISwitch {
        var switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: "toggle:", forControlEvents: UIControlEvents.ValueChanged)
        switchView.on = state
        return switchView
    }
}

enum NotificationType: Int {
    case MessagesForPatchesNearby
    case MessagesForPatchesWatching
    case MessagesForPatchesOwns
    case MessagesSharing
    case LikePatch
    case LikeMessage
    case SoundEffects
    case SoundForNotifications
}