//
//  ImageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-12.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController {
    
    var image: UIImage?
    var imageURL: NSURL?

    @IBOutlet weak var mainImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.image != nil {
            self.mainImageView.image = self.image
        } else if imageURL != nil {
            self.mainImageView.pa_setImageWithURL(self.imageURL)
        }
    }
}
