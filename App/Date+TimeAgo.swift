//
//  Date+TimeAgo.swift
//  DateToolsTests
//
//  Created by Matthew York on 8/23/16.
//  Copyright © 2016 Matthew York. All rights reserved.
//

import Foundation
import Localize_Swift

/**
 *  Extends the Date class by adding convenient methods to display the passage of
 *  time in String format.
 */
public extension Date {
    
    //MARK: - Time Ago
    
    /**
     *  Takes in a date and returns a string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - parameter date: Date to be measured from now
     *
     *  - returns String - Formatted return string
     */
    public static func timeAgo(since date:Date) -> String{
        return date.timeAgo(since: Date(), numericDates: false, numericTimes: false)
    }
    
    /**
     *  Takes in a date and returns a shortened string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - parameter date: Date to be measured from now
     *
     *  - returns String - Formatted return string
     */
    public static func shortTimeAgo(since date:Date) -> String {
        return date.shortTimeAgo(since:Date())
    }
    
    /**
     *  Returns a string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - returns String - Formatted return string
     */
    public var timeAgoSinceNow: String {
        return self.timeAgo(since:Date())
    }
    
    /**
     *  Returns a shortened string with the most convenient unit of time representing
     *  how far in the past that date is from now.
     *
     *  - returns String - Formatted return string
     */
    public var shortTimeAgoSinceNow: String {
        return self.shortTimeAgo(since:Date())
    }
    
