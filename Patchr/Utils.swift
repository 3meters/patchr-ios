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
	static var imageStarOn: UIImage = { return UIImage(named: "imgStarFilledLight") }()!
    static var imageStarOff: UIImage = { return UIImage(named: "imgStarLight") }()!
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
	static var imageMuted: UIImage = { return UIImage(named: "imgSoundOff3Light") }()!
	
    static func genDateKey() -> String {
        let date = Date()     			// Initialized to current date
		let calendar = Calendar.current // System caches currentCalendar as of iOS 7
        let calComponents: Set<Calendar.Component> = Set([.year, .month, .day, .hour, .minute, .second, .nanosecond])
        let components = calendar.dateComponents(calComponents, from: date)
        let milliSeconds = components.nanosecond! / 1_000_000
        let dateKey = String(format: "%04d%02d%02d_%02d%02d%02d_%04d", components.year!, components.month!, components.day!, components.hour!, components.minute!, components.second!, milliSeconds)
        return dateKey
    }

	static func genSalt() -> Int {
		// random number (change the modulus to the length you'd like)
		return Int(arc4random() % 1000000)
	}

	static func genImageKey() -> String {
        /* 20150126_095004_670196.jpg */
        let imageKey = "\(Utils.genDateKey())_\(Utils.genSalt())"
        return imageKey
    }
    
    static func genRandomId() -> String {
        let charCount = 9
        let charSet = "abcdefghijklmnopqrstuvwxyz0123456789"
        let charSetSize = charSet.length
        var id = ""
        for _ in 1...charCount {
            let randPos = floorf(Float(arc4random_uniform(UInt32(charSetSize))))
            id += charSet[Int(randPos)]
        }
        return id
    }
	
    static func initialsFromName(fullname: String, count: Int? = 2) -> String {
        let words: [String] = fullname.components(separatedBy: " ")
		var initials = ""
		for word in words {
			if !word.isEmpty {
                let initial = String(word.characters.prefix(1)).uppercased()
				initials.append(initial)
                if initials.length >= count! {
                    break
                }
			}
		}
		return initials.length > 2 ? initials[0...1] : initials
	}
	
	static func numberFromName(fullname: String) -> Int {
        var total: Int = 0
        for u in fullname.unicodeScalars {
            total += Int(UInt32(u))
        }
        return total
	}
    
	static func randomColor(seed: Int?) -> UIColor {
        if seed != nil {
            srand48(seed!)
            let hue = CGFloat(Double(drand48().truncatingRemainder(dividingBy: 256)) / 256.0) // 0.0 to 1.0
            let saturation = CGFloat(Double(drand48().truncatingRemainder(dividingBy: 128)) / 266.0 + 0.5) // 0.5 to 1.0, away from white
            let brightness = CGFloat(Double(drand48().truncatingRemainder(dividingBy: 128)) / 256.0 + 0.5) // 0.5 to 1.0, away from black
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        }
		else {
			let hue = CGFloat(Double(arc4random() % 256) / 256.0) // 0.0 to 1.0
			let saturation = CGFloat(Double(arc4random() % 128) / 266.0 + 0.5) // 0.5 to 1.0, away from white
			let brightness = CGFloat(Double(arc4random() % 128) / 256.0 + 0.5) // 0.5 to 1.0, away from black
			return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
		}
	}
    
    static func prepareImage(image inImage: UIImage) -> UIImage {
		var image = inImage;
        let scalingNeeded: Bool = (image.size.width > Config.imageDimensionMax || image.size.height > Config.imageDimensionMax)
        if (scalingNeeded) {
            let rect: CGRect = AVMakeRect(aspectRatio: image.size
                , insideRect: CGRect(x:0, y:0, width: Config.imageDimensionMax, height: Config.imageDimensionMax))
            image = image.resizeTo(size: rect.size)
        }
        else {
            image = image.normalizedImage()
        }
        return image
    }
	
	static func clearSearchHistory() {
		UserDefaults.standard.set(nil, forKey: PerUserKey(key: Prefs.searchHistory))
	}
    
	static func updateSearchHistory(search: String) {
		if var searches = UserDefaults.standard.array(forKey: PerUserKey(key: Prefs.searchHistory)) as? [String] {
			/* Replace if found else append */
			var index = 0
			var found = false
			for item in searches {
				if (item == search) {
					searches[index] = search
					found = true
					break
				}
				index += 1
			}
			if !found {
				searches.append(search)
			}
			UserDefaults.standard.set(searches, forKey: PerUserKey(key: Prefs.searchHistory))
		}
		else {
			UserDefaults.standard.set([search], forKey: PerUserKey(key: Prefs.searchHistory))
		}
	}
    
    @discardableResult static func delay(_ delay: Double, closure: @escaping () -> ()) -> DispatchWorkItem? {
        let task = DispatchWorkItem(block: closure)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        return task
    }
}
