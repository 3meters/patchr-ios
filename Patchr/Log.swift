//
//  Log.swift
//  Patchr
//
//  Created by Jay Massena on 7/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import CocoaLumberjack
import Bugsnag

struct Log {
	static func v(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
			if LOG_LEVEL.rawValue >= DDLogLevel.verbose.rawValue {
				DDLogVerbose(message)
			}
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func d(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
			if LOG_LEVEL.rawValue >= DDLogLevel.debug.rawValue {
				DDLogDebug(message)
			}
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func i(_ message: String, breadcrumb: Bool = false) {
		if LOG_LEVEL.rawValue >= DDLogLevel.info.rawValue {
			DDLogInfo(message)
		}
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func w(_ message: String, breadcrumb: Bool = false) {
		if LOG_LEVEL.rawValue >= DDLogLevel.warning.rawValue {
			DDLogWarn(message)
		}
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
	static func e(_ message: String, breadcrumb: Bool = false) {
		if LOG_LEVEL.rawValue >= DDLogLevel.error.rawValue {
			DDLogError(message)
		}
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
