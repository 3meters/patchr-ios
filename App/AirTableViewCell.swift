//
//  AirTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirTableViewCell: UITableViewCell {
	
	init () {
		super.init(style: .value1, reuseIdentifier: nil)
		initialize()
	}
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		self.accessoryType = .disclosureIndicator
		self.textLabel!.font = Theme.fontTextDisplay
		self.textLabel!.textColor = Theme.colorText
	}
}
