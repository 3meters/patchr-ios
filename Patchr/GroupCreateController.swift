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

    var groupTitleField = FloatTextField(frame: CGRect.zero)
    var message = AirLabelTitle()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewDidAppear(_ animated: Bool) {
        let _ = self.groupTitleField.becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.groupTitleField.alignUnder(self.message, matchingCenterWithTopPadding: 8, width: 288, height: 48)
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
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.message.text = (self.flow == .onboardCreate)
            ? "Name your new Patchr group."
            : "Create a new Patchr group."
        
        if self.flow == .onboardCreate {
            self.navigationItem.title = "Step 3 of 3"
        }

        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.groupTitleField.placeholder = "Group Name"
        self.groupTitleField.setDelegate(delegate: self)
        self.groupTitleField.keyboardType = .default
        self.groupTitleField.autocapitalizationType = .words
        self.groupTitleField.autocorrectionType = .no
        self.groupTitleField.returnKeyType = UIReturnKeyType.next
        
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.groupTitleField)
        
        /* Navigation bar buttons */
        let createButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [createButton]
        
        if self.flow == .none {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancelAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
    }
    
    func createGroup() {
        
        guard !self.processing else { return }
        self.processing = true
        
        /* Not checking username uniqueness because group doesn't have any yet */
        let groupId = "gr-\(Utils.genRandomId())"
        var groupMap: [String: Any] = ["title": self.groupTitleField.text!]

        FireController.instance.addGroup(groupId: groupId, groupMap: &groupMap, then: { success in
            
            self.progress?.hide(true)
            self.processing = false

            if success {
                if self.flow == .onboardCreate {
                    let controller = InviteViewController()
                    controller.flow = .onboardCreate
                    controller.inputGroupId = groupId
                    controller.inputGroupTitle = self.groupTitleField.text!
                    self.navigationController?.pushViewController(controller, animated: true)
                }
                else {
                    FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                        if firstChannelId != nil {
                            StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
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
            self.groupTitleField.errorMessage = "Name your group"
            return false
        }
        return true
    }

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.groupTitleField {
            self.doneAction(sender: textField)
        }
        return true
    }
}
