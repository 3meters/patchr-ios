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
            let channelId = StateController.instance.channelId!
            let userId = UserController.instance.userId!
            self.channelQuery = ChannelQuery(channelId: channelId, userId: userId)
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
    
    func channelInviteAction(sender: AnyObject?) {        
        let controller = InviteViewController()
        controller.flow = .none
        controller.inputCode = self.channel.code!
        controller.inputChannelId = self.channel.id!
        controller.inputChannelTitle = self.channel.title!
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
        
        if (self.scope == .channel && self.channel.role == "owner") {
            if self.scope != .reaction {
                let addButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(channelInviteAction(sender:)))
                self.navigationItem.rightBarButtonItems = [addButton]
            }
        }
        
        if self.scope == .reaction {
            let noun = (self.inputEmojiCount == 1) ? "person" : "people"
            self.navigationItem.title = "\(self.inputEmoji!)  \(self.inputEmojiCount!) \(noun) reacted with \(self.inputEmojiCode!)"
        }
        else {
            self.navigationItem.title = self.channel!.title!
        }
        
        let channelId = StateController.instance.channelId!
        var query = FireController.db.child("channel-members/\(channelId)")
        if self.scope == .reaction {
            query = FireController.db.child(self.inputReactionPath)
        }
        
        self.queryController = DataSourceController(name: "member_list")
        self.queryController.bind(to: self.tableView, query: query) { [weak self] scrollView, indexPath, data in
            
            let tableView = scrollView as! UITableView
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserListCell
            cell.reset()
            guard let this = self else { return cell }
            
            let snap = data as! DataSnapshot
            let userId = snap.key
            let channelId = StateController.instance.channelId!
            
            if this.scope == .reaction {
                cell.userQuery = UserQuery(userId: userId)
            }
            else {
                cell.userQuery = UserQuery(userId: userId, channelId: channelId)
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
                        if this.scope == .channel {
                            if let role = this.channel.role, role == "owner", userId != UserController.instance.userId {
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
        let controller = MemberViewController(userId: user?.id)
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
