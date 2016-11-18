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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.groupTitleField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.userNameField.alignUnder(self.groupTitleField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.errorLabel.alignUnder(self.userNameField, matchingCenterWithTopPadding: 0, width: 288, height: errorSize.height)

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject?) {
        if isValid() {
            self.activeTextField?.resignFirstResponder()
            createGroup()
        }
    }

    func cancelAction(sender: AnyObject?) {
        if self.isModal {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
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

        self.message.text = "Share and message more safely because Patchr groups stay focused."

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
        let nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [nextButton]
    }
    
    func createGroup() {
        
        let groupId = "gr-\(Utils.genRandomId())"
        var groupMap: [String: Any] = ["title": self.groupTitleField.text!]

        FireController.instance.addGroup(groupId: groupId, groupMap: &groupMap, then: { success in
            if success {
                FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                    if firstChannelId != nil {
                        StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
                        MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                        let _ = self.navigationController?.popToRootViewController(animated: false)
                        self.cancelAction(sender: nil)
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

        if textField == self.userNameField {
            self.doneAction(sender: textField)
            textField.resignFirstResponder()
            return false
        }

        return true
    }
}
