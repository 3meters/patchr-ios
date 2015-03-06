//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

func LocalizedString(str: String, comment:String) -> String
{
    return NSLocalizedString(str, comment: comment)
}

func LocalizedString(str: String) -> String
{
    return LocalizedString("[]"+str, str)
}

// Utility to show some information about subview frames.

func showSubviews(view: UIView, level: Int = 0)
{
    var indent = ""
    for i in 0..<level {
        indent += "  "
    }
    var count = 0
    for subview in view.subviews {
        println("\(indent)\(count++). \(subview.frame)")
        showSubviews(subview as UIView, level: level + 1)
    }
}

func PatchrUserDefaultKey(subKey: String) -> String
{
    return "com.3meters.patchr.ios." + subKey
}

let globalGregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)

public func DateTimeTag() -> String!
{
    let date = NSDate()

    if let dc = globalGregorianCalendar?.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay |
                                                    .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
    {
        return String(format:"%04d%02d%02d_%02d%02d%02d", dc.year, dc.month, dc.day, dc.hour, dc.minute, dc.second)
    }
    return nil
}

var temporaryFileCount = 0

func TemporaryFileURLForImage(image: UIImage) -> NSURL?
{
    let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.75)
    if let imageData = imageData {
    
        // Note: This method of getting a temporary file path is not the recommended method. See the docs for NSTemporaryDirectory.
        let temporaryFilePath = NSTemporaryDirectory() + "patchr_temp_file_\(temporaryFileCount).jpg"
        println(temporaryFilePath)
        
        if imageData.writeToFile(temporaryFilePath, atomically: false) {
            return NSURL(fileURLWithPath: temporaryFilePath)
        }
    }
    return nil
}

