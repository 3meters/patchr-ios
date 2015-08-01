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
                println(message!)
            }
        #endif
    }
    static func d(message: AnyObject?) {
        #if DEBUG
            if message != nil {
                println(message!)
            }
        #endif
    }
    static func i(message: AnyObject?) {
        if message != nil {
            println(message!)
        }
    }
    static func w(message: AnyObject?) {
        if message != nil {
            println(message!)
        }
    }
}