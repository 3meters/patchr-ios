//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirImageButton: UIButton {

    var progress: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var linkedPhotoUrl: NSURL?
    var sizeCategory: String = SizeCategory.thumbnail

    var progressAuto: Bool = true
    
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
	
    func linkedToPhoto(photo: Photo) -> Bool {
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
         * Request image via resizer so size is capped.
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
            Log.w("Failed url: \(url?.absoluteString)")
			if error!.code == HTTPStatusCode.NotFound.rawValue {
				Shared.Toast("Image not found")
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
				duration: 0.5,
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
