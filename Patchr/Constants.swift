//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

let pageSizeDefault = 20
let pageSizeNearby = 50
let pageSizeExplore = 20
let pageSizeNotifications = 20

let Device = UIDevice.currentDevice()

let iosVersion = NSString(string: Device.systemVersion).doubleValue
let IOS9 = iosVersion >= 9
let IOS8 = iosVersion >= 8
let IOS7 = iosVersion >= 7 && iosVersion < 8

let SCREEN_NARROW = (UIScreen.mainScreen().bounds.size.width == 320)
let PIXEL_SCALE: CGFloat = UIScreen.mainScreen().scale
let SPACER_WIDTH: CGFloat = 12
let TIMEOUT_REQUEST: Int = 10   // Seconds

let URI_PROXIBASE_SEARCH_IMAGES: String = "https://api.datamarket.azure.com/Bing/Search/v1"
let NAMESPACE: String = "com.3meters.patchr.ios."
let CELL_IDENTIFIER = "cell_identifier"

func PatchrUserDefaultKey(subKey: String) -> String {
    return NAMESPACE + subKey
}

public struct Colors {
    static let accentColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0.75), blue: CGFloat(1), alpha: CGFloat(1))
    static let brandColor: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.55), blue: CGFloat(0), alpha: CGFloat(1))
    static let brandColorLight: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.718), blue: CGFloat(0.302), alpha: CGFloat(1))
    static let brandColorDark: UIColor = UIColor(red: CGFloat(0.93), green: CGFloat(0.42), blue: CGFloat(0), alpha: CGFloat(1))
    static let windowColor: UIColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(1))
    static let hintColor: UIColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1))
    static let gray95pcntColor: UIColor = UIColor(red: CGFloat(0.95), green: CGFloat(0.95), blue: CGFloat(0.95), alpha: CGFloat(1))
    static let gray90pcntColor: UIColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(1))
}

public struct Events {
    static let LikeDidChange = "LikeDidChange"
    static let WatchDidChange = "WatchDidChange"
}

/*
* Any photo from the device (camera, gallery) is store in s3 and source = aircandi.images|users
* Any search photo is not stored in s3 and source = generic. (Deprecated)
* Any search photo is stored in s3 and source = aircandi.images|users
* Any patch photo from foursquare stays there and photo.source = foursquare.
*/
public struct PhotoSource {
    static let aircandi_images = "aircandi.images"
    static let aircandi_users  = "aircandi.users"
    static let aircandi        = "aircandi"
    static let foursquare     = "foursquare"
    static let google         = "google"
    static let resource       = "resource"
    static let bing           = "bing"
    static let generic        = "generic"
}
