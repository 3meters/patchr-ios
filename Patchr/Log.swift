//
//  Log.swift
//  Patchr
//
//  Created by Jay Massena on 7/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import Bugsnag
import CocoaLumberjack

class Log {
    
    static func prepare() {
        
        /* Logging */
        DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
//        DDLog.add(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
        DDTTYLogger.sharedInstance().colorsEnabled = true
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogVerbose, backgroundColor: nil, for: DDLogFlag.verbose)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogDebug, backgroundColor: nil, for: DDLogFlag.debug)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogInfo, backgroundColor: nil, for: DDLogFlag.info)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogWarning, backgroundColor: nil, for: DDLogFlag.warning)
        DDTTYLogger.sharedInstance().setForegroundColor(Theme.colorLogError, backgroundColor: nil, for: DDLogFlag.error)
        
//        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
//        fileLogger.rollingFrequency = 60 * 60 * 24  // 24 hours
//        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
//        DDLog.add(fileLogger)
    }
    
	static func v(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
            DDLogVerbose("Verbose")
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func d(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
            DDLogDebug(message)
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func i(_ message: String, breadcrumb: Bool = false) {
        DDLogInfo(message)
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func w(_ message: String, breadcrumb: Bool = false) {
        DDLogWarn(message)
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
	static func e(_ message: String, breadcrumb: Bool = false) {
        DDLogError(message)
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
