//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import AVFoundation
import UIKit

struct DateUtils {
	
	static func now() -> Int64 {
        /* Now in milliseconds: Double -> Int64 */
		return Int64(Date().timeIntervalSince1970 * 1000)
	}
    
    static func nowTimeInterval() -> TimeInterval {
        /* Now in seconds: TimeInterval is alias for Double */
        return Date().timeIntervalSince1970
    }

    static func from(timestamp: Int64) -> Date {
        /* Reduce precision to seconds */
        return Date(timeIntervalSince1970: Double(timestamp / 1000))
    }
    
    static func dateMediumString(timestamp: Int64) -> String {
        let dateFormatter = DateFormatter()
        let date = from(timestamp: timestamp)
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date as Date)
    }
    
    static func timeAgoShort(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        if (date as NSDate).monthsAgo() >= 1 {
            return dateFormatter.string(from: date as Date)
        }
        else {
            return (date as NSDate).shortTimeAgoSinceNow()
        }
    }
}

extension Date {
    var milliseconds: Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    var seconds: Int {
        return Int(self.timeIntervalSince1970)
    }
}
