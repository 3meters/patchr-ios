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

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.image != nil {
            self.imageView.image = self.image
        } else if imageURL != nil {
            var photo = Photo.insertInManagedObjectContext(DataController.instance.managedObjectContext) as! Photo
            photo.prefix = self.imageURL!.absoluteString
            photo.source = PhotoSource.generic.rawValue;
            self.imageView.setImageWithPhoto(photo)
        }
    }
}
