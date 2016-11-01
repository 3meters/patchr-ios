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

}
