//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class UserQuery: NSObject {

	var authHandle: FIRAuthStateDidChangeListenerHandle!
	var onlineHandle: UInt!

	var block: ((Error?, FireUser?) -> Swift.Void)!
	var fired = false

	var userPath: String!
	var userHandle: UInt!
	var userId: String!
	var user: FireUser!

	var linkPath: String!
	var linkHandle: UInt!
	var linkMap: [String: Any]!
	var linkMapMiss = false

	init(userId: String, groupId: String? = nil, channelId: String? = nil, trackPresence: Bool = false) {
		super.init()
		self.userId = userId
		self.userPath = "users/\(userId)"
		if channelId != nil {
			self.linkPath = "group-channel-members/\(groupId!)/\(channelId!)/\(userId)"
		}
		else if groupId != nil {
			self.linkPath = "group-members/\(groupId!)/\(userId)"
		}

		if trackPresence {
			self.onlineHandle = FireController.db.child(".info/connected").observe(.value, with: { [weak self] snap in
				guard let this = self else { return }
				if !(snap.value is NSNull) {
					let timestamp = FireController.instance.getServerTimestamp()
					FireController.db.child((this.userPath)!).onDisconnectUpdateChildValues(["presence": timestamp])
					FireController.db.child((this.userPath)!).updateChildValues(["presence": true])
				}
			})
		}
	}

	func observe(with block: @escaping (Error?, FireUser?) -> ()) {

		self.block = block

		self.authHandle = FIRAuth.auth()?.addStateDidChangeListener() { [weak self] auth, user in
			guard let this = self else { return }
			if auth.currentUser == nil {
				this.remove()
			}
		}

		self.userHandle = FireController.db.child(self.userPath).observe(.value, with: { [weak self] snap in
			guard let this = self else { return }
			if let value = snap.value as? [String: Any] {
				this.user = FireUser(dict: value, id: snap.key)
				if this.linkPath == nil || this.linkMapMiss {
					this.block(nil, this.user)  // May or may not have link info
				}
				else if this.linkMap != nil {
					this.user!.membershipFrom(dict: (this.linkMap)!)
					this.block(nil, this.user)  // May or may not have link info
				}
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read user: \(this.userPath!)")
			this.block(error, nil)
		})

		if self.linkPath != nil {
			self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
				guard let this = self else { return }
				if let value = snap.value as? [String: Any] {
					this.linkMap = value
					if this.user != nil {
						this.user!.membershipFrom(dict: value)
						this.block(nil, this.user)
					}
				}
				else {
					/* User might be fine but group was deleted */
					this.linkMapMiss = true
					if this.user != nil {
						this.user!.membershipClear()
						this.block(nil, this.user)
					}
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read user membership: \(this.linkPath!)")
				this.block(error, nil)
			})
		}
	}

	func once(with block: @escaping (Error?, FireUser?) -> Swift.Void) {

		self.block = block

		FireController.db.child(self.userPath).observeSingleEvent(of: .value, with: { [weak self] snap in
			guard let this = self else { return }
			if !this.fired {
				if let value = snap.value as? [String: Any] {
					this.user = FireUser(dict: value, id: snap.key)
					if this.linkPath == nil || this.linkMapMiss {
						this.fired = true
						this.block(nil, this.user)  // May or may not have link info
					}
					else if this.linkMap != nil {
						this.fired = true
						this.user!.membershipFrom(dict: this.linkMap!)
						this.block(nil, this.user)  // May or may not have link info
					}
				}
				else {
					this.fired = true
					this.block(nil, nil)
				}
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read user: \(this.userPath!)")
			this.block(error, nil)
		})

		if self.linkPath != nil {
			FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
				guard let this = self else { return }
				if !this.fired {
					if let value = snap.value as? [String: Any] {
						this.linkMap = value
						if this.user != nil {
							this.fired = true
							this.user!.membershipFrom(dict: value)
							this.block(nil, this.user)
						}
					}
					else {
						this.linkMapMiss = true
						if this.user != nil {
							this.fired = true
							this.block(nil, this.user)
						}
					}
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read user membership: \(this.linkPath!)")
				this.block(error, nil)
			})
		}
	}

	func remove() {
		if self.authHandle != nil {
			FIRAuth.auth()?.removeStateDidChangeListener(self.authHandle)
		}
		if self.userHandle != nil {
			FireController.db.child(self.userPath).removeObserver(withHandle: self.userHandle)
		}
		if self.linkHandle != nil {
			FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
		}
		if self.onlineHandle != nil {
			FireController.db.child(".info/connected").removeObserver(withHandle: self.onlineHandle)
		}
	}

	deinit {
		remove()
	}
}
