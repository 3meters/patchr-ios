//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage
import Photos
import DACircularProgress

class AirImageView: UIImageView {

    var progressView: DACircularProgressView!
    
    var gradientHeightPcnt = CGFloat(0.35)
    var gradientLayer: CAGradientLayer!
    var asset: Any? // Holds extra metadata when image is from device library
    var fromUrl: URL?
    var processing = false
    var enableProgress = true
    var enableLogging = false
    
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
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/
    
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
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func initialize(){
        self.layer.delegate = self
        self.progressView = DACircularProgressView()
        self.progressView.trackTintColor = Colors.white
        self.progressView.progressTintColor = Colors.accentColor
        self.progressView.thicknessRatio = 0.15
    }
    
    func reset() {
        self.processing = false
        self.hideProgress()
    }
    
    func showProgress() {
        addSubview(self.progressView)
    }
    
    func hideProgress() {
        if self.progressView.superview != nil {
            self.progressView.setProgress(0, animated: false)
            self.progressView.removeFromSuperview()
        }
    }
	
    func setImageWithUrl(url: URL, animate: Bool = true, then: ((Bool) -> Void)? = nil) {
        
		/* Stash the url we are loading so we can check for a match later when download is completed. */
		self.fromUrl = url
        self.processing = true
        self.contentMode = .scaleAspectFill
        if self.enableProgress {
            self.showProgress()
        }
        
        let progress: SDWebImageDownloaderProgressBlock = { loadedSize, expectedSize, url in
            let progress = CGFloat(loadedSize) / CGFloat(expectedSize)
            DispatchQueue.main.async {
                self.progressView.setProgress(progress, animated: true)
            }
        }
        
        let completed: SDExternalCompletionBlock = { [weak self] image, error, cacheType, imageUrl in
            
            self?.processing = false
            
            DispatchQueue.main.async() {

                self?.hideProgress()
                if error != nil {
                    Log.w("*** Image fetch failed: " + error!.localizedDescription)
                    Log.w("*** Failed url: \(url.absoluteString)")
                    self?.fromUrl = nil
                    return
                }
                
                /* Image returned is not the one we want anymore */
                if self?.fromUrl?.absoluteString != url.absoluteString {
                    return
                }
                
                if animate {
                    UIView.transition(with: self!
                        , duration: 0.3
                        , options: .transitionCrossDissolve
                        , animations: { self?.image = image })
                }
                else {
                    self?.image = image
                }
                then?(true)
            }
        }
        
        sd_setImage(with: url
            , placeholderImage: nil
            , options: [.retryFailed, .lowPriority, .avoidAutoSetImage]
            , progress: progress
            , completed: completed)
	}
    
    func associated(withUrl: URL) -> Bool {
        if self.fromUrl != nil && withUrl.absoluteString == self.fromUrl?.absoluteString {
            return (self.image != nil || self.processing)
        }
        return false
    }
}
