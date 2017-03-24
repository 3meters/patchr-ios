//
//  PatchTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class GalleryViewCell: UICollectionViewCell {
	
	var displayPhoto: DisplayPhoto?
	var displayImageView = AirImageView(frame: CGRect.zero)
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		self.clipsToBounds = true
		self.contentView.addSubview(self.displayImageView)
	}
    
    func reset() {
        self.displayImageView.reset()
    }
	
	override var layoutMargins: UIEdgeInsets {
		get { return UIEdgeInsets.zero }
		set (newVal) {}
	}
	
	override func layoutSubviews() {
		self.contentView.fillSuperview()
		self.displayImageView.fillSuperview()
        self.displayImageView.progressView.anchorInCenter(withWidth: 20, height: 20)
		self.selectedBackgroundView?.fillSuperview()
	}
}
