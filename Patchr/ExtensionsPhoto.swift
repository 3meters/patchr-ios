//
//  Extensions.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class PhotoUtils {
    
    static func url(prefix: String, source: String, size: Int?, frameWidth: Int = Int(IMAGE_DIMENSION_MAX)) -> NSURL {
        var path: String = ""
        var quality: Int = 75
        if PIXEL_SCALE >= 3 {
            quality = 25
        }
        else if PIXEL_SCALE >= 2 {
            quality = 50
        }
        
        if source == PhotoSource.aircandi_images || source == PhotoSource.aircandi {
            var width = size != nil ? size : 400
            path = "https://3meters-images.imgix.net/\(prefix)?w=\(width!)&dpr=\(PIXEL_SCALE)&q=\(quality)&auto=enhance"
        }
        else if source == PhotoSource.aircandi_users {
            var width = size != nil ? size : 100
            path = "https://3meters-users.imgix.net/\(prefix)?w=\(width!)&h=\(width!)&fit=min&dpr=\(PIXEL_SCALE)&q=\(quality)&auto=enhance"
        }
        else if source == PhotoSource.google {
            var width: CGFloat = CGFloat(frameWidth) * PIXEL_SCALE
            if (prefix.rangeOfString("?") != nil) {
                path = "\(prefix)&maxwidth=\(width)"
            }
            else {
                path = "\(prefix)?maxwidth=\(width)"
            }
        }
        else if source == PhotoSource.gravatar {
            var width: CGFloat = CGFloat(100) * PIXEL_SCALE
            path = "\(prefix)&s=\(width)"
        }
        
        return NSURL(string: path)!
    }
}

enum ResizeDimension{
    case height
    case width
}

class GooglePlusProxy {
    /*
    * Setting refresh to 60 minutes.
    */
    static func convert(uri: String, size: Int, dimension: ResizeDimension!) -> String {
        
        let queryString = (CFURLCreateStringByAddingPercentEscapes(nil, uri as NSString, nil, ":/?@!$&'()*+,;=" as NSString, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) as NSString) as String
        if dimension == ResizeDimension.width {
            var converted = "https://images1-focus-opensocial.googleusercontent.com/gadgets/proxy?url=\(queryString)&container=focus&resize_w=\(size)&no_expand=1&refresh=3600"
            return converted
        }
        else {
            var converted = "https://images1-focus-opensocial.googleusercontent.com/gadgets/proxy?url=\(queryString)&container=focus&resize_h=\(size)&no_expand=1&refresh=3600"
            return converted
        }
    }
}