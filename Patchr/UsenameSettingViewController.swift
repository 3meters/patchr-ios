//
//  NotificationSettingsViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class UsernameSettingViewController: UITableViewController, UITextFieldDelegate {

    /* Notifications */

    var usernameCell = AirTextFieldCell()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.usernameCell.textField.becomeFirstResponder()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
        self.usernameCell.textField.fillSuperview(withLeftPadding: 16, rightPadding: 16, topPadding: 8, bottomPadding: 8)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func doneAction(sender: AnyObject) {
        if isValid() {
            update()
        }
    }
    
    func cancelAction(sender: AnyObject) {
        let _ = self.navigationController?.popViewController(animated: true)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.navigationItem.title = "Username"

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        
        if let group = StateController.instance.group, let username = UserController.instance.user?.username {
            self.usernameCell.textField.text = username
            self.usernameCell.textField.delegate = self
            self.usernameCell.textField.keyboardType = .default
            self.usernameCell.textField.autocapitalizationType = .none
            self.usernameCell.textField.autocorrectionType = .no
            self.usernameCell.textField.returnKeyType = .done
        }
        
        /* Navigation bar buttons */
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelAction(sender:)))
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.leftBarButtonItems = [cancelButton]
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func update() {
        if isValid() {
            let username = self.usernameCell.textField.text!
            let groupId = StateController.instance.groupId
            let userId = UserController.instance.userId
            let memberGroupsPath = "member-groups/\(userId!)/\(groupId!)/username"
            let groupMembersPath = "group-members/\(groupId!)/\(userId!)/username"
            
            let updates: [String: Any] = [
                groupMembersPath: username,
                memberGroupsPath: username
            ]
            
            FireController.db.updateChildValues(updates) {_,_ in
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func isValid() -> Bool {
        
        if self.usernameCell.textField.isEmpty {
            Alert(title: "Choose your username for this group")
            return false
        }
        
        let username = usernameCell.textField.text!
        let characterSet: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-")
        if username.rangeOfCharacter(from: characterSet.inverted) != nil {
            Alert(title: "Username must be lower case and cannot contain spaces or periods.")
            return false
        }
        
        if (usernameCell.textField.text!.utf16.count > 21) {
            Alert(title: "Username must be 21 characters or less.")
            return false
        }
        
        return true
    }
}

extension UsernameSettingViewController {
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 1
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                return self.usernameCell
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
}
