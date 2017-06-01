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

	static func isImageCached(key: String, then: @escaping (Bool) -> ()) {
		SDImageCache.shared().diskImageExists(withKey: key) { exists in
			then(exists)
		}
	}

	static func storeImageToCache(image: UIImage, key: String, then: (() -> Void)? = nil) {
		SDImageCache.shared().store(image, forKey: key, toDisk: true) { then?() }
	}

	static func storeImageDataToCache(imageData: Data, key: String, then: (() -> Void)? = nil) {
		DispatchQueue.global(qos: .userInitiated).async {
			SDImageCache.shared().storeImageData(toDisk: imageData, forKey: key)    // Synchronous
            then?()
		}
	}
    
    static func storeImageDataToCacheSync(imageData: Data, key: String) {
        SDImageCache.shared().storeImageData(toDisk: imageData, forKey: key)    // Synchronous
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
					, insideRect: CGRect(x: 0, y: 0, width: Config.imageDimensionMax, height: Config.imageDimensionMax))
			image = image.resizeTo(size: rect.size)
		}
		else {
			image = image.normalizedImage()
		}
		return image
	}
    
    static func readStorageBucket() -> String {
        let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!) as? [String: AnyObject]
        let storageBucket = dict!["STORAGE_BUCKET"] as! String
        return storageBucket
    }
}

class ImageProxy {

	static func lookupSource(source: String) -> ImageSourceType {
		if source == GoogleStorage.imageSource {
			return GoogleImageSource()
		}
		return S3ImageSource()
	}

	static func url(photo: FirePhoto, category: String) -> URL {
		let dimension = (photo.width == nil || photo.width! >= photo.height!) ? ResizeDimension.width : ResizeDimension.height
		let imageSource = ImageProxy.lookupSource(source: photo.source!)
		let url = imageSource.url(prefix: photo.filename!, category: nil)
		return GooglePlusProxy.url(url: url, category: category, dimension: dimension)
	}
}

class GooglePlusProxy: ImageProxyType {
    
    static func url(url: String, category: String = SizeCategory.standard, dimension: ResizeDimension? = nil) -> URL {
        /*
         * - Used for images that are not currently stored in s3 like bing image search.
         * - Setting refresh to 60 minutes by default.
         */
        let encodedUrl = url.stringByAddingPercentEncodingForUrl()
        let size = ((category == SizeCategory.standard) ? 400 : 100) * Int(Config.pixelScale)
        let dimen = (dimension == ResizeDimension.width) ? "resize_w=\(size)" : "resize_h=\(size)"
        let path = "https://images-focus-opensocial.googleusercontent.com/gadgets/proxy?url=\(encodedUrl!)&container=focus&gadget=a&\(dimen)&no_expand=1&refresh=3600&rewriteMime=image/*"
        return URL(string: path)!
    }
}

class CloudinaryProxy: ImageProxyType {

	static func url(url: String, category: String = SizeCategory.standard, dimension: ResizeDimension? = nil) -> URL {
		let encodedUrl = url.stringByAddingPercentEncodingForUrl()
		let size = (category == SizeCategory.standard) ? 400 : 100
		let dimen = (category == SizeCategory.profile) ? "w_\(size),h_\(size)" : "w_\(size)"
		let path = "https://res.cloudinary.com/patchr/image/fetch/\(dimen),dpr_\(Config.pixelScale),q_auto,c_fill/\(encodedUrl!)"
		return URL(string: path)!
	}
}

class S3ImageSource: ImageSourceType {
	func url(prefix: String, category: String? = nil) -> String {
		return "https://s3-us-west-2.amazonaws.com/aircandi-images/\(prefix)"
	}
}

class GoogleImageSource: ImageSourceType {
	func url(prefix: String, category: String? = nil) -> String {
        let storageBucket = ImageUtils.readStorageBucket()
		return "https://firebasestorage.googleapis.com/v0/b/\(storageBucket)/o/images%2F\(prefix)?alt=media"
	}
}

enum ResizeDimension {
	case height
	case width
}

public struct SizeCategory {
	static let profile = "profile"
	static let standard = "standard"
}

protocol ImageSourceType {
	func url(prefix: String, category: String?) -> String
}

protocol ImageProxyType {
	static func url(url: String, category: String, dimension: ResizeDimension?) -> URL
}
