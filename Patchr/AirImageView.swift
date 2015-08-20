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
    var linkedPhotoUrl: NSURL?
    
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
        gradient = CAGradientLayer()
        gradient.frame = CGRectMake(0, 0, self.bounds.size.width + 10, self.bounds.size.height + 10)
        var startColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.2))  // Bottom
        var endColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0))    // Top
        gradient.colors = [endColor.CGColor, startColor.CGColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.hidden = true
        
        self.layer.insertSublayer(self.gradient, atIndex: 0)
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
        
        var frameHeightPixels = Int(self.frame.size.height * PIXEL_SCALE)
        var frameWidthPixels = Int(self.frame.size.width * PIXEL_SCALE)
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!)
        let url = PhotoUtils.urlSized(photoUrl, frameWidth: frameWidthPixels, frameHeight: frameHeightPixels, photoWidth: Int(photo.widthValue), photoHeight: Int(photo.heightValue))
        
        return (linkedPhotoUrl!.absoluteString == url.absoluteString)
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
        
        var frameHeightPixels = Int(self.frame.size.height * PIXEL_SCALE)
        var frameWidthPixels = Int(self.frame.size.width * PIXEL_SCALE)
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!)
        
        if photoUrl.absoluteString == nil || photoUrl.absoluteString!.isEmpty {
            var error = NSError(domain: "Photo error", code: 0, userInfo: [NSLocalizedDescriptionKey:"Photo has invalid source: \(photo.source!)"])
            self.imageCompletion(nil, error: error, cacheType: nil, url: nil, animate: animate)
            return
        }
        
        let url = PhotoUtils.urlSized(photoUrl, frameWidth: frameWidthPixels, frameHeight: frameHeightPixels, photoWidth: Int(photo.widthValue), photoHeight: Int(photo.heightValue))
        
        self.linkedPhotoUrl = url
        
        startActivity()
        
        self.sd_setImageWithURL(url,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithThumbnail(thumbnail: Thumbnail, animate: Bool = true) {
        
        var url = NSURL(string: thumbnail.mediaUrl!)
        
        self.linkedPhotoUrl = url
        
        self.sd_setImageWithURL(url,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        startActivity()
        
        var url = NSURL(string: imageResult.mediaUrl!)
        
        self.linkedPhotoUrl = url
        
        self.sd_setImageWithURL(url,
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
                Log.w(url!.absoluteString)
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
        
        if animate /*|| cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk*/ {
            UIView.transitionWithView(self,
                duration: 0.5,
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
