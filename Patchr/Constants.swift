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

let Device = UIDevice.current
let iosVersion = NSString(string: Device.systemVersion).doubleValue
let IOS9 = iosVersion >= 9
let IOS8 = iosVersion >= 8
let IOS7 = iosVersion >= 7 && iosVersion < 8
let APPLE_APP_ID = "983436323"
let GOOGLE_ANALYTICS_ID = "UA-33660954-6"
let BUNDLE_ID = "com.3meters.patchr.ios"
let KEYCHAIN_GROUP = "7542324V6B.\(BUNDLE_ID)"// Team id + bundle id
let BUGSNAG_KEY = "d1313b8d5fc14d937419406f33fd4c01"

let SCREEN_NARROW = (UIScreen.main.bounds.size.width == 320)
let SCREEN_320 = (UIScreen.main.bounds.size.width == 320)// iphone 4s
let SCREEN_375 = (UIScreen.main.bounds.size.width == 375)// iphone 6
let PIXEL_SCALE = CGFloat(UIScreen.main.scale)
let THIRD_PARTY_AUTH_ENABLED = false

let TIMEOUT_REQUEST: Int = 10    // Seconds
let BLOCKING = false

let IMAGE_DIMENSION_MAX = CGFloat(1600)
let CONTENT_WIDTH_MAX = CGFloat(462)
let SIDE_MENU_WIDTH = CGFloat(260)
let NAVIGATION_DRAWER_WIDTH = min(CGFloat(UIScreen.main.bounds.size.width - 96), 384)

let URI_PROXIBASE_SEARCH_IMAGES = "https://api.cognitive.microsoft.com/bing/v5.0"
let NAMESPACE = "com.3meters.patchr.ios."
let CELL_IDENTIFIER = "cell"
let COGNITO_POOLID = "us-east-1:ff1976dc-9c27-4046-a59f-7dd43355869b"

var LOG_TIMERS = false
var MailComposer: MFMailComposeViewController? = MFMailComposeViewController()

let spacerFlex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
let spacerFixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)

func PatchrUserDefaultKey(subKey: String) -> String {
    return NAMESPACE + subKey
}

enum AppConfiguration {
    case debug
    case testFlight
    case appStore
}

struct Config {
    /* This is private because the use of 'appConfiguration' is preferred. */
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    // This can be used to add debug statements.
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

    static let DidFetchQuery = "DidFetchQuery"
    static let ImageNotFound = "ImageNotFound"
    static let LocationWasDenied = "LocationWasDenied"
    static let LocationWasAllowed = "LocationWasAllowed"
    static let DidReceiveRemoteNotification = "DidReceiveRemoteNotification"
}

public struct Schema {
    static let ENTITY_BEACON = "beacon"
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
