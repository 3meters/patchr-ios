//
//  AirTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/18/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class AirTextFieldCell: AirTableViewCell {
    
    var textField = UITextField()
	
	override init () {
		super.init(style: .default, reuseIdentifier: nil)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textField.fillSuperview()
    }
	
	override func initialize() {
        super.initialize()
        self.accessoryType = .none
        self.contentView.addSubview(self.textField)
	}
}
