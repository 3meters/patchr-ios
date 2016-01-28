//
//  Created by Jay Massena on 1/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF
import Nimble
import CoreLocation
import CocoaLumberjack

@testable import Patchr	// Makes all internal api calls available

class AnonymousTests: KIFTestCase {
	
	override func beforeAll() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToLobby()
		app.logLevel(DDLogLevel.Debug)
		
		tester().tap(Button.Guest)
		tester().waitFor(View.Main)
	}
	
	override func beforeEach() {
		let app = UIApplication.sharedApplication().delegate as! AppDelegate
		app.resetToMain()
	}
	
	func testAddingPatchIsGuarded() {
		
		/* Show and confirm guard */
		tester().tapLabel(Nav.AddLabel)
		tester().waitFor(View.Guest)
		
		expect(self.tester().exists(Button.Signup)) == true
		expect(self.tester().exists(Button.Cancel)) == true
		
		tester().tap(Button.Cancel)
		tester().waitFor(View.Main)
	}
	
	func testGuardSupportsLoginAndSignup() {
		
		/* Show and confirm guard */
		tester().tapLabel(Nav.AddLabel)
		tester().waitFor(View.Guest)
		
		/* Nav to login */
		tester().tap(Button.Login)
		tester().tap(Nav.Cancel)
		
		/* Nav to signup */
		tester().tapLabel(Nav.AddLabel)
		tester().waitFor(View.Guest)
		tester().tap(Button.Signup)
		tester().tap(Nav.Cancel)
		
		/* Cancel */
		tester().waitFor(View.Main)
	}
	
	func testAnonymousCanBrowse() {
		
		var notification = system().waitForNotificationName(Events.DidFetchQuery, object: nil) {
			LocationController.instance.setMockLocation(Location.massena)
			self.tester().acknowledgeSystemAlert()
		}
		
		if let userInfo = notification.userInfo, let count = userInfo["count"] as? Int {
			expect(count) > 0
		}
		
		self.tester().waitForTimeInterval(1.0)
		
		/* Should be there */
		expect(self.tester().existsLabel(Segment.Nearby)) == true
		expect(self.tester().existsLabel(Segment.Explore)) == true
		expect(self.tester().existsLabel(Nav.AddLabel)) == true
		expect(self.tester().existsLabel(Nav.MapLabel)) == true
		
		/* Should not be there */
		expect(self.tester().existsLabel(Segment.Own)) == false
		expect(self.tester().existsLabel(Segment.Watching)) == false

		/* User move to new location */
		notification = system().waitForNotificationName(Events.DidFetchQuery, object: nil) {
			LocationController.instance.setMockLocation(Location.ballard)
		}
		
		if let userInfo = notification.userInfo, let count = userInfo["count"] as? Int {
			expect(count) > 0
		}
		
		self.tester().waitForTimeInterval(1.0)		
	}
}