//
//  BaseView.swift
//  Patchr
//
//  Created by Jay Massena on 8/6/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class BaseView: UIView {
	
	var cell: UITableViewCell?
	var entity: Entity?
	
	override func sizeThatFits(size: CGSize) -> CGSize {
		self.bounds.size.width = size.width
		self.setNeedsLayout()
		self.layoutIfNeeded()
		return sizeThatFitsSubviews()
	}
}

enum CellType: String {
	case Text = "text"
	case Photo = "photo"
	case TextAndPhoto = "text_and_photo"
	case Share = "share"
}