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

private let iosVersion = NSString(string: Device.systemVersion).doubleValue

let IOS8 = iosVersion >= 8
let IOS7 = iosVersion >= 7 && iosVersion < 8

let SCREEN_NARROW = (UIScreen.mainScreen().bounds.size.width == 320)
let PIXEL_SCALE: CGFloat = UIScreen.mainScreen().scale
let SPACER_WIDTH: CGFloat = 12

let URI_PROXIBASE_SEARCH_IMAGES: String = "https://api.datamarket.azure.com/Bing/Search/v1/Image"
let BING_ACCESS_KEY: String = "bNm8LpZdJma/cbJdDiwHq+TGwzVF7nW+QF9vWdPh/Rg"