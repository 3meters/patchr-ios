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

var temporaryFileCount = 0

struct Utils {
    
    static func LocalizedString(str: String, comment: String) -> String {
        return NSLocalizedString(str, comment: comment)
    }
    
    static func LocalizedString(str: String) -> String {
        return LocalizedString("[]" + str, comment: str)
    }
    
    static func DateTimeTag() -> String! {
        let date = NSDate()
        let globalGregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        
        if let dc = globalGregorianCalendar?.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay |
            .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: date) {
                return String(format: "%04d%02d%02d_%02d%02d%02d", dc.year, dc.month, dc.day, dc.hour, dc.minute, dc.second)
        }
        return nil
    }
    
    static func TemporaryFileURLForImage(image: UIImage) -> NSURL? {
        
        if let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.70) {
            /* 
             * Note: This method of getting a temporary file path is not the recommended method. See the docs for NSTemporaryDirectory. 
             */
            let temporaryFilePath = NSTemporaryDirectory() + "patchr_temp_file_\(temporaryFileCount).jpg"
            println(temporaryFilePath)
            
            if imageData.writeToFile(temporaryFilePath, atomically: false) {
                return NSURL(fileURLWithPath: temporaryFilePath)
            }
        }
        return nil
    }
    
    static func prepareImage(var image: UIImage) -> UIImage {
        var scalingNeeded: Bool = (image.size.width > 1280 || image.size.height > 1280)
        if (scalingNeeded) {
            let rect: CGRect = AVMakeRectWithAspectRatioInsideRect(image.size, CGRectMake(0, 0, 1280, 1280))
            image = image.resizeTo(rect.size)
        }
        else {
            image = image.normalizedImage()
        }
        return image
    }
    
    static func updateRecents(recent: [String:AnyObject]) {
        
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            if var recentPatches = groupDefaults.arrayForKey(PatchrUserDefaultKey("recent.patches")) as? [[String:AnyObject]] {
        
                /* Replace if found else append */
                var index = 0
                var found = false
                for item in recentPatches {
                    if (item["id_"] as! String) == (recent["id_"] as! String) {
                        recentPatches[index] = recent
                        found = true
                        break
                    }
                    index++
                }
                
                if !found {
                    recentPatches.append(recent)
                }
                
                /* Sort descending */
                recentPatches.sort {
                    item1, item2 in
                    let date1 = item1["recentDate"] as! Int
                    let date2 = item2["recentDate"] as! Int
                    return date1 > date2 // > descending, < for ascending
                }
                
                /* Trim to 10 most recent */
                if recentPatches.count > 10 {
                    recentPatches = Array(recentPatches[0..<10])
                }
                
                groupDefaults.setObject(recentPatches, forKey:PatchrUserDefaultKey("recent.patches"))
            }
            else {
                groupDefaults.setObject([recent], forKey:PatchrUserDefaultKey("recent.patches"))
            }
        }
    }
}