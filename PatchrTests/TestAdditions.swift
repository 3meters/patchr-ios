//
//  PatchrUITests.swift
//  PatchrUITests
//
//  Created by Jay Massena on 1/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF
import Nimble

struct Location {
	static let ballard		= CLLocationCoordinate2DMake(47.668798, -122.384605)
	static let bellsquare	= CLLocationCoordinate2DMake(47.61579554, -122.20136896)
	static let massena		= CLLocationCoordinate2DMake(47.5936745, -122.15954795)
}

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

/* 
 * A Nimble matcher that succeeds when the actual value exists (is not nil). 
 */
public func exist<T>() -> MatcherFunc<T> {
	return MatcherFunc { actualExpression, failureMessage in
		failureMessage.postfixMessage = "exist"
		let actualValue = try actualExpression.evaluate()
		return actualValue != nil
	}
}

extension NMBObjCMatcher {
	public class func existMatcher() -> NMBObjCMatcher {
		return NMBObjCMatcher { actualExpression, failureMessage in
			return try! exist().matches(actualExpression, failureMessage: failureMessage)
		}
	}
}

extension KIFUITestActor {
	
	func login() {
		tester().tap(Button.Login)
		tester().waitFor(View.Login)
		tester().enterText("batman@3meters.com", into: Field.Email)
		tester().enterText("Patchme", into: Field.Password)
		tester().tap(Button.Submit)
		tester().waitForLabel(Toast.LoggedIn + " Batman")
		tester().waitFor(View.Main)
	}
	
	func logout() {
		tester().waitFor(View.Main)
		tester().tap(Tab.Profile)
		tester().tap(Nav.Settings)
		tester().tap(Button.Logout)
	}
	
	func tap(identifier: String) {
		tester().tapViewWithAccessibilityIdentifier(identifier)
	}
	
	func tapLabel(label: String) {
		tester().tapViewWithAccessibilityLabel(label)
	}
	
	func enterText(text: String?, into: String) {
		if text == nil {
			tester().clearTextFromViewWithAccessibilityIdentifier(into)
		}
		else {
			tester().clearTextFromAndThenEnterText(text!, intoViewWithAccessibilityIdentifier: into)
		}
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
	
	func waitForContains(label: String) {
		let predicate = NSPredicate(format: "accessibilityLabel CONTAINS[cd] %@", label)
		tester().waitForAccessibilityElement(nil, view: nil, withElementMatchingPredicate: predicate, tappable: false)
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
		if let element = element(identifier) {
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
	
	func element(identifier: String) -> UIAccessibilityElement? {
		let predicate = NSPredicate(format: "accessibilityIdentifier = %@", identifier)
		let element: UIAccessibilityElement? = UIApplication.sharedApplication().accessibilityElementMatchingBlock({
			element in
			return predicate.evaluateWithObject(element)
		})
		return element
	}
	
	func elementWithLabel(label: String) -> UIAccessibilityElement? {
		do {
			let element = try UIAccessibilityElement(label: label, value: nil, traits: UIAccessibilityTraitNone)
			return element
		}
		catch {
			return nil
		}
	}
}
