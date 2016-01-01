//
//  AwsS3.swift
//  Patchr
//
//  Created by Jay Massena on 7/19/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

class Proxibase: NSObject {
    
    class var sharedService: Proxibase {
        struct Singleton {
            static let instance = Proxibase()
        }
        return Singleton.instance
    }
    
    var patch: [String:AnyObject]!
    
    func postMessage(message: [String:AnyObject], patch: [String:AnyObject]) {
        Log.d("Posting message...")
        
        self.patch = patch
        
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.3meters.patchr.ios.message")
        config.sharedContainerIdentifier = "group.com.3meters.patchr.ios"
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        let request = NSMutableURLRequest(URL: NSURL(string: "https://api.aircandi.com/v1/data/messages")!)
        request.HTTPMethod = "POST"
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(message, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTaskWithRequest(request)
            task.resume()
        }
        catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
    }
}

extension Proxibase: NSURLSessionDelegate {
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        Log.d("Session finished")
    }
}

extension Proxibase: NSURLSessionTaskDelegate {
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if task.error != nil {
            Log.w("Session error while posting message: \(task.error!.localizedDescription)")
        }
        else {
            Log.d("Message posted!")
            let patchId: String = ((patch["_id"] != nil) ? patch["_id"] : patch["id_"]) as! String
            var recent: [String:AnyObject] = ["id_": patchId, "name":self.patch["name"]!]
            recent["recentDate"] = NSNumber(longLong: Utils.now()) // Only way to store Int64 as AnyObject
            if self.patch["photo"] != nil {
                recent["photo"] = self.patch["photo"]
            }
            
            Utils.updateRecents(recent)                
        }
    }
}
