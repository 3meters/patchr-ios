




//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class MemberListController: BaseTableController, UITableViewDelegate {
    
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    
    var channel: FireChannel!
    
    var scope: ListScope = .group
    var target: MemberTarget = .group
    
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
            let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)
            channelQuery.once(with: { channel in
                if channel != nil {
                    self.channel = channel
                    self.bind()
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
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func groupInviteAction(sender: AnyObject?) {
        let controller = InviteViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func channelInviteAction(sender: AnyObject?) {
        let controller = MemberPickerController()
        let wrapper = AirNavigationController(rootViewController: controller)
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
    }
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func manageUserAction(sender: AnyObject?) {
        if let button = sender as? AirButton, let user = button.data as? FireUser {
            let controller = MemberSettingsController()
            controller.inputUser = user
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func removeMemberAction(sender: AnyObject?) {
        if let button = sender as? AirButton, let user = button.data as? FireUser {
            let groupId = self.channel.group!
            let channelId = self.channel.id!
            let userId = user.id!
            FireController.instance.removeUserFromChannel(userId: userId, groupId: groupId, channelId: channelId)
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
        
        self.cellReuseIdentifier = "user-cell"
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        
        if self.presented {
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
        }
    }

    func bind() {

        let groupId = StateController.instance.groupId!
        let group = StateController.instance.group!
        var query = FireController.db.child("group-members/\(groupId)")
            .queryOrdered(byChild: "index_priority_joined_at_desc")
        
        if self.scope == .channel {
            let channelId = StateController.instance.channelId!
            query = FireController.db.child("channel-members/\(channelId)")
        }
        
        if (self.scope == .channel && self.channel.role == "owner") || StateController.instance.group?.role == "owner" {
            if self.target == .channel {
                let addButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(channelInviteAction(sender:)))
                self.navigationItem.rightBarButtonItems = [addButton]
            }
            else if self.target == .group {
                let inviteButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(groupInviteAction(sender:)))
                self.navigationItem.rightBarButtonItems = [inviteButton]
            }
            
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
        
        self.navigationItem.title = self.scope == .channel ? "# \(self.channel!.name!)" : group.title!
        
        self.tableViewDataSource = FUITableViewDataSource(
            query: query,
            view: self.tableView,
            populateCell: { [weak self] (view, indexPath, snap) -> UserListCell in
                
                let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! UserListCell
                let userId = snap.key
                let userQuery = UserQuery(userId: userId, groupId: groupId)
                
                cell.reset()

                userQuery.once(with: { user in
                    if user != nil {
                        cell.bind(user: user!)
                        if self?.scope == .group {
                            if let role = StateController.instance.group!.role, (role == "owner" || role == "admin") {
                                cell.actionButton?.isHidden = false
                                cell.actionButton?.setTitle("Manage", for: .normal)
                                cell.actionButton?.data = user
                                cell.actionButton?.addTarget(self, action: #selector(self?.manageUserAction(sender:)), for: .touchUpInside)
                            }
                        }
                        else if self?.scope == .channel {
                            if let role = StateController.instance.group!.role, (role == "owner" || role == "admin") {
                                if user!.id != UserController.instance.userId {
                                    cell.actionButton?.isHidden = false
                                    cell.actionButton?.setTitle("Remove", for: .normal)
                                    cell.actionButton?.data = user
                                    cell.actionButton?.addTarget(self, action: #selector(self?.removeMemberAction(sender:)), for: .touchUpInside)
                                }
                            }
                        }
                    }
                })
                
                return cell
        })

        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserListCell
        let user = cell.user
        let controller = MemberViewController()
        controller.inputUserId = user?.id
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    enum ListScope: Int {
        case group
        case channel
    }
    
    enum MemberTarget: Int {
        case group
        case channel
    }
}