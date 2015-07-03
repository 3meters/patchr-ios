//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirImageButton: UIButton {

    var activity: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var photoUrl: NSURL?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize(){
        
        activity.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(activity)
        
        let xCenterConstraint = NSLayoutConstraint(item: activity, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let yCenterConstraint = NSLayoutConstraint(item: activity, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: activity, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 12)
        let heightConstraint = NSLayoutConstraint(item: activity, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 12)
        
        self.addConstraints([xCenterConstraint, yCenterConstraint, widthConstraint, heightConstraint])
        
        activity.hidesWhenStopped = true
    }
    
    func startActivity(){
        activity.startAnimating()
    }
    
    func stopActivity(){
        activity.stopAnimating()
    }
    
    func setImageWithPhoto(photo: Photo, animate: Bool = true) {
        
        if photo.source == PhotoSource.resource.rawValue {
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
        
        var resizerHeight = self.frame.size.height * PIXEL_SCALE
        var resizerWidth = self.frame.size.width * PIXEL_SCALE
        
        photo.resizer(true, height: Int(resizerHeight), width: Int(resizerWidth))
        let url = photo.uriWrapped()
        
        /* We already have the needed image */
        if self.photoUrl?.absoluteString == url.absoluteString {
            return
        }
        
        self.photoUrl = url
        
        startActivity()
        
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func setImageWithImageResult(imageResult: ImageResult, animate: Bool = true) {
        
        startActivity()
        /*
         * Request image via resizer so size is capped.
         */
        let dimension = imageResult.width >= imageResult.height ? ResizeDimension.width : ResizeDimension.height
        var url = NSURL(string: GooglePlusProxy.convert(imageResult.mediaUrl!, size: 1280, dimension: dimension))
        
        /* We already have the needed image */
        if self.photoUrl?.absoluteString == url!.absoluteString {
            return
        }
        
        self.photoUrl = url
        
        self.sd_setImageWithURL(url,
            forState:UIControlState.Normal,
            completed: { image, error, cacheType, url in
                self.imageCompletion(image, error: error, cacheType: cacheType, url: url, animate: animate)
            }
        )
    }
    
    func imageCompletion(image: UIImage?, error: NSError?, cacheType: SDImageCacheType, url: NSURL, animate: Bool = true) -> Void {
        
        stopActivity()
        
        if error != nil {
            println("Image fetch failed: " + error!.localizedDescription)
            println(url.standardizedURL)
            self.setImage(UIImage(named: "imgBroken250Light"), forState:UIControlState.Normal)
            return
        }
        
        /* Image returned is not the one we want anymore */
        if self.photoUrl?.absoluteString != url.absoluteString {
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
