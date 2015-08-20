//
//  PatchrTests.swift
//  PatchrTests
//
//  Created by Rob MacEachern on 2015-01-20.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import XCTest
import CoreLocation

// NOTE: At this moment, the tests are set up so that they only work when set up to run on the production server.
    
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
        let client = Proxibase()
        let user = UserController.instance
        client.signIn("rob@robmaceachern.com", password: "test9090") { (response, error) -> Void in
            if (error == nil && user.authenticated) {
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
        let client = Proxibase()
        let user = UserController.instance
        client.signOut { (response, error) -> Void in
            if error == nil && !user.authenticated {
                expectation.fulfill()
            } else {
                println(error)
            }
        }
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
    
    func testFetchNearbyPatches() {
        var expectation = self.expectationWithDescription("Fetch nearby patches")
        let client = Proxibase()
        let user = UserController.instance
        client.signIn("rob@robmaceachern.com", password: "test9090") { (response, error) -> Void in
            let location = CLLocationCoordinate2D(latitude: 49.2845280, longitude: -123.1092720)
            client.fetchNearbyPatches(location, radius: 10000, completion: { (response, error) -> Void in
                if error == nil && response != nil {
                    //NSLog("\(response)")
                    expectation.fulfill()
                } else {
                    println(error)
                }
            })
        }
        
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
    
    func testFetchNotifications() {
        var expectation = self.expectationWithDescription("Fetch notifications")
        let client = Proxibase()
        let user = UserController.instance
        client.signIn("rob@robmaceachern.com", password: "test9090") { (response, error) -> Void in
            client.fetchNotifications(completion: { (response, error) -> Void in
                if error == nil && response != nil {
                    expectation.fulfill()
                } else {
                    println(error)
                }
            })
        }
        
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
    
    func testFetchMessagesForPatch() {
        var expectation = self.expectationWithDescription("Fetch messages for patch")
        let client = Proxibase()
        let user = UserController.instance
        client.signIn("rob@robmaceachern.com", password: "test9090") { (response, error) -> Void in
            client.fetchMessagesForPatch("pa.150120.02229.596.036120", completion: { (response, error) -> Void in
                if error == nil && response != nil {
                    //NSLog("\(response)")
                    expectation.fulfill()
                } else {
                    println(error)
                }
            })
        }
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
    
    func testFetchMostMessagedPatches() {
        var expectation = self.expectationWithDescription("Fetch patches with the most messages")
        let client = Proxibase()
        let user = UserController.instance
        client.signIn("rob@robmaceachern.com", password: "test9090") { (response, error) -> Void in
            let location = CLLocationCoordinate2D(latitude: 49.2845280, longitude: -123.1092720)
            client.fetchInterestingPatches(location, completion: { (response, error) -> Void in
                if error == nil && response != nil {
                    //NSLog("\(response)")
                    expectation.fulfill()
                } else {
                    println(error)
                }
            })
        }
        
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
    
    func testFetchMessagesOwnedByCurrentUser() {
        var expectation = self.expectationWithDescription("Fetch messages for current user")
        let client = Proxibase()
        let user = UserController.instance
        client.signIn("rob@robmaceachern.com", password: "test9090") { (response, error) -> Void in
            client.fetchMessagesOwnedByUser(user.userId!, completion: { (response, error) -> Void in
                if error == nil && response != nil {
                    //NSLog("\(response)")
                    expectation.fulfill()
                } else {
                    println(error)
                }
            })
        }
        
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
}
