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
	static func v(message: AnyObject?, breadcrumb: Bool = false) {
        #if DEBUG
			if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Verbose.rawValue {
				DDLogVerbose(message)
			}
        #endif
		if breadcrumb {
			if let message = message as? String {
				Log.breadcrumb(message);
			}
		}
    }
	
    static func d(message: AnyObject?, breadcrumb: Bool = false) {
        #if DEBUG
			if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Debug.rawValue {
				DDLogDebug(message)
			}
        #endif
		if breadcrumb {
			if let message = message as? String {
				Log.breadcrumb(message);
			}
		}
    }
	
    static func i(message: AnyObject?, breadcrumb: Bool = false) {
		if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Info.rawValue {
			DDLogInfo(message)
		}
		if breadcrumb {
			if let message = message as? String {
				Log.breadcrumb(message);
			}
		}
    }
	
    static func w(message: AnyObject?, breadcrumb: Bool = false) {
		if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Warning.rawValue {
			DDLogWarn(message)
		}
		if breadcrumb {
			if let message = message as? String {
				Log.breadcrumb(message);
			}
		}
    }
	
	static func e(message: AnyObject?, breadcrumb: Bool = false) {
		if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Error.rawValue {
			DDLogError(message)
		}
		if breadcrumb {
			if let message = message as? String {
				Log.breadcrumb(message);
			}
		}
	}
	
	static func breadcrumb(message: String!) {
		/* Requited to call on the main thread */
		NSOperationQueue.mainQueue().addOperationWithBlock {
			Bugsnag.leaveBreadcrumbWithMessage(message);
		}
	}
}