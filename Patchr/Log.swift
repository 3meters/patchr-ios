//
//  Log.swift
//  Patchr
//
//  Created by Jay Massena on 7/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

struct Log {
    static func v(message: AnyObject?) {
        #if DEBUG
            if message != nil {
				NSLog(message! as! String)
            }
        #endif
    }
    static func d(message: AnyObject?) {
        #if DEBUG
            if message != nil {
                NSLog(message! as! String)
            }
        #endif
    }
    static func i(message: AnyObject?) {
        if message != nil {
			NSLog(message! as! String)
        }
    }
    static func w(message: AnyObject?) {
        if message != nil {
			NSLog(String(message as! NSString))
        }
    }
}