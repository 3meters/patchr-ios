//
//  Log.swift
//  Patchr
//
//  Created by Jay Massena on 7/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import CocoaLumberjack

struct Log {
    static func v(message: AnyObject?) {
        #if DEBUG
			if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Verbose.rawValue {
				DDLogVerbose(message)
			}
        #endif
    }
	
    static func d(message: AnyObject?) {
        #if DEBUG
			if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Debug.rawValue {
				DDLogDebug(message)
			}
        #endif
    }
	
    static func i(message: AnyObject?) {
		if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Info.rawValue {
			DDLogInfo(message)
		}
    }
	
    static func w(message: AnyObject?) {
		if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Warning.rawValue {
			DDLogWarn(message)
		}
    }
	
	static func e(message: AnyObject?) {
		if let message = message as? String where LOG_LEVEL.rawValue >= DDLogLevel.Error.rawValue {
			DDLogError(message)
		}
	}
}