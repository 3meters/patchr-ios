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
    let ref = FIRDatabase.database().reference()

    private override init() {}

    /*--------------------------------------------------------------------------------------------
     * Singles
     *--------------------------------------------------------------------------------------------*/

    @discardableResult func observe(path: String, eventType: FIRDataEventType, with block: @escaping (FIRDataSnapshot) -> Swift.Void) -> UInt {
        return self.ref.child(path).observe(eventType, with: block)
    }
    
    func removeObserver(withHandle handle: UInt) {
        self.ref.removeObserver(withHandle: handle)
    }
    
    /*--------------------------------------------------------------------------------------------
     * Collections
     *--------------------------------------------------------------------------------------------*/

    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    func warmup() {}
}
