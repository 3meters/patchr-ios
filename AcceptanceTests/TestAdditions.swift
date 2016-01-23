//
//  PatchrUITests.swift
//  PatchrUITests
//
//  Created by Jay Massena on 1/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF

extension XCTestCase {
	func tester(file : String = __FILE__, _ line : Int = __LINE__) -> KIFUITestActor {
		return KIFUITestActor(inFile: file, atLine: line, delegate: self)
	}
	
	func system(file : String = __FILE__, _ line : Int = __LINE__) -> KIFSystemTestActor {
		return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
	}
}

extension KIFTestActor {
	func tester(file : String = __FILE__, _ line : Int = __LINE__) -> KIFUITestActor {
		return KIFUITestActor(inFile: file, atLine: line, delegate: self)
	}
	
	func system(file : String = __FILE__, _ line : Int = __LINE__) -> KIFSystemTestActor {
		return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
	}
}

extension KIFUITestActor {
	
	func login() {
		tester().tap(Button.Login)
		tester().enterText("batman@3meters.com", into: Field.Email)
		tester().enterText("Patchme", into: Field.Password)
		tester().tap(Button.Login)
		tester().waitForLabel("Logged in as Batman")
		tester().waitFor(Tab.Profile)
	}
	
	func logout() {
		tester().waitFor(Tab.Profile)
		tester().tap(Tab.Profile)
		tester().tap(Button.Settings)
		tester().tap(Button.Logout)
	}
	
	func tap(identifier: String) {
		tester().tapViewWithAccessibilityIdentifier(identifier)
	}
	
	func tapLabel(label: String) {
		tester().tapViewWithAccessibilityLabel(label)
	}
	
	func enterText(text: String, into: String) {
		tester().clearTextFromAndThenEnterText(text, intoViewWithAccessibilityIdentifier: into)
	}
	
	func waitForAbsence(identifier: String) {
		tester().waitForAbsenceOfViewWithAccessibilityIdentifier(identifier)
	}
	
	func waitForAbsenceLabel(label: String) {
		tester().waitForAbsenceOfViewWithAccessibilityLabel(label)
	}
	
	func waitFor(identifier: String) {
		tester().waitForViewWithAccessibilityIdentifier(identifier)
	}
	
	func waitForLabel(label: String) {
		tester().waitForViewWithAccessibilityLabel(label)
	}
	
	func waitForResults(label: String) {
		tester().waitForViewWithAccessibilityLabel(label)
	}
	
	func exists(identifier: String) -> Bool {
		return tester().tryFindingViewWithAccessibilityIdentifier(identifier)
	}
	
	func existsLabel(label: String) -> Bool {
		do {
			try tester().tryFindingViewWithAccessibilityLabel(label)
			return true
		}
		catch {
			return false
		}
	}
	
	func existsTappable(identifier: String) -> Bool {
		if let element = getElement(identifier) {
			do {
				try UIAccessibilityElement.viewContainingAccessibilityElement(element, tappable: true)
				return true
			}
			catch {
				return false
			}
		}
		return false
	}
	
	private func getElement(identifier: String) -> UIAccessibilityElement? {
		let predicate = NSPredicate(format: "accessibilityIdentifier = %@", identifier)
		let element: UIAccessibilityElement? = UIApplication.sharedApplication().accessibilityElementMatchingBlock({
			element in
			return predicate.evaluateWithObject(element)
		})
		return element
	}
	
	private func getElementWithLabel(label: String) -> UIAccessibilityElement? {
		do {
			let element = try UIAccessibilityElement(label: label, value: nil, traits: UIAccessibilityTraitNone)
			return element
		}
		catch {
			return nil
		}
	}
}

struct Location {
	static let ballard = CLLocationCoordinate2DMake(47.668798, -122.384605)
	static let bellsquare = CLLocationCoordinate2DMake(47.61579554, -122.20136896)
	static let massena = CLLocationCoordinate2DMake(47.5936745, -122.15954795)
}

struct Field {
	static let Email			= "email_field"
	static let Password			= "password_field"
}

struct Label {
	static let BadEmailPassword = "Wrong email and password combination."
	static let EmailVerified	= "Email verified"
}

struct Button {
	static let ForgotPassword	= "forgot_password_button"
	static let Submit			= "submit_button"
	static let Guest			= "guest_button"
	static let Signup			= "signup_button"
	static let Login			= "login_button"
	static let Cancel			= "cancel_button"
	static let Ok				= "OK"
	static let Settings			= "settings_button"
	static let Logout			= "logout_button"
	static let ClearHistory		= "clear_history_button"
	static let Edit				= "edit_button"
}

struct Tab {
	static let Patches			= "patches_tab"
	static let Notifications	= "notifications_tab"
	static let Search			= "search_tab"
	static let Profile			= "profile_tab"
}

struct Segment {
	static let Nearby			= "Nearby"
	static let Watching			= "Watching"
	static let Own				= "Own"
	static let Explore			= "Explore"
}

struct Nav {
	static let Map				= "Map"
	static let Add				= "Add"
	static let Cancel			= "nav_cancel_button"
}

