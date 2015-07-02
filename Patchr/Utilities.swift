//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ObjectiveC

let globalGregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)

var temporaryFileCount = 0

func LocalizedString(str: String, comment: String) -> String {
	return NSLocalizedString(str, comment: comment)
}

func LocalizedString(str: String) -> String {
	return LocalizedString("[]" + str, str)
}

func PatchrUserDefaultKey(subKey: String) -> String {
	return "com.3meters.patchr.ios." + subKey
}

func DateTimeTag() -> String! {
	let date = NSDate()

	if let dc = globalGregorianCalendar?.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay |
															.CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: date) {
		return String(format: "%04d%02d%02d_%02d%02d%02d", dc.year, dc.month, dc.day, dc.hour, dc.minute, dc.second)
	}
	return nil
}

func TemporaryFileURLForImage(image: UIImage) -> NSURL? {
    
	let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.70)
	if let imageData = imageData {
		// Note: This method of getting a temporary file path is not the recommended method. See the docs for NSTemporaryDirectory.
		let temporaryFilePath
		= NSTemporaryDirectory() + "patchr_temp_file_\(temporaryFileCount).jpg"
		println(temporaryFilePath)

		if imageData.writeToFile(temporaryFilePath, atomically: false) {
			return NSURL(fileURLWithPath: temporaryFilePath)
		}
	}
	return nil
}

func ==(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
	return a.latitude == b.latitude && a.longitude == b.longitude
}

func !=(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
	return !(a == b)
}

extension String {
    var length: Int {
        return count(self)
    }
}