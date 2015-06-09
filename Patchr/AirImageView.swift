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
    var photo: Photo?
    
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
        let widthConstraint = NSLayoutConstraint(item: activity, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        let heightConstraint = NSLayoutConstraint(item: activity, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        
        self.addConstraints([xCenterConstraint, yCenterConstraint, widthConstraint, heightConstraint])
        
        activity.hidesWhenStopped = true
    }
    
    func startActivity(){
        activity.startAnimating()
    }
    
    func stopActivity(){
        activity.stopAnimating()
    }
}
