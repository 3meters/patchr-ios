//
//  AirTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirTableViewCell: UITableViewCell {
	
	var view: BaseView?
	var separator = UIView()
	var padding = UIEdgeInsetsZero
	
	init(view: UIView, padding: UIEdgeInsets, reuseIdentifier: String?) {
		super.init(style: .Default, reuseIdentifier: reuseIdentifier)
		self.view = view as? BaseView
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
		self.view?.fillSuperviewWithLeftPadding(self.padding.left,
			rightPadding: self.padding.right,
			topPadding: self.padding.top,
			bottomPadding: self.padding.bottom + 1)
		
		self.separator.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 1)
	}
	
	func addSeparator() {
		self.separator.layer.backgroundColor = Colors.separatorColor.CGColor
		self.contentView.addSubview(self.separator)
	}
	
	override func prepareForReuse() {
		self.view?.prepareForRecycle()
	}
}
