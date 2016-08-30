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

        self.reach = Reachability(hostName: "clients3.google.com")  // Google uses this to test for captive portals

        /*
        * Called on a background thread.
        */
        self.reach!.reachableBlock = { (let reach: Reachability!) -> Void in
            self.reachable = true
            dispatch_async(dispatch_get_main_queue()) {
                Log.d("Network is reachable: \(reach)", breadcrumb: true)
            }
        }

        self.reach!.unreachableBlock = { (let reach: Reachability!) -> Void in
            self.reachable = false
            Log.d("Network is unreachable: \(reach)", breadcrumb: true)
        }

        self.reach.startNotifier()
        Log.d("Network flags: \(reach)")
    }

    func isReachable() -> Bool {
        return self.reach.isReachable()
    }

    func isUnreachable() -> Bool {
        return !self.reach.isReachable()
    }

    func isReachableViaWWAN() -> Bool {
        return self.reach.isReachableViaWWAN()
    }

    func isReachableViaWiFi() -> Bool {
        return self.reach.isReachableViaWiFi()
    }
}
