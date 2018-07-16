//
//  ReachabilityManager.swift
//  Patchr
//
//  Created by Jay Massena on 9/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class ReachabilityManager: NSObject {

    static let instance = ReachabilityManager()
    private var reach: Reachability!
    var reachable: Bool = false

    override init(){
        super.init()

        self.reach = Reachability(hostname: "clients3.google.com")  // Google uses this to test for captive portals

        /*
        * Called on a background thread.
        */
        self.reach!.whenReachable = { reachability in
            self.reachable = true
            DispatchQueue.main.async() {
                Log.d("Network is reachable: \(self.reach.description)", breadcrumb: true)
            }
        }

        self.reach!.whenUnreachable = { reachability in
            self.reachable = false
            DispatchQueue.main.async() {
                Log.d("Network is unreachable: \(self.reach.description)", breadcrumb: true)
            }
        }        
    }

    func isReachable() -> Bool {
        return (self.reach.connection != .none)
    }

    func isUnreachable() -> Bool {
        return !(self.reach.connection != .none)
    }

    func isReachableViaCellular() -> Bool {
        return (self.reach.connection == .cellular)
    }

    func isReachableViaWiFi() -> Bool {
        return self.reach.connection == .wifi
    }
    
    func startMonitoring() {
        try! self.reach!.startNotifier()
    }
    
    func stopMonitoring() {
        self.reach.stopNotifier()
    }
    
    func prepare() {}
}
