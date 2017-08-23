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
    var membership: [String: Any]?
	var userPath: String!
	var userHandle: UInt!
	var user: FireUser!

    init(userId: String, membership: [String: Any]? = nil, trackPresence: Bool = false) {
		super.init()
		self.userPath = "users/\(userId)"
        self.membership = membership
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

	func observe(with block: @escaping (Error?, FireUser?) -> Swift.Void) {

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
                this.user = FireUser(dict: value, membership: this.membership, id: snap.key)
                this.block(nil, this.user)
			}
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to observe user: \(this.userPath!)")
			this.block(error, nil)
		})
	}

	func once(with block: @escaping (Error?, FireUser?) -> Swift.Void) {

		self.block = block

		FireController.db.child(self.userPath).observeSingleEvent(of: .value, with: { [weak self] snap in
			guard let this = self else { return }
            if let value = snap.value as? [String: Any] {
                this.user = FireUser(dict: value, membership: this.membership, id: snap.key)
                this.block(nil, this.user)
            }
		}, withCancel: { [weak self] error in
			guard let this = self else { return }
			Log.v("Permission denied trying to read user once: \(this.userPath!)")
			this.block(error, nil)
		})
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
