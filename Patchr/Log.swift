//
//  Log.swift
//  Patchr
//
//  Created by Jay Massena on 7/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FirebaseCrash

class Log {
    
    static func prepare() {
        
        /* Logging */
        DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
//        DDASLLogger.sharedInstance().colorsEnabled = true
//        DDASLLogger.sharedInstance().setForegroundColor(Theme.colorLogVerbose, backgroundColor: nil, for: DDLogFlag.verbose)
//        DDASLLogger.sharedInstance().setForegroundColor(Theme.colorLogDebug, backgroundColor: nil, for: DDLogFlag.debug)
//        DDASLLogger.sharedInstance().setForegroundColor(Theme.colorLogInfo, backgroundColor: nil, for: DDLogFlag.info)
//        DDASLLogger.sharedInstance().setForegroundColor(Theme.colorLogWarning, backgroundColor: nil, for: DDLogFlag.warning)
//        DDASLLogger.sharedInstance().setForegroundColor(Theme.colorLogError, backgroundColor: nil, for: DDLogFlag.error)
    }
    
	static func v(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
            if Config.logLevel == LogLevel.verbose {
                DDLogVerbose(message)
            }
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func d(_ message: String, breadcrumb: Bool = false) {
        #if DEBUG
            if Config.logLevel <= LogLevel.debug {
                DDLogDebug(message)
            }
        #endif
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func i(_ message: String, breadcrumb: Bool = false) {
        if Config.logLevel <= LogLevel.info {
            DDLogInfo(message)
        }
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
    static func w(_ message: String, breadcrumb: Bool = false) {
        if Config.logLevel <= LogLevel.warning {
            DDLogWarn(message)
        }
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
    }
	
	static func e(_ message: String, breadcrumb: Bool = false) {
        if Config.logLevel <= LogLevel.error {
            DDLogError(message)
        }
		if breadcrumb {
			Log.breadcrumb(message: message);
		}
	}
	
	static func breadcrumb(message: String!) {
		/* Requited to call on the main thread */
		OperationQueue.main.addOperation {
            FirebaseCrashMessage(message)
		}
	}
}
