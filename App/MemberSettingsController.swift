//
//  NotificationSettingsViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD

class MemberSettingsController: UITableViewController {
    
    var inputUser: FireUser?
    var inputUserId: String?
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

    @objc func doneAction(sender: AnyObject?) {
        update()
    }

    @objc func closeAction(sender: AnyObject?) {
        close(animated: true)
    }

    @objc func removeAction(sender: AnyObject?) {
        remove()
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        let userTitle = self.inputUserId != nil ? "deleted".localized() : self.inputUser!.profile?.fullName ?? self.inputUser!.username!
        self.navigationItem.title = userTitle

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 48
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.roleOwnerCell.textLabel?.text = "owner".localized()
        self.roleEditorCell.textLabel?.text = "contributor".localized()
        self.roleReaderCell.textLabel?.text = "reader".localized()
        
        self.roleEditorCell.selectionStyle = .none
        self.roleReaderCell.selectionStyle = .none
        
        let targetTitle = self.inputChannel.title!
        self.removeCell.contentView.addSubview(self.removeButton)
        self.removeCell.accessoryType = .none
        self.removeButton.setTitle("member_settings_remove".localizedFormat(targetTitle).uppercased(), for: .normal)
        self.removeButton.addTarget(self, action: #selector(removeAction(sender:)), for: .touchUpInside)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
        let doneButton = UIBarButtonItem(title: "done".localized(), style: .plain, target: self, action: #selector(doneAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton]
    }
    
    func bind() {

        let userId = self.inputUser != nil ? self.inputUser!.id! : self.inputUserId!
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
        if self.roleNext != self.role {
            Reporting.track("update_channel_member_role")
            let userId = self.inputUser != nil ? self.inputUser!.id! : self.inputUserId!
            let channelId = self.inputChannel.id!
            let path = "channel-members/\(channelId)/\(userId)/role"
            let role = self.roleNext!
            FireController.db.child(path).setValue(role) { error, ref in
                if error != nil {
                    Log.w("Permission denied: \(path)")
                }
                self.closeAction(sender: nil)
            }
        }
    }
    
    func remove() {
        let userTitle = self.inputUserId != nil ? "deleted".localized() : self.inputUser!.profile?.fullName ?? self.inputUser!.username!
        
        DeleteConfirmationAlert(
            title: "confirm".localized(),
            message: "member_remove_message".localizedFormat(userTitle),
            actionTitle: "remove".localized(), cancelTitle: "cancel".localized(), delegate: self) { doIt in
            if doIt {
                
                Reporting.track("remove_channel_member")

                self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
                self.progress!.mode = MBProgressHUDMode.indeterminate
                self.progress!.styleAs(progressStyle: .activityWithText)
                self.progress!.minShowTime = 0.5
                self.progress!.labelText = "progress_removing".localized()
                self.progress!.removeFromSuperViewOnHide = true
                self.progress!.show(true)
                
                let userId = self.inputUser != nil ? self.inputUser!.id! : self.inputUserId!
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
            let roleLabel = (selectedCell?.textLabel!.text!.lowercased())!
            self.roleNext = roleLabel == "contributor" ? "editor" : roleLabel
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
            return "member_settings_role_header".localized().uppercased()
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "member_settings_role_footer".localized()
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
