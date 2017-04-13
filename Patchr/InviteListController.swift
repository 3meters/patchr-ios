




//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import TwicketSegmentedControl

class InviteListController: BaseTableController, UITableViewDelegate {
    
    var switcher = TwicketSegmentedControl()
    var rule = UIView()
    var currentStatus = "pending"
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.switcher.anchorTopCenter(withTopPadding: 68, width: 200, height: 48)
        self.rule.alignUnder(self.switcher, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: Theme.dimenRuleThickness)
        let tableHeight = view.frame.height - self.rule.bounds.origin.y
        self.tableView.alignUnder(self.switcher, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 1, height: tableHeight)
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func resendInviteAction(sender: AnyObject?) {
        if let button = sender as? AirButton,
            let invite = button.data as? [String: Any],
            let inviteId = invite["id"] as? String,
            let inviter = invite["inviter"] as? [String: Any],
            let inviterId = inviter["id"] as? String,
            let groupId = StateController.instance.groupId {
            FireController.instance.deleteInvite(groupId: groupId, inviterId: inviterId, inviteId: inviteId)
                resendInvite(invite: invite)
        }
    }
    
    func revokeInviteAction(sender: AnyObject?) {
        DeleteConfirmationAlert(
            title: "Confirm Revoke",
            message: "Are you sure you want to revoke this invitation?",
            actionTitle: "Revoke", cancelTitle: "Cancel", delegate: self) { doIt in
                if doIt {
                    if let button = sender as? AirButton,
                        let invite = button.data as? [String: Any],
                        let inviteId = invite["id"] as? String,
                        let inviter = invite["inviter"] as? [String: Any],
                        let inviterId = inviter["id"] as? String,
                        let groupId = StateController.instance.groupId {
                        FireController.instance.deleteInvite(groupId: groupId, inviterId: inviterId, inviteId: inviteId)
                        UIShared.toast(message: "Invite revoked")
                    }
                }
        }
    }
    
    func longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let point = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                let cell = self.tableView.cellForRow(at: indexPath) as! InviteListCell
                let snap = self.queryController.snapshot(at: indexPath.row)
                var invite = snap.value as! [String: Any]
                invite["id"] = snap.key
                showInviteActions(invite: invite, sourceView: cell.contentView)
            }
        }
    }
    
    func deleteInviteAction(invite: [String: Any]) {
        DeleteConfirmationAlert(
            title: "Confirm Delete",
            message: "Are you sure you want to delete this? Deleting an accepted invite only clears it from list.",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    if let inviteId = invite["id"] as? String,
                        let inviter = invite["inviter"] as? [String: Any],
                        let inviterId = inviter["id"] as? String,
                        let group = invite["group"] as? [String: Any],
                        let groupId = group["id"] as? String {
                        FireController.instance.deleteInvite(groupId: groupId, inviterId: inviterId, inviteId: inviteId) { success in
                            if success {
                                UIShared.toast(message: "Invite deleted")
                            }
                        }
                    }
                }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.rule.backgroundColor = Theme.colorRule
        
        self.tableView.register(UINib(nibName: "InvitePendingListCell", bundle: nil), forCellReuseIdentifier: "pending")
        self.tableView.register(UINib(nibName: "InviteAcceptedListCell", bundle: nil), forCellReuseIdentifier: "accepted")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 116, right: 0)
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.allowsSelection = false
        self.tableView.estimatedRowHeight = 130
        
        self.switcher.setSegmentItems(["Pending","Accepted"])
        self.switcher.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 48)
        self.switcher.sliderBackgroundColor = Colors.accentColorFill
        self.switcher.delegate = self
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.switcher)
        self.view.addSubview(self.rule)
    }

    func bind() {

        let groupId = StateController.instance.groupId!
        let userId = UserController.instance.userId!
        let group = StateController.instance.group!
        let query = FireController.db.child("invites/\(groupId)/\(userId)")
            .queryOrdered(byChild: "status")
            .queryEqual(toValue: self.currentStatus)
        
        self.navigationItem.title = "Invites: \(group.title!)"
        
        if self.queryController != nil {
            self.queryController = nil
            self.tableView.reloadData()
        }
        
        self.queryController = DataSourceController(name:"invite_list")
        self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
            
            let snap = data as! FIRDataSnapshot
            var invite = snap.value as! [String: Any]
            let status = invite["status"] as! String
            invite["id"] = snap.key
            
            let cell = tableView.dequeueReusableCell(withIdentifier: status, for: indexPath) as! InviteListCell
            cell.reset()    // Releases previous data observers
            guard let this = self else { return cell }
            
            if status == "accepted" {
                let userId = invite["accepted_by"] as! String
                cell.userQuery = UserQuery(userId: userId, groupId: groupId)
                cell.userQuery.once(with: { [weak this, weak cell] error, user in
                    guard let this = this else { return }
                    guard let cell = cell else { return }
                    if user != nil {
                        let recognizer = UILongPressGestureRecognizer(target: this, action: #selector(this.longPressAction(sender:)))
                        recognizer.minimumPressDuration = TimeInterval(0.2)
                        cell.addGestureRecognizer(recognizer)
                        cell.data = invite as AnyObject?
                        cell.bind(user: user!, invite: invite)
                    }
                })
            }
            else {
                cell.bind(invite: invite)
                cell.resendButton?.isHidden = false
                cell.resendButton?.data = invite as AnyObject?
                cell.resendButton?.addTarget(self, action: #selector(this.resendInviteAction(sender:)), for: .touchUpInside)
                cell.revokeButton?.isHidden = false
                cell.revokeButton?.data = invite as AnyObject?
                cell.revokeButton?.addTarget(self, action: #selector(this.revokeInviteAction(sender:)), for: .touchUpInside)
            }
            return cell
        }
    }
    
    func resendInvite(invite: [String: Any]) {

        let userId = UserController.instance.userId!
        let email = invite["email"] as! String
        let role = invite["role"] as! String
        let type = (role == "member") ? "invite-members" : "invite-guests"
        let ref = FireController.db.child("queue/invites").childByAutoId()
        let timestamp = FireController.instance.getServerTimestamp()
        
        var task: [String: Any] = [:]
        if invite["channels"] != nil {
            task["channels"] = invite["channels"]
        }
        task["created_at"] = timestamp
        task["created_by"] = userId
        task["group"] = invite["group"]
        task["inviter"] = invite["inviter"]
        task["invite_id"] = invite["id"]
        task["link"] = invite["link"]
        task["id"] = ref.key
        task["recipients"] = [email]
        task["state"] = "waiting"
        task["type"] = type
        
        ref.setValue(task)
        UIShared.toast(message: "Invite re-sent")
    }
    
    func showInviteActions(invite: [String: Any], sourceView: UIView?) {
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let delete = UIAlertAction(title: "Delete invite", style: .destructive) { action in
            self.deleteInviteAction(invite: invite)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            sheet.dismiss(animated: true, completion: nil)
        }
        
        sheet.addAction(delete)
        sheet.addAction(cancel)
        
        if let presenter = sheet.popoverPresentationController, let sourceView = sourceView {
            presenter.sourceView = sourceView
            presenter.sourceRect = sourceView.bounds
        }
        
        present(sheet, animated: true, completion: nil)
    }

}

extension InviteListController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        self.currentStatus = (segmentIndex == 0) ? "pending" : "accepted"
        bind()
    }
}
