//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChannelQuery: NSObject {

	var authHandle: AuthStateDidChangeListenerHandle!

	var block: ((Error?, FireChannel?) -> Swift.Void)!
	var fired = false

	var channelPath: String!
	var channelHandle: UInt!
	var channel: FireChannel!

	var linkPath: String!
	var linkHandle: UInt!
	var linkMap: [String: Any]!
	var linkMapMiss = false

	init(channelId: String, userId: String?) {
		super.init()
		self.channelPath = "channels/\(channelId)"
		if userId != nil {
			self.linkPath = "channel-members/\(channelId)/\(userId!)"
		}
	}

	func observe(with block: @escaping (Error?, FireChannel?) -> Swift.Void) {

		self.block = block

		self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
			guard let this = self else { return }
			if auth.currentUser == nil {
				this.remove()
			}
		}

		self.channelHandle = FireController.db.child(self.channelPath).observe(.value, with: { [weak self] snap in
			guard let this = self else { return }
			if let value = snap.value as? [String: Any] {
				this.channel = FireChannel(dict: value, id: snap.key)
				if this.linkPath == nil || this.linkMapMiss {
					this.block(nil, this.channel)  // May or may not have link info
				}
				else if this.linkMap != nil {
					this.channel!.membershipFrom(dict: (this.linkMap)!)
					this.block(nil, this.channel)  // May or may not have link info
				}
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read channel: \(this.channelPath!)")
			this.block(error, nil)
		})

		if self.linkPath != nil {
			self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
				guard let this = self else { return }
				if let value = snap.value as? [String: Any] {
					this.linkMap = value
					if this.channel != nil {
						this.channel!.membershipFrom(dict: value)
						this.block(nil, this.channel)
					}
				}
				else {
					this.linkMapMiss = true
					if this.channel != nil {
						this.channel!.membershipClear()
						this.block(nil, this.channel)
					}
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read channel membership: \(this.linkPath!)")
				this.block(error, nil)
			})
		}
	}

	func once(with block: @escaping (Error?, FireChannel?) -> Swift.Void) {

		self.block = block

		FireController.db.child(self.channelPath).observeSingleEvent(of: .value, with: { [weak self] snap in
			guard let this = self else { return }
			if !this.fired {
				if let value = snap.value as? [String: Any] {
					this.channel = FireChannel(dict: value, id: snap.key)
					if this.linkPath == nil || this.linkMapMiss {
						this.fired = true
						this.block(nil, this.channel)  // May or may not have link info
					}
					else if this.linkMap != nil {
						this.fired = true
						this.channel!.membershipFrom(dict: this.linkMap!)
						this.block(nil, this.channel)  // May or may not have link info
					}
				}
				else {
					this.fired = true
					this.block(nil, nil)
				}
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read channel: \(this.channelPath!)")
			this.block(error, nil)
		})

		if self.linkPath != nil {
			FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
				guard let this = self else { return }
				if !this.fired {
					if let value = snap.value as? [String: Any] {
						this.linkMap = value
						if this.channel != nil {
							this.fired = true
							this.channel!.membershipFrom(dict: value)
							this.block(nil, this.channel)
						}
					}
					else {
						/* User might not be a member so send the channel without link info */
						this.linkMapMiss = true
						if this.channel != nil {
							this.fired = true
							this.block(nil, this.channel)
						}
					}
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read channel membership: \(this.linkPath!)")
				this.block(error, nil)
			})
		}
	}

	func remove() {
		if self.authHandle != nil {
			Auth.auth().removeStateDidChangeListener(self.authHandle)
		}
		if self.channelHandle != nil {
			FireController.db.child(self.channelPath).removeObserver(withHandle: self.channelHandle)
		}
		if self.linkHandle != nil {
			FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
		}
	}

	deinit {
		remove()
	}
}
