//
//  PhotoChooserUI.swift
//  Patchr
//
//  Created by Brent on 2015-03-03.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

// Opportunity here to make this generic.

class TextViewChangeObserver {
    var observerObject: NSObjectProtocol
    
    init(_ textView: UITextView, action: () -> ()) {
        observerObject = NSNotificationCenter.defaultCenter().addObserverForName(UITextViewTextDidChangeNotification, object: textView, queue: nil) {
            note in
            
            action()
        }
    }
    
    func stopObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(observerObject)
    }
    
    deinit {
        print("-- deinit Change observer")
    }
}