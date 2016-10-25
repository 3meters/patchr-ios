//
//  Log.swift
//  Patchr
//
//  Created by Jay Massena on 7/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import Bugsnag
import SwiftyBeaver

class Log {
    
    static func prepare() {
        let log = SwiftyBeaver.self
        let console = ConsoleDestination()
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $T $L: $M"
        console.levelString.verbose = "⚪️ VERBOSE"
        console.levelString.debug = "💙 DEBUG  "
        console.levelString.info = "💚 INFO   "
        console.levelString.warning = "💛 WARNING"
        console.levelString.error = "❤️ ERROR  "
        log.addDestination(console)
    }
    
	static func v(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
            SwiftyBeaver.self.verbose(message)
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func d(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
            SwiftyBeaver.self.debug(message)
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func i(_ message: String, breadcrumb: Bool = false) {
        SwiftyBeaver.self.info(message)
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func w(_ message: String, breadcrumb: Bool = false) {
        SwiftyBeaver.self.warning(message)
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
	static func e(_ message: String, breadcrumb: Bool = false) {
        SwiftyBeaver.self.error(message)
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
	}
	
	static func breadcrumb(message: String!) {
		/* Requited to call on the main thread */
		OperationQueue.main.addOperation {
			Bugsnag.leaveBreadcrumb(withMessage: message);
		}
	}
}
