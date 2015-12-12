//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirImageView: UIImageView {

    var activity: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
	var showGradient: Bool = false
    var gradient: CAGradientLayer?
    var linkedPhotoUrl: NSURL?
    var sizeCategory: String = SizeCategory.thumbnail
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize(){
		self.activity.hidesWhenStopped = true
        addSubview(self.activity)
    }
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.activity.anchorInCenterWithWidth(20, height: 20)
		
		/* Gradient */
		if self.showGradient {
			if self.gradient == nil {
				self.gradient = CAGradientLayer()
				self.layer.addSublayer(self.gradient!)
				let startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.2))  // Bottom
				let endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
				self.gradient!.colors = [endColor.CGColor, startColor.CGColor]
				self.gradient!.startPoint = CGPoint(x: 0.5, y: 0.5)
				self.gradient!.endPoint = CGPoint(x: 0.5, y: 1)
				self.gradient!.zPosition = 1
				self.gradient!.shouldRasterize = true
				self.gradient!.rasterizationScale = UIScreen.mainScreen().scale
			}
			
			self.gradient!.frame = CGRectMake(0, 0, self.bounds.size.width + 10, self.bounds.size.height + 10)
		}
	}

    func startActivity(){
        self.activity.startAnimating()
    }
	
    func stopActivity(){
        self.activity.stopAnimating()
    }
	
    func linkedToPhoto(photo: Photo) -> Bool {
        if linkedPhotoUrl == nil {
            return false
        }
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory)
        return (linkedPhotoUrl!.absoluteString == photoUrl.absoluteString)
    }
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
		let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory)
		
		guard photoUrl.absoluteString != self.linkedPhotoUrl?.absoluteString else {
			return
		}
		
        if photo.source == PhotoSource.resource {
            if animate {
                UIView.transitionWithView(self,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: {
						/* Optimization to skip decoding from file */
						if photo.prefix == "imgDefaultPatch" {
							self.image = Utils.imageDefaultPatch
						}
						if photo.prefix == "imgDefaultUser" {
							self.image = Utils.imageDefaultUser
						}
						else {
							self.image = UIImage(named: photo.prefix)
						}
                    },
                    completion: nil)
            }
            else {
				/* Optimization to skip decoding from file */
				if photo.prefix == "imgDefaultPatch" {
					self.image = Utils.imageDefaultPatch
				}
				if photo.prefix == "imgDefaultUser" {
					self.image = Utils.imageDefaultUser
				}
				else {
					self.image = UIImage(named: photo.prefix)
				}
            }
            return
        }
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			
			if photoUrl.absoluteString.isEmpty {
				let error = NSError(domain: "Photo error", code: 0, userInfo: [NSLocalizedDescriptionKey:"Photo has invalid source: \(photo.source!)"])
				dispatch_async(dispatch_get_main_queue()) {
					self.imageCompletion(nil, error: error, cacheType: nil, url: nil, animate: animate)
				}
				return
			}
			
			/* Stash the url we are loading so we can check for a match later when download is completed. */
			self.linkedPhotoUrl = photoUrl
			
			self.sd_setImageWithURL(photoUrl,
				placeholderImage: nil,
				options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload],
				completed: { [weak self] image, error, cacheType, url in
					
					dispatch_async(dispatch_get_main_queue()) {
						self?.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
					}
				}
			)
		}
		
		dispatch_async(dispatch_get_main_queue()) {
			self.startActivity()
		}
    }
	
    func setImageWithThumbnail(thumbnail: Thumbnail, animate: Bool = true) {
        
        let url = NSURL(string: thumbnail.mediaUrl!)
        
		/* Stash the url we are loading so we can check for a match later when download is completed. */
        self.linkedPhotoUrl = url
        
        self.sd_setImageWithURL(url,
            placeholderImage: nil,
            options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage],
            completed: { [weak self] image, error, cacheType, url in
                self?.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        startActivity()
        
        let url = NSURL(string: imageResult.mediaUrl!)
        
		/* Stash the url we are loading so we can check for a match later when download is completed. */
        self.linkedPhotoUrl = url
        
        self.sd_setImageWithURL(url,
            placeholderImage: nil,
            options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload],
            completed: {
				[weak self] image, error, cacheType, url in
				self?.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }

    func imageCompletion(image: UIImage?, error: NSError?, cacheType: SDImageCacheType?, url: NSURL?, animate: Bool = true) -> Void {
        
        stopActivity()

		
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
				duration: 0.25,
				options: UIViewAnimationOptions.TransitionCrossDissolve,
				animations: {
					self.image = image
				},
				completion: nil)
		}
		else {
			self.image = image
		}
    }
}
