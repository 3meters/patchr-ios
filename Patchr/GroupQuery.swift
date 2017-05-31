//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import FirebaseAuth

class GroupQuery: NSObject {

	var authHandle: AuthStateDidChangeListenerHandle!

	var block: ((Error?, Trigger?, FireGroup?) -> Swift.Void)!
	var fired = false

	var groupPath: String!
	var groupHandle: UInt!
	var group: FireGroup!

	var linkPath: String!
	var linkHandle: UInt!
	var linkMap: [String: Any]!
	var linkMapMiss = false

	init(groupId: String, userId: String?) {
		super.init()
		self.groupPath = "groups/\(groupId)"
		if userId != nil {
			self.linkPath = "group-members/\(groupId)/\(userId!)"
		}
	}

	func observe(with block: @escaping (Error?, Trigger?, FireGroup?) -> Swift.Void) {

		self.block = block

		self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
			guard let this = self else { return }
			if auth.currentUser == nil {
				this.remove()
			}
		}

		self.groupHandle = FireController.db.child(self.groupPath).observe(.value, with: { [weak self] snap in
			guard let this = self else { return }
			if let value = snap.value as? [String: Any] {
				this.group = FireGroup(dict: value, id: snap.key)
				if this.linkPath == nil || this.linkMapMiss {
					this.block(nil, .object, this.group)
				}
				else if this.linkMap != nil {
					this.group!.membershipFrom(dict: (this.linkMap)!)
					this.block(nil, .object, this.group)
				}
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read group: \(this.groupPath!)")
			this.block(error, nil, nil)
		})

		if self.linkPath != nil {
			self.linkHandle = FireController.db.child(self.linkPath).observe(.value, with: { [weak self] snap in
				guard let this = self else { return }
				if let value = snap.value as? [String: Any] {
					this.linkMap = value
					if this.group != nil {
						this.group!.membershipFrom(dict: value)
						this.block(nil, .link, this.group)
					}
				}
				else {
					/* Group might be fine but user is not member of group anymore */
					this.linkMapMiss = true
					if this.group != nil {
						this.group!.membershipClear()
						this.block(nil, .link, this.group)
					}
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read group membership: \(this.linkPath!)")
				this.block(error, nil, nil)
			})
		}
	}

	func once(with block: @escaping (Error?, Trigger?, FireGroup?) -> Swift.Void) {

		self.block = block

		FireController.db.child(self.groupPath).observeSingleEvent(of: .value, with: { [weak self] snap in
			guard let this = self else { return }
			if !this.fired {
				if let value = snap.value as? [String: Any] {
					this.group = FireGroup(dict: value, id: snap.key)
					if this.linkPath == nil || this.linkMapMiss {
						this.fired = true
						this.block(nil, .object, this.group)
					}
					else if this.linkMap != nil {
						this.fired = true
						this.group!.membershipFrom(dict: this.linkMap!)
						this.block(nil, .object, this.group)  // May or may not have link info
					}
				}
				else {
					this.fired = true
					this.block(nil, nil, nil)
				}
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read group: \(this.groupPath!)")
			this.block(error, nil, nil)
		})

		if self.linkPath != nil {
			FireController.db.child(self.linkPath).observeSingleEvent(of: .value, with: { [weak self] snap in
				guard let this = self else { return }
				if !this.fired {
					if let value = snap.value as? [String: Any] {
						this.linkMap = value
						if this.group != nil {
							this.fired = true
							this.group!.membershipFrom(dict: this.linkMap!)
							this.block(nil, .link, this.group)
						}
					}
					else {
						/* User might not be a member so send the channel without link info */
						this.linkMapMiss = true
						if this.group != nil {
							this.fired = true
							this.block(nil, .link, this.group)
						}
					}
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read group membership: \(this.linkPath!)")
				this.block(error, nil, nil)
			})
		}
	}

	func remove() {
		if self.authHandle != nil {
			Auth.auth().removeStateDidChangeListener(self.authHandle)
		}
		if self.groupHandle != nil {
			FireController.db.child(self.groupPath).removeObserver(withHandle: self.groupHandle)
		}
		if self.linkHandle != nil {
			FireController.db.child(self.linkPath).removeObserver(withHandle: self.linkHandle)
		}
	}

	deinit {
		remove()
	}
}
