//
//  AirTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class WrapperTableViewCell: UITableViewCell {
	
	var view				: UIView?
	var separator			= UIView()
	var padding				= UIEdgeInsets.zero
	
	init(view: UIView, padding: UIEdgeInsets, reuseIdentifier: String?) {
		super.init(style: .default, reuseIdentifier: reuseIdentifier)
		self.view = view
		self.padding = padding
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func initialize() {
		addSeparator()
		if self.view != nil {
			self.contentView.addSubview(self.view!)
		}
	}
	
	override func layoutSubviews() {
		
		/* Fill contentView with injected view */
		self.view?.fillSuperview(withLeftPadding: self.padding.left,
			rightPadding: self.padding.right,
			topPadding: self.padding.top,
			bottomPadding: self.padding.bottom + 1)
		
		self.selectedBackgroundView?.fillSuperview()
		self.separator.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 1)
	}
	
	func addSeparator() {
		self.separator.layer.backgroundColor = Theme.colorSeparator.cgColor
        self.contentView.addSubview(self.separator)
	}
}
