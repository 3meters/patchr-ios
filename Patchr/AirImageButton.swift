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
    var spot: CAShapeLayer?
    var sizeCategory: String = SizeCategory.thumbnail

    var widthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    
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
        
        self.progress.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(progress)
        
        let xCenterConstraint = NSLayoutConstraint(item: progress, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let yCenterConstraint = NSLayoutConstraint(item: progress, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        self.widthConstraint = NSLayoutConstraint(item: progress, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: self.progressSize)
        self.heightConstraint = NSLayoutConstraint(item: progress, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: self.progressSize)
        
        self.addConstraints([xCenterConstraint, yCenterConstraint, widthConstraint!, heightConstraint!])
        
        self.progress.hidesWhenStopped = true
        
        /* Dot for debug */
        if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("devModeEnabled")) {
            self.spot = CAShapeLayer()
            self.spot!.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)
            self.spot!.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2)
            self.spot!.path = UIBezierPath(ovalInRect: CGRectMake(4, 4, 12, 12)).CGPath
            self.spot!.fillColor = UIColor.lightGrayColor().CGColor
            self.spot!.zPosition = 0
            self.layer.addSublayer(self.spot!)
        }
    }
    
    func setProgressSize(size: CGFloat) {
        self.progressSize = size
        self.widthConstraint?.constant = size
        self.heightConstraint?.constant = size
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
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
    
    func linkedToPhoto(photo: Photo) -> Bool {
        if self.linkedPhotoUrl == nil {
            return false
        }
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory, size: nil)
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
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory, size: nil)
        
        if photoUrl.absoluteString.isEmpty {
            let error = NSError(domain: "Photo error", code: 0, userInfo: [NSLocalizedDescriptionKey:"Photo has invalid source: \(photo.source!)"])
            self.imageCompletion(nil, error: error, cacheType: nil, url: nil, animate: animate)
            return
        }
        
        self.linkedPhotoUrl = photoUrl
        
        if progressAuto {
            startProgress()
        }
    
        self.spot?.fillColor = UIColor.lightGrayColor().CGColor
        self.sd_setImageWithURL(photoUrl,
            forState:UIControlState.Normal,
            placeholderImage: nil,
            options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload],
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
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
        
        self.spot?.fillColor = UIColor.lightGrayColor().CGColor
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            placeholderImage: nil,
            options: [.RetryFailed, .LowPriority, .AvoidAutoSetImage, .ProgressiveDownload],
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
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
                Log.w("Failed url: \(url!.absoluteString)")
            }
            self.contentMode = UIViewContentMode.Center
            self.setImage(UIImage(named: "imgBroken250Light"), forState:UIControlState.Normal)
            return
        }
        else {
            self.contentMode = UIViewContentMode.ScaleAspectFill
        }
        
        /* Image returned is not the one we want anymore */
        if self.linkedPhotoUrl?.absoluteString != url?.absoluteString {
            return
        }
        
        self.spot?.fillColor = UIColor.lightGrayColor().CGColor
        if NSUserDefaults.standardUserDefaults().boolForKey(PatchrUserDefaultKey("devModeEnabled")) {
            self.spot?.fillColor = UIColor.redColor().CGColor
            if cacheType == SDImageCacheType.Disk {
                self.spot?.fillColor = UIColor.orangeColor().CGColor
            }
            else if cacheType == SDImageCacheType.Memory {
                self.spot?.fillColor = UIColor.greenColor().CGColor
            }
            self.spot?.hidden = false
        }
        else {
            self.spot?.hidden = true
        }

        self.setImage(image, forState:UIControlState.Normal)
    }
}
