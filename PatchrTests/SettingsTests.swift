//
//  Created by Jay Massena on 1/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF
import Nimble
import CocoaLumberjack

@testable import Patchr	// Makes all internal api calls available

class SettingsTests: KIFTestCase {
	
	override func beforeAll() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToLobby()
		app.logLevel(DDLogLevel.Debug)
		tester().login()
		tester().waitFor(View.Main)
	}
	
	override func beforeEach() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToMain()
	}
	
	func testCanBrowseTermsOfService() {
		
		tester().tap(Tab.Profile)
		tester().tap(Nav.Settings)
		tester().waitFor(Table.Settings)
		
		tester().tap(Button.TermsOfService)
		tester().waitFor(View.TermsOfService)
		
		tester().tapLabel(Nav.SettingsLabel)
		tester().waitFor(Table.Settings)
		
		tester().tapLabel(Nav.MeLabel)
		tester().waitFor(View.Main)
	}
	
	func testCanBrowsePrivacyPolicy() {
		
		tester().tap(Tab.Profile)
		tester().tap(Nav.Settings)
		tester().waitFor(Table.Settings)
		
		tester().tap(Button.PrivacyPolicy)
		tester().waitFor(View.PrivacyPolicy)
		
		tester().tapLabel(Nav.SettingsLabel)
		tester().waitFor(Table.Settings)
		
		tester().tapLabel(Nav.MeLabel)
		tester().waitFor(View.Main)
	}
	
	func testCanBrowseLicensing() {
		
		tester().tap(Tab.Profile)
		tester().tap(Nav.Settings)
		tester().waitFor(Table.Settings)
		
		tester().tap(Button.Licensing)
		tester().waitFor(View.Licensing)
		
		tester().tapLabel(Nav.SettingsLabel)
		tester().waitFor(Table.Settings)
		
		tester().tapLabel(Nav.MeLabel)
		tester().waitFor(View.Main)
	}
}