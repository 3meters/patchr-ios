//
//  Stopwatch.swift
//  Patchr
//
//  Created by Jay Massena on 10/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation

class Stopwatch: NSObject {
	
	private var lastThreshold: TimeInterval	= 0
	private var log: NSMutableArray = []
	
	var name: String?
	var totalTime: TimeInterval = 0
	
	func totalTimeMills() -> Int {
		return Int(self.totalTime / 1000)
	}
	
	/*
	 * Returns last lap time, process statistic.
	 */
	@discardableResult func segmentTime(message: String)  -> TimeInterval {
		return processSegmentTime(message: message)
	}
	
	func segmentNote(message: String) {
		log.add("\(self.name!): *** Note    ***: \(message)")
	}
	
	@discardableResult func processSegmentTime(message: String?, prefixIncluded: Bool = false) -> TimeInterval {
		if lastThreshold == 0 {
			return 0
		}
		
		let now = DateUtils.nowTimeInterval()
		let lapTime = now - self.lastThreshold
		self.totalTime += lapTime
		self.lastThreshold = now
		let stats = "segment time: \(Int(lapTime * 1000))ms, total time: \(Int(self.totalTime * 1000))ms"
		if message != nil {
			if prefixIncluded {
				let message = "\(self.name!): \(message!): \(stats)"
				log.add(message)
			}
			else {
				let message = "\(self.name!): *** Segment ***: \(message!): \(stats)"
				log.add(message)
			}
		}
		return lapTime
	}
	
	/*
	 * Starts time watching.
	 */
	func start(name: String, message: String) {
		self.name = name
		self.totalTime = 0
		self.lastThreshold = DateUtils.nowTimeInterval()
		log.add("\(name): *** Started ***: \(message)")
	}
	
	/*
	 * Suspends time watching, returns last lap time.
	 */
	@discardableResult func stop(message: String) -> TimeInterval {
		let lapTime = processSegmentTime(message: "*** Stopped ***: \(message)", prefixIncluded: true)
		self.lastThreshold = 0
        Log.v("*** Timer log ***")
        for line in self.log {
            Log.v("\(line)")
        }
		self.log = []
		return lapTime
	}
	
	func isStarted() -> Bool {
		return (self.lastThreshold > 0)
	}
}
