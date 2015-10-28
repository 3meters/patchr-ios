//
//  Stopwatch.swift
//  Patchr
//
//  Created by Jay Massena on 10/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Foundation

class Stopwatch: NSObject {
	
	private var lastThreshold: NSTimeInterval	= 0
	private var log: NSMutableArray				= []
	
	var name: String?
	var totalTime: NSTimeInterval				= 0
	
	func totalTimeMills() -> Int {
		return Int(self.totalTime / 1000)
	}
	
	/*
	 * Returns last lap time, process statistic.
	 */
	func segmentTime(message: String)  -> NSTimeInterval {
		return processSegmentTime(message)
	}
	
	func processSegmentTime(message: String?) -> NSTimeInterval {
		if lastThreshold == 0 {
			return 0
		}
		
		let now = NSDate().timeIntervalSince1970
		let lapTime = now - self.lastThreshold
		self.totalTime += lapTime
		self.lastThreshold = now
		let stats = "segment time: \(Int(lapTime * 1000))ms, total time: \(Int(self.totalTime * 1000))ms"
		if message != nil {
			log.addObject("\(self.name!): \(message!): \(stats)")
		}
		return lapTime
	}
	
	/*
	 * Starts time watching.
	 */
	func start(name: String, message: String) {
		self.name = name
		self.totalTime = 0
		self.lastThreshold = NSDate().timeIntervalSince1970
		log.addObject("\(name): *** Started ***: \(message)")
	}
	
	/*
	 * Suspends time watching, returns last lap time.
	 */
	func stop(message: String) -> NSTimeInterval {
		let lapTime = processSegmentTime("*** Stopped ***: \(message)")
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
