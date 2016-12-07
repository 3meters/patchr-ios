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

class GroupCreateController: BaseEditViewController {

    var groupTitleField = AirTextField()
    var userNameField = AirTextField()
    var errorLabel = AirLabelDisplay()
    var message = AirLabelTitle()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.groupTitleField.becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.groupTitleField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.userNameField.alignUnder(self.groupTitleField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
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
            self.progress?.labelText = "Activating..."
            self.progress?.removeFromSuperViewOnHide = true
            self.progress?.show(true)

            createGroup()
        }
    }

    func cancelAction(sender: AnyObject?) {
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

        self.message.text = (self.flow == .onboardCreate)
            ? "Share and message more safely because Patchr groups stay focused."
            : "Create a new Patchr group."
        
        if self.flow == .onboardCreate {
            self.navigationItem.title = "Step 3 of 3"
        }

        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.groupTitleField.placeholder = "Group Name"
        self.groupTitleField.delegate = self
        self.groupTitleField.keyboardType = .default
        self.groupTitleField.autocapitalizationType = .words
        self.groupTitleField.autocorrectionType = .no
        self.groupTitleField.returnKeyType = UIReturnKeyType.next
        
        self.userNameField.placeholder = "Your username for this group (lower case)"
        self.userNameField.delegate = self
        self.userNameField.keyboardType = .default
        self.userNameField.autocapitalizationType = .none
        self.userNameField.autocorrectionType = .no
        self.userNameField.returnKeyType = UIReturnKeyType.next
        
        self.errorLabel.textColor = Theme.colorTextValidationError
        self.errorLabel.alpha = 0.0
        self.errorLabel.numberOfLines = 0
        self.errorLabel.font = Theme.fontValidationError
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.groupTitleField)
        self.contentHolder.addSubview(self.userNameField)
        self.contentHolder.addSubview(self.errorLabel)
        
        /* Navigation bar buttons */
        let createButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [createButton]
    }
    
    func createGroup() {
        
        guard !self.processing else { return }
        self.processing = true
        
        /* Not checking username uniqueness because group doesn't have any yet */
        let username = self.userNameField.text!
        let groupId = "gr-\(Utils.genRandomId())"
        var groupMap: [String: Any] = ["title": self.groupTitleField.text!]

        FireController.instance.addGroup(groupId: groupId, groupMap: &groupMap, username: username, then: { success in
            
            self.progress?.hide(true)
            self.processing = false

            if success {
                if self.flow == .onboardCreate {
                    let controller = InviteViewController()
                    controller.flow = .onboardCreate
                    controller.inputGroupId = groupId
                    controller.inputGroupTitle = self.groupTitleField.text!
                    controller.inputUsername = username
                    self.navigationController?.pushViewController(controller, animated: true)
                }
                else {
                    FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                        if firstChannelId != nil {
                            StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
                            MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                            let _ = self.navigationController?.popToRootViewController(animated: false)
                            self.cancelAction(sender: nil)
                        }
                    }
                }
            }
        })
    }
    
    func isValid() -> Bool {

        if self.groupTitleField.isEmpty {
            Alert(title: "Name your group")
            return false
        }
        
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

        if textField == self.groupTitleField {
            userNameField.becomeFirstResponder()
        }
        else if textField == self.userNameField {
            self.doneAction(sender: textField)
        }

        return true
    }
}
