//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class AirImageView: UIImageView {

    var activity: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
	
	var showGradient: Bool = false {
		didSet {
			if showGradient {
				if self.gradient == nil {
					self.gradient = CAGradientLayer()
					let startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.2))  // Bottom
					let endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
					self.gradient!.colors = [endColor.cgColor, startColor.cgColor]
					self.gradient!.startPoint = CGPoint(x: 0.5, y: 0.5)
					self.gradient!.endPoint = CGPoint(x: 0.5, y: 1)
					self.gradient!.zPosition = 1
					self.gradient!.shouldRasterize = true
					self.gradient!.rasterizationScale = UIScreen.main.scale
				}
			
				self.layer.addSublayer(self.gradient!)
                self.gradient!.frame = CGRect(x:0, y:0, width:self.bounds.size.width + 10, height:self.bounds.size.height + 10)
			}
			else {
				if self.gradient != nil {
					self.gradient?.removeFromSuperlayer()
				}
			}
		}
	}
	
    var gradient: CAGradientLayer?
    var linkedPhotoUrl: URL?
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
		
		self.activity.anchorInCenter(withWidth: 20, height: 20)
		
		/* Gradient */
		if self.showGradient {
			if self.gradient == nil {
				self.gradient = CAGradientLayer()
				self.layer.addSublayer(self.gradient!)
				let startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.2))  // Bottom
				let endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
				self.gradient!.colors = [endColor.cgColor, startColor.cgColor]
				self.gradient!.startPoint = CGPoint(x: 0.5, y: 0.5)
				self.gradient!.endPoint = CGPoint(x: 0.5, y: 1)
				self.gradient!.zPosition = 1
				self.gradient!.shouldRasterize = true
				self.gradient!.rasterizationScale = UIScreen.main.scale
			}
			
            self.gradient!.frame = CGRect(x:0, y:0, width:self.bounds.size.width + 10, height:self.bounds.size.height + 10)
		}
		else {
			if self.gradient != nil {
				self.gradient?.removeFromSuperlayer()
			}
		}
	}

    func startActivity(){
        self.activity.startAnimating()
    }
	
    func stopActivity(){
        self.activity.stopAnimating()
    }
	
    func linkedToPhoto(photo: Photo) -> Bool {
        if self.linkedPhotoUrl == nil {
            return false
        }
        
        let photoUrl = PhotoUtils.url(prefix: photo.prefix!, source: photo.source!, category: self.sizeCategory)
        return (self.linkedPhotoUrl!.absoluteString == photoUrl!.absoluteString)
    }
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
		let photoUrl = PhotoUtils.url(prefix: photo.prefix!, source: photo.source!, category: self.sizeCategory)
		
		guard photoUrl?.absoluteString != self.linkedPhotoUrl?.absoluteString else {
			return
		}
		
        if photo.source == PhotoSource.resource {
            if animate {
                UIView.transition(with: self,
                    duration: 0.5,
                    options: UIViewAnimationOptions.transitionCrossDissolve,
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
        
        DispatchQueue.global().async {
			if (photoUrl?.absoluteString.isEmpty)! {
				let error = NSError(domain: "Photo error", code: 0, userInfo: [NSLocalizedDescriptionKey:"Photo has invalid source: \(photo.source!)"])
				DispatchQueue.main.async() {
					self.imageCompletion(image: nil, error: error, cacheType: nil, url: nil, animate: animate)
				}
				return
			}
			
			/* Stash the url we are loading so we can check for a match later when download is completed. */
			self.linkedPhotoUrl = photoUrl
			let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage, /* .ProgressiveDownload */]
			
            self.sd_setImage(with: photoUrl,
				placeholderImage: nil,
				options: options,
				completed: {
                    [weak self] image, error, cacheType, url in
                    if (self != nil) {
                        DispatchQueue.main.async() {
                            self!.imageCompletion(image: image, error: error, cacheType: cacheType, url: url, animate: animate)
                        }
                    }
            })
		}
        DispatchQueue.main.async {
			self.startActivity()
		}
    }
	
	func setImageWithUrl(url: URL, animate: Bool = true) {

		/* Stash the url we are loading so we can check for a match later when download is completed. */
		self.linkedPhotoUrl = url
		let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage, /* .ProgressiveDownload */]

		self.sd_setImage(with: url,
            placeholderImage: nil,
            options: options,
            completed: {
                [weak self] image, error, cacheType, url in
                if (self != nil) {
                    self!.imageCompletion(image: image, error: error, cacheType: cacheType, url: url, animate: animate)
                }
            })
	}

    func imageCompletion(image: UIImage?, error: Error?, cacheType: SDImageCacheType?, url: URL?, animate: Bool = true) -> Void {
        
        stopActivity()
		
        if error != nil {
			
			Log.w("Image fetch failed: " + error!.localizedDescription)
			Log.w("Failed url: \(url?.absoluteString)")
			
			self.linkedPhotoUrl = nil

			if error!._code == HTTPStatusCode.NotFound.rawValue {
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ImageNotFound), object: self)
				UIShared.Toast(message: "Image not found")
			}
			else if error!._code == HTTPStatusCode.UnsupportedMediaType.rawValue {
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.ImageNotFound), object: self)
				UIShared.Toast(message: "Image format not supported")
			}
			
			return
        }
        else {
            self.contentMode = UIViewContentMode.scaleAspectFill
        }
        
        /* Image returned is not the one we want anymore */
        if self.linkedPhotoUrl?.absoluteString != url?.absoluteString {
            return
        }
        		
		if animate /*|| cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk*/ {
			UIView.transition(with: self,
				duration: 0.4,
				options: UIViewAnimationOptions.transitionCrossDissolve,
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
