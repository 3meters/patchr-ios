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
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.3meters.patchr.ios.message")
        config.sharedContainerIdentifier = "group.com.3meters.patchr.ios"
        let session = Foundation.URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.aircandi.com/v1/data/messages")! as URL)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: message, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTask(with: request as URLRequest)
            task.resume()
        }
        catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
    }
}

extension Proxibase: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Log.d("Session finished")
    }
}

extension Proxibase: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if task.error != nil {
            Log.w("Session error while posting message: \(task.error!.localizedDescription)")
        }
        else {
            Log.d("Message posted!")
            let patchId: String = ((patch["_id"] != nil) ? patch["_id"] : patch["id_"]) as! String
            var recent: [String:AnyObject] = ["id_": patchId as AnyObject, "name":self.patch["name"]!]
            recent["recentDate"] = NSNumber(value: Utils.now()) // Only way to store Int64 as AnyObject
            if self.patch["photo"] != nil {
                recent["photo"] = self.patch["photo"]
            }
            
            Utils.updateRecents(recent: recent)
        }
    }
}
