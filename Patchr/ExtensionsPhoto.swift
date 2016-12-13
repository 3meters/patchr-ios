//
//  Extensions.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit

class PhotoUtils {
    
    static let useGoogle = false
    
    static func fallbackUrl(prefix: String) -> URL {
        return URL(string: "https://s3-us-west-2.amazonaws.com/aircandi-images/\(prefix)")!
    }
    
    static func url(prefix: String?, source: String?, category: String, google: Bool = false) -> URL? {
        
        guard prefix != nil && source != nil else {
            return nil
        }
		
        var path: String = ""
        var quality: Int = 75
        if PIXEL_SCALE >= 3 {
            quality = 25
        }
        else if PIXEL_SCALE >= 2 {
            quality = 50
        }
        
        if source == PhotoSource.aircandi_images {
            let width = (category == SizeCategory.standard) ? 400 : 100
            if google {
                let dimension = (category == SizeCategory.profile) ? ResizeDimension.width : ResizeDimension.height
                let imageUrl = PhotoUtils.fallbackUrl(prefix: prefix!).absoluteString
                path = GooglePlusProxy.convert(uri: imageUrl, size: width, dimension: dimension)
            }
            else {
                if category == SizeCategory.profile {
                    path = "https://3meters-images.imgix.net/\(prefix!)?w=\(width)&dpr=\(PIXEL_SCALE)&q=\(quality)&h=\(width)&fit=min&trim=auto"
                }
                else {
                    path = "https://3meters-images.imgix.net/\(prefix!)?w=\(width)&dpr=\(PIXEL_SCALE)&q=\(quality)"
                }
            }
        }
        else if source == PhotoSource.google {
            let width: CGFloat = CGFloat(IMAGE_DIMENSION_MAX) * PIXEL_SCALE
            if (prefix!.range(of: "?") != nil) {
                path = "\(prefix)&maxwidth=\(width)"
            }
            else {
                path = "\(prefix)?maxwidth=\(width)"
            }
        }
        else if source == PhotoSource.gravatar {
            let width: CGFloat = CGFloat(100) * PIXEL_SCALE
            path = "\(prefix)&s=\(width)"
        }
		
        return URL(string: path)
    }
}

/* Only used for GooglePlusProxy */
enum ResizeDimension{
    case height
    case width
}

class GooglePlusProxy {
    /*
	* Currently used for bing images only.
	*
    * Setting refresh to 60 minutes.
    */
    static func convert(uri: String, size: Int, dimension: ResizeDimension!) -> String {
        let encodedUrl = uri.stringByAddingPercentEncodingForUrl()
        if dimension == ResizeDimension.width {
            let converted = "https://images1-focus-opensocial.googleusercontent.com/gadgets/proxy?url=\(encodedUrl!)&container=focus&resize_w=\(size)&no_expand=1&refresh=3600"
            return converted
        }
        else {
            let converted = "https://images1-focus-opensocial.googleusercontent.com/gadgets/proxy?url=\(encodedUrl!)&container=focus&resize_h=\(size)&no_expand=1&refresh=3600"
            return converted
        }
    }
}
