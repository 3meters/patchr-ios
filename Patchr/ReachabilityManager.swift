//
//  ReachabilityManager.swift
//  Patchr
//
//  Created by Jay Massena on 9/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation
import ReachabilitySwift

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
            Log.d("Network is unreachable: \(self.reach.description)", breadcrumb: true)
        }
        
        try! self.reach!.startNotifier()
    }

    func isReachable() -> Bool {
        return self.reach.isReachable
    }

    func isUnreachable() -> Bool {
        return !self.reach.isReachable
    }

    func isReachableViaWWAN() -> Bool {
        return self.reach.isReachableViaWWAN
    }

    func isReachableViaWiFi() -> Bool {
        return self.reach.isReachableViaWiFi
    }
    
    func warmup() {}
}
