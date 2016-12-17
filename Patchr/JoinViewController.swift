//
//  SignInViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import FirebaseAuth
import Firebase

class JoinViewController: BaseEditViewController {

    var message = AirLabelTitle()
    var joinButton = AirButton()
    
    var inputGroupId: String?
    var inputRole: String?
    var inputChannelId: String?
    
    var inputGroupTitle: String?
    var inputChannelName: String?
    
    var inputReferrerId: String?
    var inputReferrerName: String?
    var inputReferrerPhotoUrl: String?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
        memberCheck()   // Redirects if already a member
    }

    override func viewWillLayoutSubviews() {
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.joinButton.alignUnder(self.message, matchingCenterWithTopPadding: 48, width: 288, height: 48)
        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject?) {
        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
        self.progress?.mode = MBProgressHUDMode.indeterminate
        self.progress?.styleAs(progressStyle: .ActivityWithText)
        self.progress?.minShowTime = 0.5
        self.progress?.labelText = "Joining..."
        self.progress?.removeFromSuperViewOnHide = true
        self.progress?.show(true)

        join()
    }

    func closeAction(sender: AnyObject?) {
        close()
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.message.text = "\(self.inputReferrerName!) has invited you to join the Patchr group \(self.inputGroupTitle!)."
        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.joinButton)
        self.contentHolder.isHidden = true
        
        self.joinButton.setTitle("Join group".uppercased(), for: .normal)
        self.joinButton.addTarget(self, action: #selector(doneAction(sender:)), for: .touchUpInside)
        
        /* Navigation bar buttons */
        let joinButton = UIBarButtonItem(title: "Join", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.rightBarButtonItems = [joinButton]
        self.navigationItem.leftBarButtonItems = [closeButton]
    }
    
    func memberCheck() {
        
        /* Catches cases where routing is from password entry */

        let userId = UserController.instance.userId!
        let groupId = self.inputGroupId!
        let path = "group-members/\(groupId)/\(userId)"
        
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                UIShared.Toast(message: "Already a member of this group!")
                self.route()
            }
            else {
                self.contentHolder.alpha = 0.0
                self.contentHolder.isHidden = false
                self.contentHolder.fadeIn()
            }
        })
    }
    
    func join() {
        
        guard !self.processing else { return }
        self.processing = true
        
        let groupId = self.inputGroupId!
        let role = self.inputRole!
        let userId = UserController.instance.userId!
        
        FireController.instance.addUserToGroup(userId: userId, groupId: groupId, channelId: self.inputChannelId, role: role, then: { success in
            self.progress?.hide(true)
            self.processing = false
            if success {
                self.route()
            }
        })
    }
    
    func route() {
        
        let groupId = self.inputGroupId!
        
        if self.inputChannelId != nil {
            StateController.instance.setChannelId(channelId: self.inputChannelId!, groupId: groupId)
            MainController.instance.showChannel(groupId: groupId, channelId: self.inputChannelId!)
            let _ = self.navigationController?.popToRootViewController(animated: false)
            self.closeAction(sender: nil)
        }
        else {
            FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                if firstChannelId != nil {
                    StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                    MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                    let _ = self.navigationController?.popToRootViewController(animated: false)
                    self.closeAction(sender: nil)
                }
            }
        }
    }
}
