//
//  UserView.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class UserSearchViewCell: UITableViewCell {

	var title			= AirLabelDisplay()
	var subtitle		= AirLabelDisplay()
	var photo			= UserPhotoView()

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
		self.addSubview(self.photo)

		/* User name */
		self.title.lineBreakMode = .byTruncatingMiddle
		self.title.font = Theme.fontTextDisplay
		self.addSubview(self.title)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.title.anchorTopLeft(withLeftPadding: 6, topPadding: 6, width: self.width() - 64, height: 40)
		self.photo.anchorTopRight(withRightPadding: 2, topPadding: 2, width: 48, height: 48)
	}
}
