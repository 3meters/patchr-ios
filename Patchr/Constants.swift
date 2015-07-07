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
let BING_ACCESS_KEY: String = "bNm8LpZdJma/cbJdDiwHq+TGwzVF7nW+QF9vWdPh/Rg"
let NAMESPACE: String = "com.3meters.patchr.ios."
let CREATIVE_SDK_CLIENT_ID = "924463f8481c4941a773fc9610fac9dd"
let CREATIVE_SDK_CLIENT_SECRET = "e2cc5494-911d-4c66-a2b4-cc9ebab420ab"

public struct Colors {
    static let accentColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0.75), blue: CGFloat(1), alpha: CGFloat(1))
    static let brandColor: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.55), blue: CGFloat(0), alpha: CGFloat(1))
    static let brandColorLight: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.718), blue: CGFloat(0.302), alpha: CGFloat(1))
    static let brandColorDark: UIColor = UIColor(red: CGFloat(0.93), green: CGFloat(0.42), blue: CGFloat(0), alpha: CGFloat(1))
    static let windowColor: UIColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(1))
    static let hintColor: UIColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1))
}

public struct Events {
    static let LikeDidChange = "LikeDidChange"
    static let WatchDidChange = "WatchDidChange"
}