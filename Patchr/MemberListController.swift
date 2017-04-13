//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class MemberListController: BaseTableController {
    
    var inputReactionPath: String!
    var inputEmojiCode: String!
    var inputEmoji: String!
    var inputEmojiCount: Int!
    
    var channel: FireChannel!
    var channelQuery: ChannelQuery!
    var scope: ListScope = .group
    var target: MemberTarget = .group
    var manage = false
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        if self.scope == .channel {
            let groupId = StateController.instance.groupId!
            let channelId = StateController.instance.channelId!
            let userId = UserController.instance.userId!
            self.channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)
            self.channelQuery.once(with: { [weak self] error, channel in
                guard let this = self else { return }
                if channel != nil {
                    this.channel = channel
                    this.bind()
                }
            })
        }
        else {
            bind()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
        }
        self.tableView.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func groupInviteAction(sender: AnyObject?) {
        
        let controller = ContactPickerController()
        controller.flow = .none
        controller.inputRole = "members"
        controller.inputGroupId = StateController.instance.groupId!
        controller.inputGroupTitle = StateController.instance.group.title
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func channelInviteAction(sender: AnyObject?) {
        
        let controller = ChannelInviteController()
        controller.flow = .none
        controller.inputChannelId = self.channel.id!
        controller.inputChannelName = self.channel.name!
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func manageUserAction(sender: AnyObject?) {
        if let button = sender as? AirButton, let user = button.data as? FireUser {
            let controller = MemberSettingsController()
            let wrapper = AirNavigationController(rootViewController: controller)
            controller.inputUser = user
            if self.target == .channel {
                controller.inputChannel = self.channel
                controller.target = .channel
            }
            self.present(wrapper, animated: true)
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
        
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        
        if self.presented || self.popupController != nil {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
    }

    func bind() {
        
        let group = StateController.instance.group!
        if (self.scope == .channel && self.channel.role == "owner") || group.role == "owner" {
            if self.scope != .reaction {
                if self.target == .channel {
                    let addButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(channelInviteAction(sender:)))
                    self.navigationItem.rightBarButtonItems = [addButton]
                }
                else if self.target == .group {
                    let inviteButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(groupInviteAction(sender:)))
                    self.navigationItem.rightBarButtonItems = [inviteButton]
                }
            }
        }
        
        if self.scope == .reaction {
            let noun = (self.inputEmojiCount == 1) ? "person" : "people"
            self.navigationItem.title = "\(self.inputEmoji!)  \(self.inputEmojiCount!) \(noun) reacted with \(self.inputEmojiCode!)"
        }
        else {
            self.navigationItem.title = self.scope == .channel ? "# \(self.channel!.name!)" : group.title!
        }
        
        let groupId = StateController.instance.groupId!
        let channelId = StateController.instance.channelId!
        var query = FireController.db.child("group-members/\(groupId)").queryOrdered(byChild: "index_priority_joined_at_desc")
        if self.scope == .channel {
            query = FireController.db.child("group-channel-members/\(groupId)/\(channelId)")
        }
        else if self.scope == .reaction {
            query = FireController.db.child(self.inputReactionPath)
        }
        
        self.queryController = DataSourceController(name: "member_list")
        self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserListCell
            cell.reset()
            guard let this = self else { return cell }
            
            let snap = data as! FIRDataSnapshot
            let userId = snap.key
            let groupId = StateController.instance.groupId!
            
            if this.target == .group {
                if this.scope == .reaction {
                    cell.userQuery = UserQuery(userId: userId)
                }
                else {
                    cell.userQuery = UserQuery(userId: userId, groupId: groupId)
                }
            }
            else  {
                let channelId = this.channel.id!
                cell.userQuery = UserQuery(userId: userId, groupId: groupId, channelId: channelId)
            }
            
            cell.userQuery.once(with: { [weak self, weak cell] error, user in
                guard let this = self else { return }
                guard let cell = cell else { return }
                if error != nil {
                    Log.w("Permission denied")
                    return
                }
                if user != nil {
                    var target = (this.target == .group) ? "group" : "channel"
                    if this.scope == .reaction {
                        target = "reaction"
                    }
                    cell.bind(user: user!, target: target)
                    if this.manage {
                        if this.scope == .group {
                            if let role = StateController.instance.group!.role, role == "owner" {
                                cell.actionButton?.isHidden = false
                                cell.actionButton?.setTitle("Manage", for: .normal)
                                cell.actionButton?.data = user
                                cell.actionButton?.addTarget(this, action: #selector(this.manageUserAction(sender:)), for: .touchUpInside)
                            }
                        }
                        else if this.scope == .channel {
                            if let role = this.channel.role, role == "owner" {
                                cell.actionButton?.isHidden = false
                                cell.actionButton?.setTitle("Manage", for: .normal)
                                cell.actionButton?.data = user
                                cell.actionButton?.addTarget(this, action: #selector(this.manageUserAction(sender:)), for: .touchUpInside)
                            }
                        }
                    }
                } else {
                    fatalError("User is missing for group or channel member")
                }
            })
            return cell
        }
    }
    
    enum ListScope: Int {
        case group
        case channel
        case reaction
    }
    
    enum MemberTarget: Int {
        case group
        case channel
    }
}

extension MemberListController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserListCell
        let user = cell.user
        let controller = MemberViewController()
        controller.inputUserId = user?.id
        Reporting.track("view_member_detail")
        if self.popupController == nil {
            self.navigationController?.pushViewController(controller, animated: true)
        }
        else {
            controller.contentSizeInPopup = self.contentSizeInPopup
            self.popupController?.push(controller, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
