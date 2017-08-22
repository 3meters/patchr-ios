//
//  NotificationSettingsViewController.swift
//  Teeny
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class MemberSettingsController: UITableViewController {
    
    var inputUser: FireUser!
    var inputChannel: FireChannel!
    
    var progress: AirProgress?

    var roleOwnerCell = AirTableViewCell()
    var roleEditorCell = AirTableViewCell()
    var roleReaderCell = AirTableViewCell()
    var removeCell = AirTableViewCell()
    var removeButton = AirLinkButton()
    
    var role: String? = nil
    var roleNext: String? = nil

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
        bind()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(Config.contentWidthMax, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
        self.removeButton.fillSuperview()
    }
    
    deinit {
        self.progress?.hide(true)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject?) {
        update()
    }

    func closeAction(sender: AnyObject?) {
        close(animated: true)
    }

    func removeAction(sender: AnyObject?) {
        remove()
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        let userTitle = self.inputUser!.profile?.fullName ?? self.inputUser!.username!
        self.navigationItem.title = userTitle

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 48
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.roleOwnerCell.textLabel?.text = "Owner"
        self.roleEditorCell.textLabel?.text = "Contributor"
        self.roleReaderCell.textLabel?.text = "Reader"
        
        self.roleEditorCell.selectionStyle = .none
        self.roleReaderCell.selectionStyle = .none
        
        let targetTitle = self.inputChannel.title!
        self.removeCell.contentView.addSubview(self.removeButton)
        self.removeCell.accessoryType = .none
        self.removeButton.setTitle("Remove from \(targetTitle) ".uppercased(), for: .normal)
        self.removeButton.addTarget(self, action: #selector(removeAction(sender:)), for: .touchUpInside)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func bind() {

        let userId = self.inputUser.id!
        let channelId = self.inputChannel.id!
        let path = "channel-members/\(channelId)/\(userId)/role"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            if let memberRole = snap.value as? String {
                self.role = memberRole
                self.roleNext = memberRole
                self.roleOwnerCell.accessoryType = self.role == "owner" ? .checkmark : .none
                self.roleEditorCell.accessoryType = self.role == "editor" ? .checkmark : .none
                self.roleReaderCell.accessoryType = self.role == "reader" ? .checkmark : .none
            }
        }, withCancel: { error in
            Log.w("Permission denied reading: \(path)")
        })
    }
    
    func update() {
        
        var updates = [String: Any]()
        let userId = self.inputUser.id!
        let channelId = self.inputChannel.id!

        if self.roleNext != self.role {
            updates["role"] = self.roleNext!
            Reporting.track("update_channel_member_role")
            FireController.db.child("channel-members/\(channelId)/\(userId)").updateChildValues(updates)
            closeAction(sender: nil)
        }
    }
    
    func remove() {
        let userTitle = self.inputUser!.profile?.fullName ?? self.inputUser!.username!
        let targetTitle = "channel"
        
        DeleteConfirmationAlert(
            title: "Confirm",
            message: "Are you sure you want to remove \(userTitle) from this \(targetTitle)?",
            actionTitle: "Remove", cancelTitle: "Cancel", delegate: self) { doIt in
            if doIt {
                
                Reporting.track("remove_channel_member")

                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress!.mode = MBProgressHUDMode.indeterminate
                self.progress!.styleAs(progressStyle: .activityWithText)
                self.progress!.minShowTime = 0.5
                self.progress!.labelText = "Removing..."
                self.progress!.removeFromSuperViewOnHide = true
                self.progress!.show(true)
                
                let userId = self.inputUser.id!
                let channelId = self.inputChannel.id!
                FireController.instance.deleteMembership(userId: userId, channelId: channelId) { [weak self] error, result in
                    guard let this = self else { return }
                    this.progress?.hide(true)
                    if error == nil {
                        this.closeAction(sender: nil)
                    }
                }
            }
        }
    }
}

extension MemberSettingsController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let selectedCell = tableView.cellForRow(at: indexPath)
            self.roleNext = selectedCell?.textLabel!.text!.lowercased()
            self.roleReaderCell.accessoryType = .none
            self.roleEditorCell.accessoryType = .none
            self.roleOwnerCell.accessoryType = .none
            selectedCell!.accessoryType = .checkmark
            self.tableView.reloadData()
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 { return self.roleOwnerCell }
            if indexPath.row == 1 { return self.roleEditorCell }
            if indexPath.row == 2 { return self.roleReaderCell }
        }
        return self.removeCell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Channel role".uppercased()
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Contributors can post new messages. Both contributors and readers can browse and comment on posted messages. Only owners can invite users and edit the channel."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 72
    }
}
