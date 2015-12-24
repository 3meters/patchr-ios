//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

let pageSizeDefault         = 20
let pageSizeNearby          = 50
let pageSizeExplore         = 20
let pageSizeNotifications   = 20

let Device				= UIDevice.currentDevice()
let iosVersion			= NSString(string: Device.systemVersion).doubleValue
let IOS9				= iosVersion >= 9
let IOS8				= iosVersion >= 8
let IOS7				= iosVersion >= 7 && iosVersion < 8
let APPLE_APP_ID		= "983436323"
let GOOGLE_ANALYTICS_ID	= "UA-33660954-6"
let BUNDLE_ID			= "com.3meters.patchr.ios"
let KEYCHAIN_GROUP		= "7542324V6B.\(BUNDLE_ID)"	// Team id + bundle id

let SCREEN_NARROW				= (UIScreen.mainScreen().bounds.size.width == 320)
let SCREEN_320					= (UIScreen.mainScreen().bounds.size.width == 320)
let SCREEN_375					= (UIScreen.mainScreen().bounds.size.width == 375)
let PIXEL_SCALE: CGFloat		= UIScreen.mainScreen().scale
let THIRD_PARTY_AUTH_ENABLED	= false

let TIMEOUT_REQUEST: Int    = 10   // Seconds

let IMAGE_DIMENSION_MAX	: CGFloat = 1280
let CONTENT_WIDTH_MAX	: CGFloat = 462

let URI_PROXIBASE_SEARCH_IMAGES: String = "https://api.datamarket.azure.com/Bing/Search/v1"
let NAMESPACE: String                   = "com.3meters.patchr.ios."
let CELL_IDENTIFIER                     = "cell"
let COGNITO_POOLID                      = "us-east-1:ff1976dc-9c27-4046-a59f-7dd43355869b"

func PatchrUserDefaultKey(subKey: String) -> String {
    return NAMESPACE + subKey
}

public struct Events {
    static let LikeDidChange        = "LikeDidChange"
    static let WatchDidChange       = "WatchDidChange"
	static let PhotoDidChange       = "PhotoDidChange"
	static let PhotoViewHasFocus    = "PhotoViewHasFocus"
	static let BindingComplete		= "BindingComplete"
	static let ImageNotFound		= "ImageNotFound"
}

public struct Schema {
    static let ENTITY_BEACON        = "beacon"
    static let ENTITY_MESSAGE       = "message"
    static let ENTITY_NOTIFICATION  = "notification"
    static let ENTITY_PATCH         = "patch"
    static let ENTITY_PLACE         = "place"
    static let ENTITY_USER          = "user"
    static let PHOTO                = "photo"
    static let LINK                 = "link"
}

public struct AuthProvider {
	static let FACEBOOK				= "facebook"
	static let GOOGLE				= "google"
	static let PROXIBASE			= "proxibase"
}

/*
* Any photo from the device (camera, gallery) is store in s3 and source = aircandi.images|users
* Any search photo is not stored in s3 and source = generic. (Deprecated)
* Any search photo is stored in s3 and source = aircandi.images|users
* Any patch photo from foursquare stays there and photo.source = foursquare.
*/
public struct PhotoSource {
    static let aircandi_images  = "aircandi.images"
    static let gravatar         = "gravatar"
    static let google           = "google"
    static let resource         = "resource"
    static let bing             = "bing"
    static let generic          = "generic"
	static let facebook			= "facebook"
}

public struct SizeCategory {
    static let profile          = "profile"
    static let thumbnail        = "thumbnail"
    static let standard         = "standard"
}

