//
//  Extensions.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import AVFoundation

class ImageUtils {
    
    static let useGoogle = false
    
    static func url(prefix: String?, source: String?, category: String, google: Bool = false) -> URL? {
        
        guard prefix != nil && source != nil else {
            return nil
        }
		
        var path: String = ""
        var quality: Int = 75
        if Config.pixelScale >= 3 {
            quality = 25
        }
        else if Config.pixelScale >= 2 {
            quality = 50
        }
        
        let width = (category == SizeCategory.standard) ? 400 : 100
        if category == SizeCategory.profile {
            path = "https://3meters-images.imgix.net/\(prefix!)?w=\(width)&dpr=\(Config.pixelScale)&q=\(quality)&h=\(width)&fit=min&trim=auto"
        }
        else {
            path = "https://3meters-images.imgix.net/\(prefix!)?w=\(width)&dpr=\(Config.pixelScale)&q=\(quality)"
        }
		
        return URL(string: path)
    }
    
    static func imageCached(key: String, then: @escaping (Bool) -> ()) {
        SDImageCache.shared().diskImageExists(withKey: key) { exists in
            then(exists)
        }
    }
    
    static func storeImageToCache(image: UIImage, key: String, then: (() -> Void)? = nil) {
        SDImageCache.shared().store(image, forKey: key, toDisk: true) { then?() }
    }

    static func storeImageDataToCache(imageData: Data, key: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            SDImageCache.shared().storeImageData(toDisk: imageData, forKey: key)    // Synchronous
        }
    }

    static func imageFromDiskCache(key: String) -> UIImage? {
        return SDImageCache.shared().imageFromCache(forKey: key)
    }
    
    static func imageFromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    static func imageFromLayer(layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContext(layer.frame.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage!
    }
    
    static func prepareImage(image inImage: UIImage) -> UIImage {
        var image = inImage;
        let scalingNeeded = (image.size.width > Config.imageDimensionMax || image.size.height > Config.imageDimensionMax)
        if (scalingNeeded) {
            let rect: CGRect = AVMakeRect(aspectRatio: image.size
                , insideRect: CGRect(x:0, y:0, width: Config.imageDimensionMax, height: Config.imageDimensionMax))
            image = image.resizeTo(size: rect.size)
        }
        else {
            image = image.normalizedImage()
        }
        return image
    }
}

/* Only used for GooglePlusProxy */
enum ResizeDimension{
    case height
    case width
}

class Cloudinary {
    
    static func url(prefix: String, category: String = SizeCategory.standard) -> URL {
        let urlString = "https://s3-us-west-2.amazonaws.com/aircandi-images/\(prefix)".stringByAddingPercentEncodingForUrl()
        let width = (category == SizeCategory.standard) ? 400 : 100
        let dimen = (category == SizeCategory.profile) ? "w_\(width),h_\(width)" : "w_\(width)"
        let path = "https://res.cloudinary.com/patchr/image/fetch/\(dimen),dpr_\(Config.pixelScale),q_auto,c_fill/\(urlString!)"        
        return URL(string: path)!
    }
    
    static func url(prefix: String, params: String) -> URL {
        let urlString = "https://s3-us-west-2.amazonaws.com/aircandi-images/\(prefix)".stringByAddingPercentEncodingForUrl()
        let path = "https://res.cloudinary.com/patchr/image/fetch/\(params)/\(urlString!)"
        return URL(string: path)!
    }
}

class GooglePlusProxy {
    /*
	* - Used for images that are not currently stored in s3 like bing image search.
    * - Setting refresh to 60 minutes by default.
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
