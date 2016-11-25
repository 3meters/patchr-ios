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
    var userNameField = AirTextField()
    var errorLabel = AirLabelDisplay()
    
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

    override func viewDidAppear(_ animated: Bool) {
        self.userNameField.becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.userNameField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.errorLabel.alignUnder(self.userNameField, matchingCenterWithTopPadding: 0, width: 288, height: errorSize.height)

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject?) {
        if isValid() {
            self.activeTextField?.resignFirstResponder()
            
            self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
            self.progress?.mode = MBProgressHUDMode.indeterminate
            self.progress?.styleAs(progressStyle: .ActivityWithText)
            self.progress?.minShowTime = 0.5
            self.progress?.labelText = "Joining..."
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)

            join()
        }
    }

    func closeAction(sender: AnyObject?) {
        close()
    }
    
    override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        self.errorLabel.fadeOut()
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.userNameField {
            let lowercased = (self.userNameField.text! as NSString).replacingCharacters(in: range, with: string.lowercased())
            self.userNameField.text = lowercased
            return false
        }
        return true
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.message.text = "Your username for the \(self.inputGroupTitle!) group."
        
        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.userNameField.placeholder = "Username (lower case)"
        self.userNameField.delegate = self
        self.userNameField.keyboardType = .default
        self.userNameField.autocapitalizationType = .none
        self.userNameField.autocorrectionType = .no
        self.userNameField.returnKeyType = .next
        
        self.errorLabel.textColor = Theme.colorTextValidationError
        self.errorLabel.alpha = 0.0
        self.errorLabel.numberOfLines = 0
        self.errorLabel.font = Theme.fontValidationError
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.userNameField)
        self.contentHolder.addSubview(self.errorLabel)
        self.contentHolder.isHidden = true
        
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
        
        let username = self.userNameField.text!
        let groupId = self.inputGroupId!
        let role = self.inputRole!
        
        /* We have an authenticated user and they are not already a member */
        FireController.instance.usernameExists(groupId: groupId, username: username, next: { exists in
            if exists {
                self.progress?.hide(true)
                self.processing = false
                self.errorLabel.text = "Choose another username"
                self.view.setNeedsLayout()
                self.errorLabel.fadeIn()
            }
            else {
                FireController.instance.addUserToGroup(groupId: groupId, channelId: self.inputChannelId, role: role, username: username, then: { success in
                    self.progress?.hide(true)
                    self.processing = false
                    if success {
                        self.route()
                    }
                })
            }
        })
    }
    
    func route() {
        
        let groupId = self.inputGroupId!
        
        if self.inputChannelId != nil {
            StateController.instance.setGroupId(groupId: groupId, channelId: self.inputChannelId!)
            MainController.instance.showChannel(groupId: groupId, channelId: self.inputChannelId!)
            let _ = self.navigationController?.popToRootViewController(animated: false)
            self.closeAction(sender: nil)
        }
        else {
            FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                if firstChannelId != nil {
                    StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
                    MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                    let _ = self.navigationController?.popToRootViewController(animated: false)
                    self.closeAction(sender: nil)
                }
            }
        }
    }
    
    func isValid() -> Bool {

        if self.userNameField.isEmpty {
            self.errorLabel.text = "Choose your username for this group"
            self.view.setNeedsLayout()
            self.errorLabel.fadeIn()
            return false
        }
        
        let username = userNameField.text!
        let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
        if username.rangeOfCharacter(from: characterSet.inverted) != nil {
            self.errorLabel.text = "Username must be lower case and cannot contain spaces or periods."
            self.view.setNeedsLayout()
            self.errorLabel.fadeIn()
            return false
        }
        
        if (userNameField.text!.utf16.count > 21) {
            self.errorLabel.text = "Username must be 21 characters or less."
            self.view.setNeedsLayout()
            self.errorLabel.fadeIn()
            return false
        }

        return true
    }

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == self.userNameField {
            self.doneAction(sender: textField)
        }

        return true
    }
}
