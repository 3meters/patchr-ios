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

    var fromUrl: URL?
    var fallbackUrl: URL?
    var processing = false
    var activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var sizeCategory = SizeCategory.thumbnail
    var enableLogging = true
    
    override var image: UIImage? {
        didSet {
            if self.enableLogging {
                if image != nil {
                    if self.fromUrl != nil {
                        Log.d("ImageView set: \(self.fromUrl!.path)")
                    }
                    else {
                        Log.d("ImageView set without existing image: \(image!.description)")
                    }
                }
                else {
                    if super.image != nil {
                        Log.d("ImageView cleared existing image to nil: \(self.fromUrl?.path)")
                    }
                }
            }
            super.image = image
        }
    }
    
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
	}

    func startActivity(){
        self.activity.startAnimating()
    }
	
    func stopActivity(){
        self.activity.stopAnimating()
    }
    
    func associated(withUrl: URL) -> Bool {
        if self.fromUrl != nil && withUrl.absoluteString == self.fromUrl?.absoluteString {
            return (self.image != nil || self.processing)
        }
        return false
    }
	
    func setImageWithUrl(url: URL, fallbackUrl: URL?, animate: Bool = true, then: ((Bool) -> Void)? = nil) {
        
		/* Stash the url we are loading so we can check for a match later when download is completed. */
		self.fromUrl = url
        self.fallbackUrl = nil
        self.processing = true
		let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage, .delayPlaceholder /* .ProgressiveDownload */]

		self.sd_setImage(with: url, placeholderImage: nil, options: options) { [weak self] image, error, cacheType, url in
            if error != nil && fallbackUrl != nil {

                self?.fallbackUrl = fallbackUrl

                Log.w("*** Image fetch failed: " + error!.localizedDescription)
                Log.w("*** Failed url: \(url!.absoluteString)")
                Log.w("*** Trying fallback url for image: \(fallbackUrl!)")
                
                self?.sd_setImage(with: fallbackUrl!, placeholderImage: nil, options: options) { [weak self] image, error, cacheType, url in
                    if error == nil {
                        Log.w("*** Success using fallback url for image: \(fallbackUrl!)")
                    }
                    DispatchQueue.main.async() {
                        self?.imageCompletion(image: image, error: error, cacheType: cacheType, url: url, animate: animate)
                        then?(error == nil)
                    }
                }
            }
            else {
                DispatchQueue.main.async() {
                    self?.imageCompletion(image: image, error: error, cacheType: cacheType, url: url, animate: animate)
                    then?(error == nil)
                }
            }
        }
	}

    func imageCompletion(image: UIImage?, error: Error?, cacheType: SDImageCacheType?, url: URL?, animate: Bool = true) -> Void {
        
        stopActivity()
        self.processing = false
		
        if error != nil {
            Log.w("*** Image fetch failed: " + error!.localizedDescription)
            Log.w("*** Failed url: \(url!.absoluteString)")
			self.fromUrl = nil
            self.fallbackUrl = nil
			return
        }
        else {
            self.contentMode = .scaleAspectFill
        }
        
        /* Image returned is not the one we want anymore */
        if self.fallbackUrl != nil {
            if self.fallbackUrl!.absoluteString != url?.absoluteString {
                return
            }
        }
        else {
            if self.fromUrl?.absoluteString != url?.absoluteString {
                return
            }
        }
        
		if animate /*|| cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk*/ {
			UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve,
				animations: { self.image = image },
				completion: nil)
		}
		else {
			self.image = image
		}
    }
}
