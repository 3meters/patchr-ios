//
//  PhotoChooserUI.swift
//  Patchr
//
//  Created by Brent on 2015-03-03.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

// Opportunity here to make this generic.

class TextFieldChangeObserver {
    var observerObject: NSObjectProtocol
    
    init(_ textField: UITextField, action: () -> ()) {
        observerObject = NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: nil) {
            note in
            action()
        }
    }
    
    func stopObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(observerObject)
    }
}