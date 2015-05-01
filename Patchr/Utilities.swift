//
//  Utilities.swift
//  Patchr
//
//  Created by Brent on 2015-03-05.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

func LocalizedString(str: String, comment: String) -> String {
	return NSLocalizedString(str, comment: comment)
}

func LocalizedString(str: String) -> String {
	return LocalizedString("[]" + str, str)
}

// Utility to show some information about subview frames.

func showSubviews(view: UIView, level: Int = 0) {
	var indent = ""
	for i in 0 ..< level {
		indent += "  "
	}
	var count = 0
	for subview in view.subviews {
		println("\(indent)\(count++). \(subview.frame)")
		showSubviews(subview as! UIView, level: level + 1)
	}
}

func PatchrUserDefaultKey(subKey: String) -> String {
	return "com.3meters.patchr.ios." + subKey
}

let globalGregorianCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)

public func DateTimeTag() -> String! {
	let date = NSDate()

	if let dc = globalGregorianCalendar?.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay |
															.CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: date) {
		return String(format: "%04d%02d%02d_%02d%02d%02d", dc.year, dc.month, dc.day, dc.hour, dc.minute, dc.second)
	}
	return nil
}

var temporaryFileCount = 0

func TemporaryFileURLForImage(image: UIImage) -> NSURL? {
	let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/0.75)
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


// Opportunity here to make this generic.

class TextViewChangeObserver {
	var observerObject: NSObjectProtocol

	init(_ textView: UITextView, action: () -> ()) {
		observerObject = NSNotificationCenter.defaultCenter().addObserverForName(UITextViewTextDidChangeNotification, object: textView, queue: nil)
		{
			note in
			action()
		}
	}

	func stopObserving() {
		NSNotificationCenter.defaultCenter().removeObserver(observerObject)
	}

	deinit {
		print("-- deinit Change observer")
	}
}

class TextFieldChangeObserver {
	var observerObject: NSObjectProtocol

	init(_ textField: UITextField, action: () -> ()) {
		observerObject = NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: nil)
		{
			note in
			action()
		}
	}

	func stopObserving() {
		NSNotificationCenter.defaultCenter().removeObserver(observerObject)
	}
}

func ==(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
	return a.latitude == b.latitude && a.longitude == b.longitude
}

func !=(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
	return !(a == b)
}

extension UIViewController {
	func ActionConfirmationAlert(title: String, message: String, actionTitle: String, cancelTitle: String, onDismiss: (Bool) -> Void) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

		alert.addAction(UIAlertAction(title: actionTitle, style: .Destructive, handler: { _ in onDismiss(true) }))
		alert.addAction(UIAlertAction(title: cancelTitle, style: .Cancel, handler: { _ in onDismiss(false) }))
		self.presentViewController(alert, animated: true) {
		}
	}

	func ErrorNotificationAlert(title: String, message: String, onDismiss: (() -> Void)? = nil) {
		let alert
		= UIAlertController(title: LocalizedString("Error"), message: message, preferredStyle: .Alert)
		alert.addAction(
		UIAlertAction(title: LocalizedString("OK"), style: .Cancel) {
			_ in
			if onDismiss != nil {
				onDismiss!()
			}
		})
		self.presentViewController(alert, animated: true) {
		}
	}
}

