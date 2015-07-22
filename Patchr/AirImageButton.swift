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
    
    var widthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    
    var progressAuto: Bool = true
    
    private var progressStyle: UIActivityIndicatorViewStyle = .Gray
    private var progressSize: CGFloat = 12
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize(){
        
        self.progress.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(progress)
        
        let xCenterConstraint = NSLayoutConstraint(item: progress, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let yCenterConstraint = NSLayoutConstraint(item: progress, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        self.widthConstraint = NSLayoutConstraint(item: progress, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: self.progressSize)
        self.heightConstraint = NSLayoutConstraint(item: progress, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: self.progressSize)
        
        self.addConstraints([xCenterConstraint, yCenterConstraint, widthConstraint!, heightConstraint!])
        
        self.progress.hidesWhenStopped = true
    }
    
    func setProgressSize(size: CGFloat) {
        self.progressSize = size
        self.widthConstraint?.constant = size
        self.heightConstraint?.constant = size
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
    }
    
    func setProgressStyle(style: UIActivityIndicatorViewStyle) {
        progress.activityIndicatorViewStyle = style
    }
    
    func startProgress(){
        progress.startAnimating()
    }
    
    func stopProgress(){
        progress.stopAnimating()
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
                        self.setImage(UIImage(named: photo.prefix), forState:UIControlState.Normal)
                    },
                    completion: nil)
            }
            else {
                self.setImage(UIImage(named: photo.prefix), forState:UIControlState.Normal)
            }
            return
        }
        
        var frameHeightPixels = Int(self.frame.size.height * PIXEL_SCALE)
        var frameWidthPixels = Int(self.frame.size.width * PIXEL_SCALE)
        
        let photoUrl = PhotoUtils.url(photo.prefix!, source: photo.source!)
        let url = PhotoUtils.urlSized(photoUrl, frameWidth: frameWidthPixels, frameHeight: frameHeightPixels, photoWidth: Int(photo.widthValue), photoHeight: Int(photo.heightValue))
        
        self.linkedPhotoUrl = url
        
        if progressAuto {
            startProgress()
        }
    
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        if progressAuto {
            startProgress()
        }
        /*
         * Request image via resizer so size is capped.
         */
        let dimension = imageResult.width >= imageResult.height ? ResizeDimension.width : ResizeDimension.height
        var url = NSURL(string: GooglePlusProxy.convert(imageResult.mediaUrl!, size: 1280, dimension: dimension))
        
        self.linkedPhotoUrl = url
        
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func imageCompletion(image: UIImage?, error: NSError?, cacheType: SDImageCacheType, url: NSURL, animate: Bool = true) -> Void {
        
        if progressAuto {
            stopProgress()
        }
        
        if error != nil {
            println("Image fetch failed: " + error!.localizedDescription)
            println(url.standardizedURL)
            self.contentMode = UIViewContentMode.Center
            self.setImage(UIImage(named: "imgBroken250Light"), forState:UIControlState.Normal)
            return
        }
        else {
            self.contentMode = UIViewContentMode.ScaleAspectFill
        }
        
        /* Image returned is not the one we want anymore */
        if self.linkedPhotoUrl?.absoluteString != url.absoluteString {
            return
        }
        
        if animate || cacheType == SDImageCacheType.None || cacheType == SDImageCacheType.Disk {
            UIView.transitionWithView(self,
                duration: 0.5,
                options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.setImage(image, forState:UIControlState.Normal)
                },
                completion: nil)
        }
        else {
            self.setImage(image, forState:UIControlState.Normal)
        }
    }
}
