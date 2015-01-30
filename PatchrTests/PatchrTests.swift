//
//  PatchrTests.swift
//  PatchrTests
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import XCTest

class PatchrTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUserAuthentication() {
        var expectation = self.expectationWithDescription("Login response")
        let client = ProxibaseClient()
        client.signIn("rob@robmaceachern.com", password: "test9090", installId: "12345") { (response, error) -> Void in
            if (error == nil && client.authenticated) {
                expectation.fulfill()
            } else {
                println(error)
            }
        }
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
    
    func testUserSignout() {
        var expectation = self.expectationWithDescription("Signout success")
        let client = ProxibaseClient()
        client.signOut { (response, error) -> Void in
            if error == nil && !client.authenticated {
                expectation.fulfill()
            } else {
                println(error)
            }
        }
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
}
