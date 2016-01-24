//
//  AcceptanceTests.swift
//  AcceptanceTests
//
//  Created by Jay Massena on 1/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF
import Nimble
import CocoaLumberjack

@testable import Patchr	// Makes all internal api calls available

class OnboardingTests: KIFTestCase {
	
	override func beforeAll() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.logLevel(DDLogLevel.Debug)
	}
	
	override func beforeEach() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToLobby()
	}
		
    func testLoginAndLogout() {
		tester().login()
		tester().logout()
	}
	
	func testInvalidLogin() {
		tester().tap(Button.Login)
		tester().waitFor(View.Login)
		
		tester().tap(Button.Submit)
		tester().waitForContains("Enter an email address")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("bat@3meters", into: Field.Email)
		tester().tap(Button.Submit)
		tester().waitForContains("Enter a valid email")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("bat@3meters.com", into: Field.Email)
		tester().enterText("Bat", into: Field.Password)
		tester().tap(Button.Submit)
		tester().waitForContains("Enter a password with")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("Batmanme", into: Field.Password)
		tester().tap(Button.Submit)
		tester().waitForContains("Email address not found")
		
		tester().enterText("batman@3meters.com", into: Field.Email)
		tester().enterText("Batmanme", into: Field.Password)
		tester().tap(Button.Submit)
		tester().waitForContains("Wrong email and password combination")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("Patchme", into: Field.Password)
		tester().tap(Button.Submit)
		tester().waitForLabel(Toast.LoggedIn + " Batman")
		tester().waitFor(View.Main)
	}
	
	func testPasswordReset() {
		tester().tap(Button.Login)
		tester().waitFor(View.Login)
		
		tester().tap(Button.ForgotPassword)
		tester().waitFor(View.PasswordReset)
		
		tester().tap(Button.Submit)
		tester().waitForContains("Enter an email address")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("bat@3meters", into: Field.ResetEmail)
		tester().tap(Button.Submit)
		tester().waitForContains("Enter a valid email")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("bat@3meters.com", into: Field.ResetEmail)
		tester().tap(Button.Submit)
		tester().waitForContains("Enter a new password")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("Patchme", into: Field.ResetPassword)
		tester().tap(Button.Submit)
		tester().waitForContains("email address could not be found")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("moo@3meters.com", into: Field.ResetEmail)
		tester().tap(Button.Submit)
		tester().waitForContains("email address has not been used")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("batman@3meters.com", into: Field.ResetEmail)
		tester().tap(Button.Submit)
		tester().waitForLabel(Toast.PasswordReset)
		tester().waitFor(View.Login)
	}
	
	func testSignupAndDelete() {
		
		/*--------------------------------------
		* SIGNUP
		--------------------------------------*/
		
		tester().tap(Button.Signup)
		tester().waitFor(View.SignupLogin)
		tester().enterText("superman@3meters.com", into: Field.Email)
		tester().enterText("Patchme", into: Field.Password)
		tester().tap(Nav.Submit)
		
		tester().waitFor(View.SignupProfile)
		tester().enterText("Superman", into: Field.Name)
		
		tester().tap(Button.PhotoSet)
		tester().tapLabel(Sheet.PhotoSearch)
		tester().waitFor(View.PhotoSearch)
		
		let notification = system().waitForNotificationName(Events.DidFetchQuery, object: nil) {
			self.tester().enterText("Superman", into: Field.Search)
			self.tester().tap(Button.Search)
		}
		
		if let userInfo = notification.userInfo, let count = userInfo["count"] as? Int {
			expect(count) > 0
		}
		
		tester().tapItemAtIndexPath(NSIndexPath.init(forItem: 0, inSection: 0), inCollectionViewWithAccessibilityIdentifier: Collection.Photos)
		tester().tapLabel(Button.UsePhoto)
		tester().waitFor(View.SignupProfile)
		
		tester().tap(Button.Join)
		tester().waitForLabel("Logged in as Superman")
		tester().waitFor(View.Main)
		
		/*--------------------------------------
		* DELETE USER
		--------------------------------------*/
		
		tester().tap(Tab.Profile)
		tester().tap(Nav.Edit)
		tester().waitFor(View.ProfileEdit)
		
		tester().tap(Nav.Delete)
		tester().waitForLabel(Alert.ConfirmDelete)
		
		tester().enterText("YES", into: Field.ConfirmDelete)
		tester().tapLabel(AlertButton.Delete)
		tester().waitFor(View.Lobby)
	}
}