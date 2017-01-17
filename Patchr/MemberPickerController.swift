




//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class MemberPickerController: BaseTableController, UITableViewDelegate {
    
    var submitButton: UIBarButtonItem!
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    let cellReuseIdentifier = "user-cell"
    
    var invites: [String: Any] = [:]
    
    var channel: FireChannel!
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        let groupId = StateController.instance.groupId!
        let channelId = StateController.instance.channelId!
        let userId = UserController.instance.userId!
        let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)
        
        channelQuery.once(with: { channel in
            if channel != nil {
                self.channel = channel
                self.bind()
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func sendInvitesAction(sender: AnyObject?) {
        invite()
    }
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.allowsMultipleSelection = true
        
        self.view.addSubview(self.tableView)
        
        self.submitButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(sendInvitesAction(sender:)))
        self.submitButton.isEnabled = false
        self.navigationItem.rightBarButtonItems = [self.submitButton]
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
    }

    func bind() {

        let groupId = StateController.instance.groupId!
        let channelName = self.channel.name!
        let query = FireController.db.child("group-members/\(groupId)").queryOrdered(byChild: "index_priority_joined_at_desc")
        
        self.navigationItem.title = "Invite to # \(channelName)"
        
        self.tableViewDataSource = FUITableViewDataSource(
            query: query,
            view: self.tableView,
            populateCell: { [weak self] (view, indexPath, snap) -> UserListCell in
                
                let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! UserListCell
                let userId = snap.key
                let channelId = (self?.channel!.id!)!
                let userQuery = UserQuery(userId: userId, groupId: groupId)
                
                cell.selectionStyle = .none
                cell.accessoryType = .none
                cell.roleLabel?.isHidden = true
                cell.reset()

                userQuery.once(with: { user in
                    if user != nil {
                        FireController.instance.isChannelMember(userId: userId, channelId: channelId, next: { member in
                            cell.bind(user: user!)
                            if member {
                                cell.roleLabel?.isHidden = false
                                cell.roleLabel?.text = "already a member"
                                cell.roleLabel?.textColor = MaterialColor.lightGreen.base
                                cell.checkBox?.isHidden = true
                                cell.allowSelection = false
                            }
                            else {
                                cell.roleLabel?.isHidden = true
                                cell.checkBox?.isHidden = false
                                cell.checkBox?.on = cell.isSelected
                            }
                        })
                    }
                })
                
                return cell
        })

        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func invite() {
        let channelName = self.channel.name!
        var message = "The following users will be added to the \(channelName) channel:\n\n"
        for userId in self.invites.keys {
            if let username = (self.invites[userId] as! FireUser).username {
                message += "\(username)\n"
            }
        }
        
        UpdateConfirmationAlert(title: "Add to channel", message: message, actionTitle: "Add", cancelTitle: "Cancel", delegate: nil, onDismiss: { doit in
            if doit {
                let groupId = self.channel.group!
                let channelId = self.channel.id!
                for userId in self.invites.keys {
                    FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
                }
                self.close()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            if cell.allowSelection {
                cell.checkBox?.setOn(true, animated: true)
                let user = cell.user!
                self.invites[user.id!] = user
                self.submitButton.isEnabled = (self.invites.count > 0)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            cell.checkBox?.setOn(false, animated: true)
            let user = cell.user!
            self.invites.removeValue(forKey: user.id!)
            self.submitButton.isEnabled = (self.invites.count > 0)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
