//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI

typealias CompletionBlock = (_ response: Any?, _ error: NSError?) -> Void

let APPLE_APP_ID = "983436323"
let GOOGLE_ANALYTICS_ID = "UA-33660954-6"
let BUNDLE_ID = "com.3meters.patchr.ios"
let KEYCHAIN_GROUP = "7542324V6B.\(BUNDLE_ID)"// Team id + bundle id
let BUGSNAG_KEY = "d1313b8d5fc14d937419406f33fd4c01"

let THIRD_PARTY_AUTH_ENABLED = false
let TIMEOUT_REQUEST: Int = 10    // Seconds
let BLOCKING = false
let debugAuth = true

let URI_PROXIBASE_SEARCH_IMAGES = "https://api.cognitive.microsoft.com/bing/v5.0"
let NAMESPACE = "com.3meters.patchr.ios."
let CELL_IDENTIFIER = "cell"
let COGNITO_POOLID = "us-east-1:ff1976dc-9c27-4046-a59f-7dd43355869b"

var LOG_TIMERS = false
var MailComposer: MFMailComposeViewController? = MFMailComposeViewController()

let spacerFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
let spacerFixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)

func PerUserKey(key: String) -> String {
    guard let userId = UserController.instance.userId else {
        fatalError("PerUserKey requires an authenticated user")
    }
    return "\(userId).\(key)"
}

enum AppConfiguration {
    case debug
    case testFlight
    case appStore
}

struct Config {

    static let device = UIDevice.current
    static let iosVersion = NSString(string: device.systemVersion).doubleValue
    static let iOS9 = iosVersion >= 9
    static let iOS8 = iosVersion >= 8
    static let iOS7 = iosVersion >= 7 && iosVersion < 8

    static let widthNarrow = (UIScreen.main.bounds.size.width == 320)
    static let width320 = (UIScreen.main.bounds.size.width == 320)// iphone 4s
    static let width375 = (UIScreen.main.bounds.size.width == 375)// iphone 6
    static let pixelScale = CGFloat(UIScreen.main.scale)
    
    static let imageDimensionMax = CGFloat(1600)
    static let contentWidthMax = CGFloat(462)
    static let sideMenuWidth = CGFloat(260)
    
    static var navigationDrawerWidth: CGFloat {
        if widthNarrow {
            return CGFloat(300)
        }
        return min(CGFloat(UIScreen.main.bounds.size.width - 96), CGFloat(384))
    }

    /* This is private because the use of 'appConfiguration' is preferred. */
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    static func appState() -> String {
        let appState = (UIApplication.shared.applicationState == .background)
            ? "background" : (UIApplication.shared.applicationState == .active)
            ? "active" : "inactive"
        return appState
    }
    
    /* This can be used to add debug statements. */
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    static var appConfiguration: AppConfiguration {
        if isDebug {
            return .debug
        }
        else if isTestFlight {
            return .testFlight
        }
        else {
            return .appStore
        }
    }
}

/*
 * Old preferences - sigh
 * - com.3meters.patchr.ios.SoundEffects
 * - com.3meters.patchr.ios.SoundForNotifications
 * - com.3meters.patchr.ios.VibrateForNotifications
 * - com.3meters.patchr.ios.NotificationType
 * - com.3meters.patchr.ios.enableDevModeAction
 * - com.3meters.patchr.ios.statusBarHidden
 * - firstLaunch = true/false
 * - user_email = string
 * - $groupId = $channelId
 * - group_id = $groupId
 * - user_id = $userId
 * - com.3meters.patchr.ios.recent.searches = [String]
 */

public struct Prefs {
    
    /* Per device */
    static let firstLaunch = "first_launch"
    static let lastUserEmail = "last_user_email"
    
    /* Per user */
    static let soundEffects = "sound_effects"
    static let lastGroupId = "last_group_id"
    static let lastChannelIds = "last_channel_ids"
    static let searchHistory = "search_history"
    
    /* Developer */
    static let developerMode = "developer_mode"
    static let statusBarHidden = "status_bar_hidden"
}

public struct Events {
    static let ChannelDidSwitch = "ChannelDidSwitch"
    static let ChannelDidUpdate = "ChannelDidUpdate"
    static let GroupDidSwitch = "GroupDidSwitch"
    static let GroupDidUpdate = "GroupDidUpdate"
    static let MessageDidUpdate = "MessageDidUpdate"
    static let PhotoDidChange = "PhotoDidChange"
    static let PhotoRemoved = "PhotoRemoved"
    static let UserDidSwitch = "UserDidSwitch"
    static let StateInitialized = "StateInitialized"
    static let UnreadChange = "UnreadChange"
    static let LeftDidClose = "LeftDidClose"
    static let LeftWillOpen = "LeftWillOpen"

    static let DidFetchQuery = "DidFetchQuery"
    static let ImageNotFound = "ImageNotFound"
    static let LocationWasDenied = "LocationWasDenied"
    static let LocationWasAllowed = "LocationWasAllowed"
    static let DidReceiveRemoteNotification = "DidReceiveRemoteNotification"
}

public struct Schema {
    static let ENTITY_MESSAGE = "message"
    static let ENTITY_PATCH = "patch"
    static let ENTITY_USER = "user"
}

/*
* Any photo from the device (camera, gallery) is store in s3 and source = aircandi.images|users
* Any search photo is not stored in s3 and source = generic. (Deprecated)
* Any search photo is stored in s3 and source = aircandi.images|users
* Any patch photo from foursquare stays there and photo.source = foursquare.
*/

public struct PhotoSource {
    static let aircandi_images = "aircandi.images"
    static let gravatar = "gravatar"
    static let google = "google"
    static let resource = "resource"
    static let bing = "bing"
    static let generic = "generic"
    static let facebook = "facebook"
}

public struct SizeCategory {
    static let profile = "profile"
    static let thumbnail = "thumbnail"
    static let standard = "standard"
}
