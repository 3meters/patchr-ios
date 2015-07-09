//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC
import Fabric
import Crashlytics

let globalGregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)

var temporaryFileCount = 0

struct Utils {
    
    static func LocalizedString(str: String, comment: String) -> String {
        return NSLocalizedString(str, comment: comment)
    }
    
    static func LocalizedString(str: String) -> String {
        return LocalizedString("[]" + str, comment: str)
    }
    
    static func PatchrUserDefaultKey(subKey: String) -> String {
        return NAMESPACE + subKey
    }
    
    static func DateTimeTag() -> String! {
        let date = NSDate()
        
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
    
    static func updateCrashKeys() {
        
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().value
        if networkStatus == 0 {
            Crashlytics.sharedInstance().setBoolValue(false, forKey: "connected")
        }
        else {
            Crashlytics.sharedInstance().setBoolValue(true, forKey: "connected")
            if networkStatus == 1 {
                Crashlytics.sharedInstance().setObjectValue("wifi", forKey: "network_type")
            }
            else if networkStatus == 2 {
                Crashlytics.sharedInstance().setObjectValue("wwan", forKey: "network_type")
            }
        }

        /* Identifies device/install combo */
        Crashlytics.sharedInstance().setObjectValue(DataController.proxibase.installationIdentifier, forKey: "install_id")
        
        /* Location info */
        let location: CLLocation? = LocationController.instance.currentLocation()
        if location != nil {
            var eventDate = location!.timestamp
            var howRecent = abs(trunc(eventDate.timeIntervalSinceNow * 100) / 100)
            Crashlytics.sharedInstance().setFloatValue(Float(location!.horizontalAccuracy), forKey: "location_accuracy")
            Crashlytics.sharedInstance().setIntValue(Int32(howRecent), forKey: "location_age")
        }
        else {
            Crashlytics.sharedInstance().setFloatValue(0, forKey: "location_accuracy")
            Crashlytics.sharedInstance().setIntValue(0 , forKey: "location_age")
        }
    }
    
    static func updateCrashUser(user: User?) {
        if user != nil {
            Crashlytics.sharedInstance().setUserIdentifier(user!.id_)
            Crashlytics.sharedInstance().setUserName(user!.name)
            Crashlytics.sharedInstance().setUserEmail(user!.email)
        }
        else {
            Crashlytics.sharedInstance().setUserIdentifier(nil)
            Crashlytics.sharedInstance().setUserName(nil)
            Crashlytics.sharedInstance().setUserEmail(nil)
        }
    }
    
    static func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().value
        return networkStatus != 0
    }
}