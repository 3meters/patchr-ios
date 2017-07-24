//
// Created by Jay Massena on 11/13/16.
// Copyright (c) 2016 3meters. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class UserQuery: NSObject {

	var authHandle: AuthStateDidChangeListenerHandle!
	var onlineHandle: UInt!

	var block: ((Error?, FireUser?) -> Swift.Void)!
	var fired = false

	var userPath: String!
	var userHandle: UInt!
	var userId: String!
	var user: FireUser!

	var channelMembershipPath: String!
	var channelMembershipHandle: UInt!
	var channelMembershipMap: [String: Any]!
	var channelMapMiss = false

	init(userId: String, channelId: String? = nil, trackPresence: Bool = false) {
		super.init()
		self.userId = userId
		self.userPath = "users/\(userId)"
		if channelId != nil {
			self.channelMembershipPath = "channel-members/\(channelId!)/\(userId)"
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

		self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
			guard let this = self else { return }
			if auth.currentUser == nil {
				this.remove()
			}
		}

		self.userHandle = FireController.db.child(self.userPath).observe(.value, with: { [weak self] snap in
			guard let this = self else { return }
			if let value = snap.value as? [String: Any] {
				this.user = FireUser(dict: value, id: snap.key)
				this.notify()
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read user: \(this.userPath!)")
			this.block(error, nil)
		})

		if self.channelMembershipPath != nil {
			self.channelMembershipHandle = FireController.db.child(self.channelMembershipPath).observe(.value, with: { [weak self] snap in
				guard let this = self else { return }
				if let value = snap.value as? [String: Any] {
					this.channelMembershipMap = value
					this.notify()
				}
				else {
					/* User might be fine but group was deleted */
					this.channelMapMiss = true
					this.user?.channel?.clear()
					this.notify()
				}
			}, withCancel: { [weak self] error in
				guard let this = self else { return }
				Log.v("Permission denied trying to read user channel membership: \(this.channelMembershipPath!)")
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
                    this.notify()
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

        if self.channelMembershipPath != nil {
            FireController.db.child(self.channelMembershipPath).observeSingleEvent(of: .value, with: { [weak self] snap in
                guard let this = self else { return }
                if !this.fired {
                    if let value = snap.value as? [String: Any] {
                        this.channelMembershipMap = value
                        this.notify()
                    }
                    else {
                        this.channelMapMiss = true
                        this.notify()
                    }
                }
                }, withCancel: { [weak self] error in
                    guard let this = self else { return }
                    Log.v("Permission denied trying to read user membership: \(this.channelMembershipPath!)")
                    this.block(error, nil)
            })
        }
	}
    
    func notify() {
        guard self.user != nil else { return }
        guard self.channelMembershipPath == nil || (self.channelMembershipMap != nil || self.channelMapMiss) else { return }
        
        if self.channelMembershipMap != nil {
            self.user!.channel = ChannelMembership(dict: self.channelMembershipMap)
        }
        self.fired = true
        self.block(nil, self.user)
    }

	func remove() {
		if self.authHandle != nil {
			Auth.auth().removeStateDidChangeListener(self.authHandle)
		}
		if self.userHandle != nil {
			FireController.db.child(self.userPath).removeObserver(withHandle: self.userHandle)
		}
		if self.onlineHandle != nil {
			FireController.db.child(".info/connected").removeObserver(withHandle: self.onlineHandle)
		}
	}

	deinit {
		remove()
	}
}
