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
    var gradient: CAGradientLayer!
    var spot: CAShapeLayer?
    var linkedPhotoUrl: NSURL?
    var sizeCategory: String = SizeCategory.thumbnail
    var imageOptions = SDWebImageOptions.RetryFailed | SDWebImageOptions.LowPriority | SDWebImageOptions.AvoidAutoSetImage | SDWebImageOptions.ProgressiveDownload
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize(){
        
        self.activity.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(self.activity)
        
        var centerConstraintX = NSLayoutConstraint(item: self.activity, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        var centerConstraintY = NSLayoutConstraint(item: self.activity, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        var widthConstraint = NSLayoutConstraint(item: self.activity, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        var heightConstraint = NSLayoutConstraint(item: self.activity, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        
        addConstraints([centerConstraintX, centerConstraintY, widthConstraint, heightConstraint])
        
        self.activity.hidesWhenStopped = true
        
        /* Gradient */
        self.gradient = CAGradientLayer()
        self.gradient.frame = CGRectMake(0, 0, self.bounds.size.width + 10, self.bounds.size.height + 10)
        var startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.2))  // Bottom
        var endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
        self.gradient.colors = [endColor.CGColor, startColor.CGColor]
        self.gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.gradient.endPoint = CGPoint(x: 0.5, y: 1)
        self.gradient.hidden = true
        self.gradient.zPosition = 1
        self.layer.addSublayer(self.gradient)
        
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
    
    func startActivity(){
        activity.startAnimating()
    }
    
    func stopActivity(){
        activity.stopAnimating()
    }
    
    func linkedToPhoto(photo: Photo) -> Bool {
        if linkedPhotoUrl == nil {
            return false
        }
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory, size: nil)
        return (linkedPhotoUrl!.absoluteString! == photoUrl.absoluteString!)
    }
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
        if photo.source == PhotoSource.resource {
            if animate {
                UIView.transitionWithView(self,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: {
                        self.image = UIImage(named: photo.prefix)
                    },
                    completion: nil)
            }
            else {
                self.image = UIImage(named: photo.prefix)
            }
            return
        }
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!, category: self.sizeCategory, size: nil)
        
        if photoUrl.absoluteString == nil || photoUrl.absoluteString!.isEmpty {
            var error = NSError(domain: "Photo error", code: 0, userInfo: [NSLocalizedDescriptionKey:"Photo has invalid source: \(photo.source!)"])
            self.imageCompletion(nil, error: error, cacheType: nil, url: nil, animate: animate)
            return
        }
        
        self.linkedPhotoUrl = photoUrl
        
        startActivity()
        
        self.spot?.fillColor = UIColor.lightGrayColor().CGColor
        self.sd_setImageWithURL(photoUrl,
            placeholderImage: nil,
            options: imageOptions,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithThumbnail(thumbnail: Thumbnail, animate: Bool = true) {
        
        var url = NSURL(string: thumbnail.mediaUrl!)
        
        self.linkedPhotoUrl = url
        
        self.spot?.fillColor = UIColor.lightGrayColor().CGColor
        self.sd_setImageWithURL(url,
            placeholderImage: nil,
            options: imageOptions,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        startActivity()
        
        var url = NSURL(string: imageResult.mediaUrl!)
        
        self.linkedPhotoUrl = url
        
        self.spot?.fillColor = UIColor.lightGrayColor().CGColor
        self.sd_setImageWithURL(url,
            placeholderImage: nil,
            options: imageOptions,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }

    func imageCompletion(image: UIImage?, error: NSError?, cacheType: SDImageCacheType?, url: NSURL?, animate: Bool = true) -> Void {
        
        stopActivity()
        
        if error != nil {
            Log.w("Image fetch failed: " + error!.localizedDescription)
            if url != nil {
                Log.w("Failed url: \(url!.absoluteString!)")
            }
            self.contentMode = UIViewContentMode.Center
            self.image = UIImage(named: "imgBroken250Light")
            return
        }
        else {
            self.contentMode = UIViewContentMode.ScaleAspectFill
        }
        
        /* Image returned is not the one we want anymore */
        if self.linkedPhotoUrl?.absoluteString != url?.absoluteString {
            return
        }
        
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
        
        self.image = image
    }
}
