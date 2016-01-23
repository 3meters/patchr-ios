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
import CoreLocation

@testable import Patchr	// Makes all internal api calls available

class AnonymousTests: KIFTestCase {
	
	override func beforeAll() {
		
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			appDelegate.resetToLobby()
		}
		
		tester().tap(Button.Guest)
		tester().waitFor(Tab.Profile)
	}
	
	override func beforeEach() {
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			appDelegate.resetToHome()
		}
	}
	
	func testAddingPatchIsGuarded() {
		
		/* Show and confirm guard */
		tester().tapLabel(Nav.Add)
		tester().waitFor(Button.Login)
		
		expect(self.tester().exists(Button.Signup)) == true
		expect(self.tester().exists(Button.Cancel)) == true
		
		tester().tap(Button.Cancel)
		tester().waitFor(Tab.Patches)
	}
	
	func testGuardSupportsLoginAndSignup() {
		
		/* Show and confirm guard */
		tester().tapLabel(Nav.Add)
		tester().waitFor(Button.Login)
		
		/* Nav to login */
		tester().tap(Button.Login)
		tester().tap(Nav.Cancel)
		
		/* Nav to signup */
		tester().tapLabel(Nav.Add)
		tester().tap(Button.Signup)
		tester().tap(Nav.Cancel)
		
		/* Cancel */
		tester().waitFor(Tab.Patches)
	}
	
	func testAnonymousCanBrowse() {
		
		var notification = system().waitForNotificationName(Events.DidFetchQuery, object: nil) {
			LocationController.instance.setMockLocation(Location.massena)
			self.tester().acknowledgeSystemAlert()
		}
		
		if let userInfo = notification.userInfo, let count = userInfo["count"] as? Int {
			expect(count).to(equal(50))
		}
		
		/* Should be there */
		expect(self.tester().existsLabel(Segment.Nearby)) == true
		expect(self.tester().existsLabel(Segment.Explore)) == true
		expect(self.tester().existsLabel(Nav.Add)) == true
		expect(self.tester().existsLabel(Nav.Map)) == true
		
		/* Should not be there */
		expect(self.tester().existsLabel(Segment.Own)) == false
		expect(self.tester().existsLabel(Segment.Watching)) == false
		
		tester().swipeViewWithAccessibilityIdentifier("table", inDirection: KIFSwipeDirection.Down)
		
		notification = system().waitForNotificationName(Events.DidFetchQuery, object: nil) {
			LocationController.instance.setMockLocation(Location.ballard)
			self.tester().acknowledgeSystemAlert()
		}
		
		if let userInfo = notification.userInfo, let count = userInfo["count"] as? Int {
			expect(count).to(equal(50))
		}
	}
}