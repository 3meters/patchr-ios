//
//  Created by Jay Massena on 1/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF
import CocoaLumberjack
import Nimble

@testable import Patchr	// Makes all internal api calls available

class UserEditingTests: KIFTestCase {
	
	override func beforeAll() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToLobby()
		app.logLevel(DDLogLevel.Debug)
		tester().login()
	}
	
	override func afterAll() {
		tester().logout()
	}
	
	override func beforeEach() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToMain()
	}
	
	override func afterEach() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToMain()
	}
	
	func testPasswordChange() {
		tester().tap(Tab.Profile)
		tester().tap(Nav.Edit)
		tester().waitFor(View.ProfileEdit)
		
		tester().tap(Button.ChangePassword)
		tester().waitFor(View.PasswordEdit)
		
		tester().tap(Nav.Submit)	// Back to profile edit
		tester().waitForContains("Enter your current password")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("Batmanme", into: Field.Password)
		tester().tap(Nav.Submit)
		tester().waitForContains("Enter a new password")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("password", into: Field.NewPassword)
		tester().tap(Nav.Submit)
		tester().waitForContains("The old password is not correct")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("Patchme", into: Field.Password)
		tester().tap(Nav.Submit)
		tester().waitForContains("The password is not strong")
		tester().tapLabel(AlertButton.Ok)
		
		tester().enterText("Patchme", into: Field.NewPassword)
		tester().tap(Nav.Submit)
		tester().waitFor(View.ProfileEdit)
		tester().tap(Nav.Cancel)
	}
	
    func testProfileEdit() {
		tester().tap(Tab.Profile)
		tester().tap(Nav.Edit)
		tester().waitFor(View.ProfileEdit)
		
		tester().enterText("Mr. Batman", into: Field.Name)
		tester().enterText("Wayne Manor", into: Field.Area)
		tester().tap(Nav.Submit)	// Save
		tester().waitFor(View.Main)
		
		tester().tap(Nav.Edit)
		tester().waitFor(View.ProfileEdit)
		
		tester().enterText("Batman", into: Field.Name)
		tester().enterText(nil, into: Field.Area)
		tester().tap(Nav.Submit)	// Save
		tester().waitFor(View.Main)
	}
}