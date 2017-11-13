//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Foundation
import SDWebImage
import Photos
import DACircularProgress

@IBDesignable
class AirImageView: UIImageView {
    
    var progressView: DALabeledCircularProgressView!
    
    var gradientColorTop = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))
    var gradientColorMiddle1 = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))
    var gradientColorMiddle2 = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))
    var gradientColorBottom = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))
    var gradientHeightPcnt = CGFloat(1.0)
    var gradientLayer: CAGradientLayer!
    
    var asset: Any? // Holds extra metadata when image is from device library
    var fromUrl: URL! {
        didSet {
            if self.enableLogging {
                if fromUrl == nil {
                    Log.d("fromUrl set to: nil")
                    return
                }
                Log.d("fromUrl set to: \(fromUrl!)")                
            }
        }
    }
    var processing = false
    var enableProgress = true
    var enableLogging = false
    
    @IBInspectable var dummyImage: UIImage?
    @IBInspectable var showGradient: Bool = false {
        didSet {
            if showGradient {
                if self.gradientLayer == nil {
                    self.gradientLayer = CAGradientLayer()
                    self.gradientLayer.colors = [self.gradientColorTop.cgColor
                        , self.gradientColorMiddle1.cgColor
                        , self.gradientColorMiddle2.cgColor
                        , self.gradientColorBottom.cgColor]
                    self.gradientLayer.locations = [0.0, 0.45, 0.66, 1.0]
                    
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
    
    @IBInspectable override var image: UIImage? {
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
                        Log.d("ImageView cleared existing image to nil: \(String(describing: self.fromUrl?.path))")
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
                let gradientHeight = self.height() * self.gradientHeightPcnt
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

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.image = self.dummyImage
        self.contentMode = .scaleAspectFill
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func initialize(){
        self.layer.delegate = self
        self.layer.masksToBounds = true
        self.backgroundColor = Theme.colorBackgroundTable
        self.progressView = DALabeledCircularProgressView(frame: CGRect.zero)
        self.progressView.trackTintColor = Colors.white
        self.progressView.progressTintColor = Colors.accentColor
        self.progressView.thicknessRatio = 0.15
    }
    
    func reset() {
        self.processing = false
        if !ReachabilityManager.instance.isReachable() {
            self.backgroundColor = Theme.colorBackgroundTable
            self.image = nil
        }
        else {
            self.hideProgress()
        }
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
	
    func setImageWithUrl(url: URL, imageType: ImageType = .photo, uploading: Bool = false, animate: Bool = true, then: ((Bool) -> Void)? = nil) {
        
		/* Stash the url we are loading so we can check for a match later when download is completed. */
		self.fromUrl = url
        self.processing = true
        self.contentMode = .scaleAspectFill
        if self.enableProgress {
            self.showProgress()
        }
        
        let progress: SDWebImageDownloaderProgressBlock = { [weak self] loadedSize, expectedSize, url in
            guard let this = self else { return }
            let progress = CGFloat(loadedSize) / CGFloat(expectedSize)
            DispatchQueue.main.async {
                this.progressView.setProgress(progress, animated: true)
            }
        }
        
        let setImageCompleted: SDExternalCompletionBlock = { [weak self] image, error, cacheType, imageUrl in
            guard let this = self else { return }
            this.processing = false
            DispatchQueue.main.async() {
                
                if error != nil {
                    if !uploading {
                        if ReachabilityManager.instance.isReachable() {
                            this.progressView.progressLabel.text = "image_missing".localized()
                            this.progressView.progressLabel.textColor = Theme.colorTextSecondary
                        }
                        Log.w("*** Image fetch failed: " + error!.localizedDescription)
                        Log.w("*** Failed url: \(url.absoluteString)")
                    }
                    this.fromUrl = nil
                    return
                }
                
                this.hideProgress()
                
                /* Exit if image returned is not the one we want anymore */
                if this.fromUrl?.absoluteString != url.absoluteString {
                    return
                }
                
                if animate {
                    UIView.transition(with: this
                        , duration: 0.3
                        , options: .transitionCrossDissolve
                        , animations: { this.image = image })
                }
                else {
                    this.image = image
                }
                then?(true)
            }
        }
        
        let loadImageCompleted: SDInternalCompletionBlock = { [weak self] image, imageData, error, cacheType, finished, imageUrl in
            guard let this = self else { return }
            this.processing = false
            if error != nil {
                Log.w("*** Animated gif fetch failed: " + error!.localizedDescription)
                Log.w("*** Failed url: \(url.absoluteString)")
                DispatchQueue.main.async() {
                    this.progressView.progressLabel.textColor = Theme.colorTextSecondary
                    this.progressView.progressLabel.text = "image_missing".localized()
                }
                this.fromUrl = nil
                return
            }
            
            /* Image returned is not the one we want anymore */
            if this.fromUrl?.absoluteString != url.absoluteString {
                return
            }
            
            if finished && image != nil && imageData != nil {
                DispatchQueue.main.async() {
                    this.hideProgress()
                    if animate {
                        UIView.transition(with: this
                            , duration: 0.3
                            , options: .transitionCrossDissolve
                            , animations: {
                                this.image = image
                        })
                    }
                    else {
                        this.image = image
                    }
                    then?(true)
                }
            }
        }
        
        if imageType == .photo {
            sd_setImage(with: url
                , placeholderImage: nil
                , options: [.retryFailed, .avoidAutoSetImage]
                , progress: progress
                , completed: setImageCompleted)
        }
        else if imageType == .animatedGif {
            SDWebImageManager.shared().loadImage(with: url
                , options: [.retryFailed]
                , progress: progress
                , completed: loadImageCompleted)
        }
	}
    
    func associated(withUrl: URL) -> Bool {
        if self.fromUrl != nil && withUrl.absoluteString == self.fromUrl!.absoluteString {
            return (self.image != nil || self.processing)
        }
        return false
    }
}
