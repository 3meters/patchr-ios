/*
 * Firebase controller
 *
 * Provide convenience functionality when interacting with the Firebase database.
 */
import UIKit
import Firebase
import FirebaseDatabase

class FireController: NSObject {

    static let instance = FireController()
    let db = FIRDatabase.database().reference()

    private override init() {}
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func autoPickChannel(userId: String, groupId: String, preferGeneral: Bool) {
        
        let path = "member-channels/\(userId)/\(groupId)"
        let ref = self.db.child(path)
        ref.observeSingleEvent(of: .childAdded, with: { snap in
            
            let channelId = snap.key
            let path = "group-channels/\(groupId)/\(channelId)"
            let ref = self.db.child(path)
            ref.observeSingleEvent(of: .value, with: { snap in
                if let channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key) {
                    if !preferGeneral || channel.isGeneral! {
                        MainController.instance.setChannelId(channelId: channel.id)
                        ref.removeAllObservers()
                    }
                }
            })
        })
    }
}
