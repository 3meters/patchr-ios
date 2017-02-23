//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage
import Photos

class AirImageView: UIImageView {

    var fromUrl: URL?
    var fallbackUrl: URL?
    var processing = false
    var activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var sizeCategory = SizeCategory.thumbnail
    var enableLogging = false
    var gradientHeightPcnt = CGFloat(0.35)
    var gradientLayer: CAGradientLayer!
    var asset: Any?
    
    var showGradient: Bool = false {
        didSet {
            if showGradient {
                if self.gradientLayer == nil {
                    self.gradientLayer = CAGradientLayer()
                    let topColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))        // Top
                    let stop2Color: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.33))    // Middle
                    let bottomColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))        // Bottom
                    self.gradientLayer.colors = [topColor.cgColor, stop2Color.cgColor, bottomColor.cgColor]
                    self.gradientLayer.locations = [0.0, 0.5, 1.0]
                    
                    /* Travels from top to bottom */
                    self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)    // (0,0) upper left corner, (1,1) lower right corner
                    self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                    self.layer.insertSublayer(self.gradientLayer, at: 1)
                }
            }
            else {
                if self.gradientLayer != nil {
                    self.gradientLayer.removeFromSuperlayer()
                    self.gradientLayer = nil
                }
            }
        }
    }
    
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
        self.layer.delegate = self
        addSubview(self.activity)
    }
	
    override func layoutSublayers(of layer: CALayer) {
        if layer == self.layer {
            if self.gradientLayer != nil {
                let gradientHeight = self.height() * 0.35
                var rect = layer.bounds
                rect.origin.y = rect.size.height - gradientHeight
                rect.size.height = gradientHeight
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.gradientLayer.frame = rect
                CATransaction.commit()
            }
        }
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
    
    func setImageFromCache(url: URL, animate: Bool = true, then: ((Bool) -> Void)? = nil) {
        if ImageUtils.imageCached(url: url) {
            self.setImageWithUrl(url: url, fallbackUrl: nil, animate: animate, then: then)
            return
        }
        Utils.delay(1.0) {
            if ImageUtils.imageCached(url: url) {
                self.setImageWithUrl(url: url, fallbackUrl: nil, animate: animate, then: then)
            }
            else {
                then?(false)
            }
        }
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
