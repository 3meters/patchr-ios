




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
    
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
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
                        UIShared.Toast(message: "Invite revoked")
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
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.allowsSelection = false
        self.tableView.estimatedRowHeight = 130
        self.tableView.delegate = self
        
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
        let query = FireController.db.child("invites/\(groupId)/\(userId)").queryOrdered(byChild: "status").queryEqual(toValue: self.currentStatus)
        
        self.navigationItem.title = "Invites: \(group.title!)"
        
        if self.tableViewDataSource != nil {
            self.tableViewDataSource = nil
            self.tableView.reloadData()
        }
        
        self.tableViewDataSource = FUITableViewDataSource(
            query: query,
            view: self.tableView,
            populateCell: { [weak self] (view, indexPath, snap) -> InviteListCell in
                
                var invite = snap.value as! [String: Any]
                let status = invite["status"] as! String
                invite["id"] = snap.key
                
                let reuseIdentifier = status
                let cell = view.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! InviteListCell
                cell.reset()
                
                if status == "accepted" {
                    let userId = invite["accepted_by"] as! String
                    let userQuery = UserQuery(userId: userId, groupId: groupId)
                    userQuery.once(with: { user in
                        if user != nil {
                            cell.bind(user: user!, invite: invite)
                        }
                    })
                }
                else {
                    cell.bind(invite: invite)
                    cell.resendButton?.isHidden = false
                    cell.resendButton?.data = invite as AnyObject?
                    cell.resendButton?.addTarget(self, action: #selector(self?.resendInviteAction(sender:)), for: .touchUpInside)
                    cell.revokeButton?.isHidden = false
                    cell.revokeButton?.data = invite as AnyObject?
                    cell.revokeButton?.addTarget(self, action: #selector(self?.revokeInviteAction(sender:)), for: .touchUpInside)
                }
                return cell
        })

        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func resendInvite(invite: [String: Any]) {
        
        let email = invite["email"] as! String
        let role = invite["role"] as! String
        let type = (role == "member") ? "invite-members" : "invite-guests"
        
        var task: [String: Any] = [:]
        if invite["channels"] != nil {
            task["channels"] = invite["channels"]
        }
        task["group"] = invite["group"]
        task["inviter"] = invite["inviter"]
        task["invite_id"] = invite["id"]
        task["link"] = invite["link"]
        task["recipients"] = [email]
        task["type"] = type
        
        let queueRef = FireController.db.child("queue/invites").childByAutoId()
        queueRef.setValue(task)
        UIShared.Toast(message: "Invite re-sent")
    }
}

extension InviteListController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        self.currentStatus = (segmentIndex == 0) ? "pending" : "accepted"
        bind()
    }
}
