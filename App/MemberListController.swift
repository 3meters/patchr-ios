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
    var scope: ListScope = .channel
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
        let viewWidth = min(Config.contentWidthMax, self.view.width())
        self.tableView.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())
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
        if let button = sender as? AirButton {
            let controller = MemberSettingsController()
            let wrapper = AirNavigationController(rootViewController: controller)
            if let user = button.data as? FireUser {
                controller.inputUser = user
                controller.inputChannel = self.channel
            }
            else if let userId = button.data as? String {
                controller.inputUserId = userId
                controller.inputChannel = self.channel
            }
            self.present(wrapper, animated: true)
        }
    }
    
    func profileTapped(sender: AnyObject?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            Reporting.track("view_member_profile")
            let point = recognizer.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                self.tableView(self.tableView, didSelectRowAt: indexPath)
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
        
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        
        if self.presented || self.popupController != nil {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
    }

    func bind() {
        
        if (self.scope == .channel && isOwner()) {
            if self.scope != .reaction {
                let addButton = UIBarButtonItem(title: "invite".localized(), style: .plain, target: self, action: #selector(channelInviteAction(sender:)))
                self.navigationItem.rightBarButtonItems = [addButton]
            }
        }
        
        if self.scope == .reaction {
            let noun = (self.inputEmojiCount == 1) ? "person".localized() : "people".localized()
            self.navigationItem.title = "reaction_list_title".localizedFormat(self.inputEmoji!, String(self.inputEmojiCount!), noun, self.inputEmojiCode!)
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
            guard self != nil else { return cell }
            
            let snap = data as! DataSnapshot
            let userId = snap.key
            
            cell.userQuery = UserQuery(userId: userId, membership: snap.value as? [String : Any])
            cell.userQuery.once(with: { [weak self, weak cell] error, user in
                guard let this = self, let cell = cell else { return }
                if error != nil {
                    Log.w("Permission denied")
                    return
                }
                var target = "channel"
                if this.scope == .reaction {
                    target = "reaction"
                }
                cell.bind(user: user, target: target)
                let tap = UITapGestureRecognizer(target: this, action: #selector(this.profileTapped(sender:)))
                cell.profileView.addGestureRecognizer(tap)

                if this.manage {
                    if this.scope == .channel {
                        if this.isOwner() {
                            if this.channel.ownedBy! != userId {
                                cell.widgetWidth.constant = 40
                                cell.settingsButton?.isHidden = false
                                cell.settingsButton?.hitInsets = UIEdgeInsetsMake(-24, -24, -24, -24)
                                cell.settingsButton?.addTarget(this, action: #selector(this.manageUserAction(sender:)), for: .touchUpInside)
                                if user != nil {
                                    cell.settingsButton?.data = user
                                }
                                else {
                                    cell.settingsButton?.data = userId as AnyObject?
                                }
                            }
                        }
                    }
                }
            })
            return cell
        }
    }
    
    func isOwner() -> Bool {
        if let membership = self.channel.membership {
            return (membership.role == "owner" || self.channel.ownedBy == UserController.instance.userId)
        }
        return false
    }
    
    enum ListScope: Int {
        case channel
        case reaction
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
