//
//  AirImageView.swift
//  Patchr
//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class AirToolButton: AirImageButton {
	
    override func initialize(){
		self.tintColor = Theme.colorTint
		self.imageView?.tintColor = Theme.colorTint
    }
}
