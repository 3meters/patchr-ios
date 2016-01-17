//
//  PatchrUITests.swift
//  PatchrUITests
//
//  Created by Jay Massena on 1/12/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import XCTest

class BaseTestCase: XCTestCase {
	
	let app = XCUIApplication()
	var launched = false
        
    override func setUp() {
        super.setUp()
		
        self.continueAfterFailure = false
		
		if !self.launched {
			setupSnapshot(app)
			self.app.launchArguments = ["MOCKFLAG"]
			self.app.launchEnvironment = ["MOCK_LAT": "47.61579554", "MOCK_LON": "-122.20136896"]
			self.app.launch()
			self.launched = true
		}
    }
    
    override func tearDown() {
        super.tearDown()
    }
}
