//
//  AcceptanceTests.swift
//  AcceptanceTests
//
//  Created by Jay Massena on 1/20/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest
import KIF
@testable import Patchr	// Makes all internal api calls available

class UserEditingTests: KIFTestCase {
	
	override func beforeAll() {
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			appDelegate.resetToLobby()
			tester().login()
		}
	}
	
	override func afterAll() {
		tester().logout()
	}
	
	override func beforeEach() {
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			appDelegate.resetToHome()
		}
	}
	
	func testPasswordChange() {
	
	}
	
    func testProfileEdit() {

	}
	
	func testFacebookConnect() {
		
	}
}