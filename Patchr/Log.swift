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
			if let message = message as? String {
				NSLog("%@", message)
			}
        #endif
    }
    static func d(message: AnyObject?) {
        #if DEBUG
			if let message = message as? String {
				NSLog("%@", message)
			}
        #endif
    }
    static func i(message: AnyObject?) {
		if let message = message as? String {
			NSLog("%@", message)
		}
    }
    static func w(message: AnyObject?) {
		if let message = message as? String {
			NSLog("%@", message)
		}
    }
}