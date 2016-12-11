//
//  AirTextField.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class FloatTextField: SkyFloatingLabelTextField, UITextFieldDelegate {
    
    var fieldDelegate: UITextFieldDelegate?
	
	required init(coder aDecoder: NSCoder) {
		/* Called when instantiated from XIB or Storyboard */
		super.init(coder: aDecoder)!
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	func initialize() {
        
        self.delegate = self
        
        /* Fonts */
		self.font = Theme.fontText
        self.titleLabel.font = Theme.fontFloatTitle
        
        /* Colors */
        self.titleColor = Theme.colorTextPlaceholder
        self.placeholderColor = Theme.colorTextPlaceholder
		self.textColor = Theme.colorText
        self.lineColor = Theme.colorRule
        self.selectedTitleColor = Colors.accentColorTextLight
        self.selectedLineColor = Colors.accentColorTextLight
        self.errorColor = Theme.colorTextValidationError
        
        self.titleFormatter = { (text: String) -> String in
            return text
        }
        
		self.clearButtonMode = UITextFieldViewMode.whileEditing
	}
    
    func setDelegate(delegate: UITextFieldDelegate) {
        self.fieldDelegate = delegate
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.errorMessage = nil
        if let delegate = self.fieldDelegate {
            return delegate.textFieldShouldClear?(textField) ?? true
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.errorMessage = nil
        if let delegate = self.fieldDelegate {
            delegate.textFieldDidBeginEditing?(textField)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let delegate = self.fieldDelegate {
            delegate.textFieldDidEndEditing?(textField)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let delegate = self.fieldDelegate {
            return delegate.textFieldShouldReturn?(textField) ?? true
        }
        return true
    }
}
