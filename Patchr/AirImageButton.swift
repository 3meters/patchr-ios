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

    var progress		: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    var linkedPhotoUrl	: URL?
    var sizeCategory	= SizeCategory.thumbnail
    var progressAuto	= true
    
    private var progressStyle: UIActivityIndicatorViewStyle = .gray
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
		self.progress.anchorInCenter(withWidth: self.progressSize, height: self.progressSize)
	}
	
    func setImageWithUrl(url: URL, fallbackUrl: URL?, animate: Bool = true, finished: ((Bool) -> Void)? = nil) {

		if self.progressAuto {
			startProgress()
		}
		
		/* Stash the url we are loading so we can check for a match later when download is completed. */
		self.linkedPhotoUrl = url
		let options: SDWebImageOptions = [.retryFailed, .lowPriority, .avoidAutoSetImage, /* .ProgressiveDownload */]
		
        self.sd_setImage(with: url, for: UIControlState.normal, placeholderImage: nil, options: options) { [weak self] image, error, cacheType, url in
            if error != nil && fallbackUrl != nil {
                Log.w("*** Image fetch failed: " + error!.localizedDescription)
                Log.w("*** Failed url: \(url!.absoluteString)")
                Log.w("*** Trying fallback url for image: \(fallbackUrl!)")
                self?.linkedPhotoUrl = fallbackUrl
                self?.sd_setImage(with: fallbackUrl!, for: UIControlState.normal, placeholderImage: nil, options: options) { [weak self] image, error, cacheType, url in
                    if error == nil {
                        Log.w("*** Success using fallback url for image: \(fallbackUrl!)")
                    }
                    DispatchQueue.main.async() {
                        self?.imageCompletion(image: image, error: error, cacheType: cacheType, url: url, animate: animate)
                        finished?(error == nil)
                    }
                }
            }
            else {
                DispatchQueue.main.async() {
                    self?.imageCompletion(image: image, error: error, cacheType: cacheType, url: url, animate: animate)
                    finished?(error == nil)
                }
            }
        }
	}

    func imageCompletion(image: UIImage?, error: Error?, cacheType: SDImageCacheType?, url: URL?, animate: Bool = true) -> Void {
        
        if self.progressAuto {
            stopProgress()
        }
        
        if error != nil {
            Log.w("*** Image fetch failed: " + error!.localizedDescription)
            Log.w("*** Failed url: \(url!.absoluteString)")
            
            self.linkedPhotoUrl = nil
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
					self.setImage(image, for:UIControlState.normal)
				},
				completion: nil)
		}
		else {
			self.setImage(image, for:UIControlState.normal)
		}
    }
}
