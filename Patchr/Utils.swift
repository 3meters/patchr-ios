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

var temporaryFileCount = 0

struct Utils {
	
	static var imageMedia: UIImage = { return UIImage(named: "imgMediaLight") }()!
	static var imageMessage: UIImage = { return UIImage(named: "imgMessageLight") }()!
	static var imageWatch: UIImage = { return UIImage(named: "imgWatchLight") }()!
	static var imageStar: UIImage = { return UIImage(named: "imgStarFilledLight") }()!
	static var imageLike: UIImage = { return UIImage(named: "imgLikeLight") }()!
	static var imageShare: UIImage = { return UIImage(named: "imgShareLight") }()!
	static var imageLocation: UIImage = { return UIImage(named: "imgLocationLight") }()!
	static var imageHeartOn: UIImage = { return UIImage(named: "imgHeartFilledLight") }()!
	static var imageHeartOff: UIImage = { return UIImage(named: "imgHeartLight") }()!
	static var imageBroken: UIImage = { return UIImage(named: "imgBroken250Light") }()!
	static var imageDefaultPatch: UIImage = { return UIImage(named: "imgDefaultPatch") }()!
	static var imageDefaultUser: UIImage = { return UIImage(named: "imgDefaultUser") }()!
	static var imageEdit: UIImage = { return UIImage(named: "imgEdit2Light") }()!
	static var imagePatch: UIImage = { return UIImage(named: "imgPatchLight") }()!
	static var imageRemove: UIImage = { return UIImage(named: "imgRemoveLight") }()!
	static var imageLock: UIImage = { return UIImage(named: "imgLockLight") }()!
	
	static var spacer: UIBarButtonItem = {
		let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
		spacer.width = 12
		return spacer
	}()

    static var messageDateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
	
	static func encodeForUrlQuery(target: String) -> String {
		return target.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
	}
	
	static func synced(lock: AnyObject, closure: () -> ()) {
		objc_sync_enter(lock)
		closure()
		objc_sync_exit(lock)
	}
	
	static func LocalizedString(str: String) -> String {
		return LocalizedString(str, comment: str)
	}
	
    static func LocalizedString(str: String, comment: String) -> String {
        return NSLocalizedString(str, comment: comment)
    }
    
