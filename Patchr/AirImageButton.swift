//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class AirImageButton: UIButton {

    var progress		: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var linkedPhotoUrl	: NSURL?
    var sizeCategory	= SizeCategory.thumbnail
    var progressAuto	= true
    
    private var progressStyle: UIActivityIndicatorViewStyle = .Gray
    private var progressSize: CGFloat = 12
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize(){
		self.progress.hidesWhenStopped = true
		self.progress.accessibilityIdentifier = "activity_image"
		addSubview(self.progress)
    }
	
    func setProgressSize(size: CGFloat) {
        self.progressSize = size
    }
    
    func setProgressStyle(style: UIActivityIndicatorViewStyle) {
        self.progress.activityIndicatorViewStyle = style
    }
    
    func startProgress(){
        self.progress.startAnimating()
    }
    
    func stopProgress(){
        self.progress.stopAnimating()
    }
	
	override func layoutSubviews() {
		super.layoutSubviews()
		self.progress.anchorInCenterWithWidth(self.progressSize, height: self.progressSize)
	}
	
    func isLinkedToPhoto(photo: Photo) -> Bool {
        if self.linkedPhotoUrl == nil {
            return false
        }
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory)
        return (linkedPhotoUrl!.absoluteString == photoUrl.absoluteString)
    }
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
        if photo.source == PhotoSource.resource {
            if animate {
                UIView.transitionWithView(self,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: {
                        self.setImage(UIImage(named: photo.prefix), forState:UIControlState.Normal)
                    },
                    completion: nil)
            }
            else {
                self.setImage(UIImage(named: photo.prefix), forState:UIControlState.Normal)
            }
            return
        }
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory)
        
        if photoUrl.absoluteString.isEmpty {
            let error = NSError(domain: "Photo error", code: 0, userInfo: [NSLocalizedDescriptionKey:"Photo has invalid source: \(photo.source!)"])
            self.imageCompletion(nil, error: error, cacheType: nil, url: nil, animate: animate)
            return
        }
        
        self.linkedPhotoUrl = photoUrl
        
        if progressAuto {
            startProgress()
        }
		
		let options: SDWebImageOptions = [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload]
		
        self.sd_setImageWithURL(photoUrl,
            forState:UIControlState.Normal,
            placeholderImage: nil,
            options: options,
            completed: { [weak self] image, error, cacheType, url in
                self?.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        if self.progressAuto {
            startProgress()
        }
        /*
         * Request image via resizer so size is capped. We don't use imgix because it only uses
		 * known image sources that we setup like our buckets on s3.
         */
        let dimension = imageResult.width >= imageResult.height ? ResizeDimension.width : ResizeDimension.height
        let url = NSURL(string: GooglePlusProxy.convert(imageResult.mediaUrl!, size: Int(IMAGE_DIMENSION_MAX), dimension: dimension))
        
        self.linkedPhotoUrl = url
		
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            placeholderImage: nil,
            options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload],
            completed: { [weak self] image, error, cacheType, url in
                self?.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func imageCompletion(image: UIImage?, error: NSError?, cacheType: SDImageCacheType?, url: NSURL?, animate: Bool = true) -> Void {
        
        if self.progressAuto {
            stopProgress()
        }
        
        if error != nil {
            Log.w("Image fetch failed: " + error!.localizedDescription)
			if url != nil {
				Log.w("Failed url: \(url!.absoluteString)", breadcrumb: true)
			}
			if error!.code == HTTPStatusCode.NotFound.rawValue
				|| error!.code == HTTPStatusCode.BadGateway.rawValue
				|| error!.code == HTTPStatusCode.Forbidden.rawValue {
				NSNotificationCenter.defaultCenter().postNotificationName(Events.ImageNotFound, object: self)
				UIShared.Toast("Image not available")
			}
			else if error!.code == HTTPStatusCode.UnsupportedMediaType.rawValue {
				NSNotificationCenter.defaultCenter().postNotificationName(Events.ImageNotFound, object: self)
				UIShared.Toast("Image format not supported")
			}
            return
        }
        else {
            self.contentMode = UIViewContentMode.ScaleAspectFill
        }
        
        /* Image returned is not the one we want anymore */
        if self.linkedPhotoUrl?.absoluteString != url?.absoluteString {
            return
        }
		
		if animate /*|| cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk*/ {
			UIView.transitionWithView(self,
				duration: 0.4,
				options: UIViewAnimationOptions.TransitionCrossDissolve,
				animations: {
					self.setImage(image, forState:UIControlState.Normal)
				},
				completion: nil)
		}
		else {
			self.setImage(image, forState:UIControlState.Normal)
		}
    }
}
