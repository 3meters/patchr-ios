//
//  Library.swift
//  Patchr
//
//  Created by Jay Massena on 1/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import Foundation
//import UIKit

class TestLib {
	
	static func login(testCase: BaseTestCase) {
		
		let lobbyLoginButton = testCase.app.buttons["lobby_login_button"]
		let emailField = testCase.app.textFields["email_field"]
		let passwordField = testCase.app.secureTextFields["password_field"]
		let loginButton = testCase.app.buttons["login_login_button"]
		let loggedInToast = testCase.app.otherElements.elementMatchingPredicate(NSPredicate(format: "label BEGINSWITH 'Logged in as'"))
		let profileTab = testCase.app.tabBars.buttons["profile_tab"]
		
		lobbyLoginButton.tap()
		
		testCase.waitForElementToExist(loginButton)
		
		/* Set email */
		emailField.tapAndTypeText("batman@3meters.com")
		passwordField.tapAndTypeText("Patchme")
		loginButton.tap()
		
		testCase.waitForElementToExist(loggedInToast)
		
		/* Wait for evidence of main screen using tab bar */
		testCase.waitForElementToExist(profileTab)
	}
	
	static func logout(testCase: BaseTestCase) {
		
		let profileTab = testCase.app.tabBars.buttons["profile_tab"]
		let settingsButton = testCase.app.navigationBars["Me"].buttons["user_settings_button"]
		let logoutButton = testCase.app.tables.buttons["settings_logout_button"]
		let lobbyLoginButton = testCase.app.buttons["lobby_login_button"]
		
		testCase.waitForElementToExist(profileTab)
		
		profileTab.forceTapElement()
		settingsButton.forceTapElement()
		logoutButton.tap()
		
		testCase.waitForElementToExist(lobbyLoginButton)
	}
}

/*Sends a tap event to a hittable/unhittable element.*/
extension XCUIElement {
	func forceTapElement() {
		if self.hittable {
			self.tap()
		}
		else {
			let coordinate: XCUICoordinate = self.coordinateWithNormalizedOffset(CGVectorMake(0.0, 0.0))
			coordinate.tap()
		}
	}
	
	func tapAndTypeText(text: String?) {
		self.tap()
		let clearTextButton = self.buttons["Clear text"]
		if clearTextButton.exists {
			clearTextButton.tap()
		}
		if text != nil {
			self.typeText(text!)
		}
	}
}

extension XCTestCase {
	
	func waitForElementToExist(element: XCUIElement) {
		if element.exists {
			return
		}
		let exists = NSPredicate(format: "exists == true")
		expectationForPredicate(exists, evaluatedWithObject: element, handler: nil)
		waitForExpectationsWithTimeout(5, handler: nil)
	}
	
	func waitForElementToNotExist(element: XCUIElement) {
		if !element.exists {
			return
		}
		let notExists = NSPredicate(format: "exists != true")
		expectationForPredicate(notExists, evaluatedWithObject: element, handler: nil)
		waitForExpectationsWithTimeout(5, handler: nil)
	}
	
	func waitUntilElementIsHittable(element: XCUIElement) {
		if element.hittable {
			return
		}
		let hittable = NSPredicate(format: "hittable == true")
		expectationForPredicate(hittable, evaluatedWithObject: element, handler: nil)
		waitForExpectationsWithTimeout(5, handler: nil)
	}
	
	func tapWhenHittable(element: XCUIElement) {
		if element.hittable {
			element.tap()
			return
		}
		let hittable = NSPredicate(format: "hittable == true")
		expectationForPredicate(hittable, evaluatedWithObject: element, handler: nil)
		waitForExpectationsWithTimeout(5) {
			error in
			if error == nil {
				element.tap()
			}
		}
	}
	
	private struct WaitData {
		static var waitExpectation: XCTestExpectation?
	}
	
	public func waitForDuration(duration: NSTimeInterval) {
		WaitData.waitExpectation = expectationWithDescription("wait")
		NSTimer.scheduledTimerWithTimeInterval(duration, target: self,
			selector: Selector("waitForDurationDone"), userInfo: nil, repeats: false)
		waitForExpectationsWithTimeout(duration + 3, handler: nil)
	}
	
	func waitForDurationDone() {
		WaitData.waitExpectation?.fulfill()
	}
}