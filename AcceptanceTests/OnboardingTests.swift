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

@testable import Patchr	// Makes all internal api calls available

class OnboardingTests: KIFTestCase {
	
	override func beforeEach() {
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			appDelegate.resetToLobby()
		}
	}
		
    func testLoginAndLogout() {
		tester().login()
		tester().logout()
	}
	
	func testLoginBadPassword() {
		
	}
	
	func testPasswordReset() {
		
	}
	
	func testSignupAndDelete() {
		
	}
}