//
//  Extensions.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class PhotoUtils {
    
    static func url(prefix: String, source: String) -> NSURL {
        var path: String = ""
        
        if source == PhotoSource.aircandi_images {
            path = "http://aircandi-images.s3.amazonaws.com/\(prefix)"
        }
        else if source == PhotoSource.aircandi_users {
            path = "http://aircandi-users.s3.amazonaws.com/\(prefix)"
        }
        
        return NSURL(string: path)!
    }
    
    static func urlSized(url: NSURL, frameWidth: Int, frameHeight: Int, photoWidth: Int?, photoHeight: Int?) -> NSURL {
        /*
        * If photo comes with native height/width then use it otherwise
        * resize based on width.
        */
        if photoWidth != nil && photoHeight != nil {
            
            var photoAspectRatio: Float = Float(photoWidth!) / Float(photoHeight!)
            var frameAspectRatio: Float = Float(frameWidth) / Float(frameHeight)
            var dimension: ResizeDimension = (frameAspectRatio >= photoAspectRatio) ? ResizeDimension.width : ResizeDimension.height;
            var size: Int = (dimension == ResizeDimension.width) ? frameWidth : frameHeight
            var uriString = GooglePlusProxy.convert(url.absoluteString!, size: size, dimension: dimension)
            
            return NSURL(string: uriString)!
        }
        else {
            var uriString = GooglePlusProxy.convert(url.absoluteString!, size: frameWidth, dimension: ResizeDimension.width)
            return NSURL(string: uriString)!
        }
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