    static func DateTimeTag() -> String! {
        let date = NSDate()     			// Initialized to current date
		let calendar = NSCalendar.currentCalendar() // System caches currentCalendar as of iOS 7
        let components = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second, .Nanosecond], fromDate: date)
        let milliSeconds = components.nanosecond / 1_000_000
        let dateTimeTag = String(format: "%04d%02d%02d_%02d%02d%02d_%04d", components.year, components.month, components.day, components.hour, components.minute, components.second, milliSeconds)
        return dateTimeTag
    }

	static func genSalt() -> Int {
		// random number (change the modulus to the length you'd like)
		return Int(arc4random() % 1000000)
	}

	static func genImageKey() -> String {
        /* 20150126_095004_670196.jpg */
        let imageKey = "\(Utils.DateTimeTag())_\(Utils.genSalt())"
        return imageKey
    }
	
	static func initialsFromName(fullname: String) -> String {
		let words = fullname.componentsSeparatedByString(" ")
		var initials = ""
		for word in words {
			initials.append(word[0])
		}
		return initials.length > 2 ? initials[0...1] : initials
	}
	
	static func numberFromName(fullname: String) -> UInt32 {
		var accum: UInt32 = 0
		for character in fullname.characters {
			let s = (String(character).unicodeScalars)
			accum += s[s.startIndex].value
		}
		return accum
	}
	
	static func randomColor(seed: UInt32?) -> UIColor {
		if seed != nil {
			srand(seed!)
			let hue = CGFloat(Double(rand() % 256) / 256.0) // 0.0 to 1.0
			let saturation = CGFloat(Double(rand() % 128) / 266.0 + 0.5) // 0.5 to 1.0, away from white
			let brightness = CGFloat(Double(rand() % 128) / 256.0 + 0.5) // 0.5 to 1.0, away from black
			return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		}
		else {
			let hue = CGFloat(Double(arc4random() % 256) / 256.0) // 0.0 to 1.0
			let saturation = CGFloat(Double(arc4random() % 128) / 266.0 + 0.5) // 0.5 to 1.0, away from white
			let brightness = CGFloat(Double(arc4random() % 128) / 256.0 + 0.5) // 0.5 to 1.0, away from black
			return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		}
	}

    static func TemporaryFileURLForImage(image: UIImage, name: String, shared: Bool = false) -> NSURL? {
        
        var imageDirectoryURL: NSURL!
        
        if shared {
            if let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.3meters.patchr.ios") {
                
                do {
                    let containerURLWithName = containerURL.URLByAppendingPathComponent(name)
                    if !NSFileManager.defaultManager().fileExistsAtPath(containerURLWithName.path!) {
                        let pathString = containerURL.path!
                        try NSFileManager.defaultManager().createDirectoryAtPath(pathString, withIntermediateDirectories: false, attributes: nil)
                    }
                }
                catch let error as NSError {
                    Log.d("\(error.localizedDescription)")
                }
                
                imageDirectoryURL = containerURL
                imageDirectoryURL = imageDirectoryURL.URLByAppendingPathComponent(name)
                imageDirectoryURL = imageDirectoryURL.URLByAppendingPathExtension("jpg")
            }
        }
        else {
            let temporaryFilePath = NSTemporaryDirectory() + "patchr_temp_file_\(name).jpg"
            imageDirectoryURL = NSURL(fileURLWithPath: temporaryFilePath)
        }
        
        if let imageData: NSData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.70) {
            if imageData.writeToFile(imageDirectoryURL.path!, atomically: true) {
                return imageDirectoryURL
            }
        }
        
        return nil
    }
    
    static func prepareImage(var image: UIImage) -> UIImage {
        let scalingNeeded: Bool = (image.size.width > IMAGE_DIMENSION_MAX || image.size.height > IMAGE_DIMENSION_MAX)
        if (scalingNeeded) {
            let rect: CGRect = AVMakeRectWithAspectRatioInsideRect(image.size, CGRectMake(0, 0, IMAGE_DIMENSION_MAX, IMAGE_DIMENSION_MAX))
            image = image.resizeTo(rect.size)
        }
        else {
            image = image.normalizedImage()
        }
        return image
    }
	
	static func clearHistory() {
		let defaults = NSUserDefaults.standardUserDefaults()
		defaults.setObject(nil, forKey:PatchrUserDefaultKey("recent.searches"))
		if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
			groupDefaults.setObject(nil, forKey:PatchrUserDefaultKey("recent.patches"))
			groupDefaults.setObject(nil, forKey:PatchrUserDefaultKey("nearby.patches"))
		}
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
                recentPatches.sortInPlace {
                    item1, item2 in
                    let date1: Int64 = (item1["recentDate"] as! NSNumber).longLongValue
                    let date2: Int64 = (item2["recentDate"] as! NSNumber).longLongValue
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
	
	static func updateSearches(search: String) {
		
		let defaults = NSUserDefaults.standardUserDefaults()
		if var searches = defaults.arrayForKey(PatchrUserDefaultKey("recent.searches")) as? [String] {
			
			/* Replace if found else append */
			var index = 0
			var found = false
			for item in searches {
				if (item == search) {
					searches[index] = search
					found = true
					break
				}
				index++
			}
			
			if !found {
				searches.append(search)
			}
			
			defaults.setObject(searches, forKey:PatchrUserDefaultKey("recent.searches"))
		}
		else {
			defaults.setObject([search], forKey:PatchrUserDefaultKey("recent.searches"))
		}
	}
	
    static func updateNearbys(nearby: [NSObject: AnyObject]) -> [[NSObject:AnyObject]] {
		
        let nearbys: [[NSObject:AnyObject]] = [nearby]
		
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
            if var storedNearbys = groupDefaults.arrayForKey(PatchrUserDefaultKey("nearby.patches")) as? [[NSObject:AnyObject]] {
				
                storedNearbys.append(nearby)
				
                /* Sort descending */
                storedNearbys.sortInPlace {
                    item1, item2 in
                    let date1: Int64 = (item1["sentDate"] as! NSNumber).longLongValue
                    let date2: Int64 = (item2["sentDate"] as! NSNumber).longLongValue
                    return date1 > date2 // > descending, < for ascending
                }
                
                /* Trim to 10 most recent */
                if storedNearbys.count > 10 {
                    storedNearbys = Array(storedNearbys[0..<10])
                }
                
                groupDefaults.setObject(storedNearbys, forKey:PatchrUserDefaultKey("nearby.patches"))
                return storedNearbys
            }
            else {
                groupDefaults.setObject(nearbys, forKey:PatchrUserDefaultKey("nearby.patches"))
            }
        }
        return nearbys
    }
    
    static func delay(delay: Double, closure: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW
            , Int64(delay * Double(NSEC_PER_SEC)))
            , dispatch_get_main_queue()
            , closure)
    }

	static func now() -> Int64 {
		return Int64(NSDate().timeIntervalSince1970 * 1000)
	}
}

extension NSDate {
	var milliseconds: Int64 {
		return Int64(self.timeIntervalSince1970 * 1000)
	}
}

extension String {
	
	var length: Int {
		return characters.count
	}
		
	subscript (i: Int) -> Character {
		return self[self.startIndex.advancedBy(i)]
	}
	
	subscript (i: Int) -> String {
		return String(self[i] as Character)
	}
	
	subscript (r: Range<Int>) -> String {
		return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
	}
}