    public func timeAgo(since date:Date, numericDates: Bool = false, numericTimes: Bool = false) -> String {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.second,.minute,.hour,.day,.weekOfYear,.month,.year])
        let earliest = self.earlierDate(date)
        let latest = (earliest == self) ? date : self //Should be triple equals, but not extended to Date at this time
        
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        let isYesterday = calendar.isDateInYesterday(date)
        
        //Not Yet Implemented/Optional
        //The following strings are present in the translation files but lack logic as of 2014.04.05
        //@"Today", @"This week", @"This month", @"This year"
        //and @"This morning", @"This afternoon"
        
        if (components.year! >= 2) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@years ago", value: components.year!)
        }
        else if (components.year! >= 1) {
            if (numericDates) {
                return DateToolsLocalizedStrings("1 year ago");
            }
            return DateToolsLocalizedStrings("Last year");
        }
        else if (components.month! >= 2) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@months ago", value: components.month!)
        }
        else if (components.month! >= 1) {
            if (numericDates) {
                return DateToolsLocalizedStrings("1 month ago");
            }
            return DateToolsLocalizedStrings("Last month");
        }
        else if (components.weekOfYear! >= 2) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@weeks ago", value: components.weekOfYear!)
        }
        else if (components.weekOfYear! >= 1) {
            if (numericDates) {
                return DateToolsLocalizedStrings("1 week ago");
            }
            return DateToolsLocalizedStrings("Last week");
        }
        else if (components.day! >= 2) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@days ago", value: components.day!)
        }
        else if (components.day! == 1) {
            if (isYesterday) {
                if (numericDates) {
                    return DateToolsLocalizedStrings("1 day ago");
                }
                return DateToolsLocalizedStrings("Yesterday");
            }
            else {
                return self.logicalLocalizedStringFromFormat(format: "%%d %@days ago", value: 2)
            }
        }
        else if (components.hour! >= 2) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@hours ago", value: components.hour!)
        }
        else if (components.hour! >= 1) {
            if (numericTimes) {
                return DateToolsLocalizedStrings("1 hour ago");
            }
            return DateToolsLocalizedStrings("An hour ago");
        }
        else if (components.minute! >= 2) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@minutes ago", value: components.minute!)
        }
        else if (components.minute! >= 1) {
            if (numericTimes) {
                return DateToolsLocalizedStrings("1 minute ago");
            }
            return DateToolsLocalizedStrings("A minute ago");
        }
        else if (components.second! >= 3) {
            return self.logicalLocalizedStringFromFormat(format: "%%d %@seconds ago", value: components.second!)
        }
        else {
            if (numericTimes) {
                return DateToolsLocalizedStrings("1 second ago");
            }
            return DateToolsLocalizedStrings("Just now");
        }
    }
    
    public func shortTimeAgo(since date:Date) -> String {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.second,.minute,.hour,.day,.weekOfYear,.month,.year])
        let earliest = self.earlierDate(date)
        let latest = (earliest == self) ? date : self // Should be triple equals, but not extended to Date at this time
        
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        
        if (components.year! >= 1) {
            return String.init(format: DateToolsLocalizedStrings("%dy"), components.year!)
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@y", value: components.year!)
        }
        else if (components.weekOfYear! >= 1) {
            return String.init(format: DateToolsLocalizedStrings("%dw"), components.weekOfYear!)
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@w", value: components.weekOfYear!)
        }
        else if (components.day! >= 1) {
            return String.init(format: DateToolsLocalizedStrings("%dd"), components.day!)
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@d", value: components.day!)
        }
        else if (components.hour! >= 1) {
            return String.init(format: DateToolsLocalizedStrings("%dh"), components.hour!)
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@h", value: components.hour!)
        }
        else if (components.minute! >= 1) {
            return String.init(format: DateToolsLocalizedStrings("%dm"), components.minute!)
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@m", value: components.minute!)
        }
        else if (components.second! >= 3) {
            return String.init(format: DateToolsLocalizedStrings("%ds"), components.second!)
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@s", value: components.second!)
        }
        else {
            return DateToolsLocalizedStrings("now")
            // jayma: return self.logicalLocalizedStringFromFormat(format: "%%d%@s", value: components.second!)
        }
    }
    
    private func logicalLocalizedStringFromFormat(format: String, value: Int) -> String{
        #if os(Linux)
            let localeFormat = String.init(format: format, getLocaleFormatUnderscoresWithValue(Double(value)) as! CVarArg)  // this may not work, unclear!!
        #else
            let localeFormat = String.init(format: format, getLocaleFormatUnderscoresWithValue(Double(value)))
        #endif
        
        return String.init(format: DateToolsLocalizedStrings(localeFormat), value)
    }
    
    private func getLocaleFormatUnderscoresWithValue(_ value: Double) -> String{
        // jayma: let localCode = Bundle.main.preferredLocalizations[0]
        let localCode = Localize.currentLanguage()
        if (localCode == "ru" || localCode == "uk") {
            let XY = Int(floor(value).truncatingRemainder(dividingBy: 100))
            let Y = Int(floor(value).truncatingRemainder(dividingBy: 10))
            
            if(Y == 0 || Y > 4 || (XY > 10 && XY < 15)) {
                return ""
            }
            
            if(Y > 1 && Y < 5 && (XY < 10 || XY > 20))  {
                return "_"
            }
            
            if(Y == 1 && XY != 11) {
                return "__"
            }
        }
        return ""
    }
    
    // MARK: - Localization
    
    private func DateToolsLocalizedStrings(_ string: String) -> String {
        //let classBundle = Bundle(for:TimeChunk.self as! AnyClass.Type).resourcePath!.appending("DateTools.bundle")
        //let bundelPath = Bundle(path:classBundle)!
        #if os(Linux)
        // NSLocalizedString() is not available yet, see: https://github.com/apple/swift-corelibs-foundation/blob/16f83ddcd311b768e30a93637af161676b0a5f2f/Foundation/NSData.swift
        // However, a seemingly-equivalent method from NSBundle is: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/NSBundle.swift
            // jayma: return Bundle.main.localizedString(forKey: string, value: "", table: "DateTools")
            return string.localized(using: "DateTools")
        #else
            // jayma: return NSLocalizedString(string, tableName: "DateTools", value: "", comment: "")
            return string.localized(using: "DateTools")
        #endif
    }
    
    // MARK: - Date Earlier/Later
    
    /**
     *  Return the earlier of two dates, between self and a given date.
     *  
     *  - parameter date: The date to compare to self
     *  - returns: The date that is earlier
     */
    public func earlierDate(_ date:Date) -> Date{
        return (self.timeIntervalSince1970 <= date.timeIntervalSince1970) ? self : date
    }
    
    /**
     *  Return the later of two dates, between self and a given date.
     *
     *  - parameter date: The date to compare to self
     *  - returns: The date that is later
     */
    public func laterDate(_ date:Date) -> Date{
        return (self.timeIntervalSince1970 >= date.timeIntervalSince1970) ? self : date
    }
}
