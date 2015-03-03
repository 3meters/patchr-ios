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
        client.signIn("rob@robmaceachern.com", password: "test9090", installId: "12345") { (_, _, response, error) -> Void in
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
    
    func testFetchNearby() {
        var expectation = self.expectationWithDescription("Fetch nearby patches")
        let client = ProxibaseClient()
        client.signIn("rob@robmaceachern.com", password: "test9090", installId: "123") { (userId, sessionKey, response, error) -> Void in
            let location = CLLocationCoordinate2D(latitude: 49.2845280, longitude: -123.1092720)
            var links = [
                Link(to: .Beacons, type: .Proximity, limit: 10, count: nil),
                Link(to: .Places, type: .Proximity, limit: 10, count: nil),
                Link(from: .Messages, type: .Content, limit: 2, count: nil),
                Link(from: .Messages, type: .Content, limit: nil, count: true),
                Link(from: .Users, type: .Like, limit: nil, count: true),
                Link(from: .Users, type: .Watch, limit: nil, count: true)
            ]
            
            client.fetchNearby(location, radius: 1000, limit: 50, offset: 0, links: links) { (response, error) -> Void in
                if error == nil && response != nil {
                    expectation.fulfill()
                } else {
                    println(error)
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            println(error)
        })
    }
}
