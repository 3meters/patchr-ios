//
//  UserView.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class SearchViewCell: UITableViewCell {

	var title			= AirLabelDisplay()
	var subtitle		= AirLabelDisplay()
	var photo			= AirImageView(frame: CGRectZero)

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		/* Called when instantiated from storyboard or nib */
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		
		self.clipsToBounds = true

		/* User photo */
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.clipsToBounds = true
		self.photo.layer.cornerRadius = 24
		self.photo.layer.backgroundColor = Theme.colorBackgroundImage.CGColor
		self.photo.sizeCategory = SizeCategory.profile
		self.addSubview(self.photo)

		/* User name */
		self.title.lineBreakMode = .ByTruncatingMiddle
		self.title.font = Theme.fontTextDisplay
		self.addSubview(self.title)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.title.anchorTopLeftWithLeftPadding(6, topPadding: 6, width: self.width() - 64, height: 40)
		self.photo.anchorTopRightWithRightPadding(2, topPadding: 2, width: 48, height: 48)
	}
}