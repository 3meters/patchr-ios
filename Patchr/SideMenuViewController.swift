//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SlideMenuControllerSwift

class SideMenuViewController: BaseTableController, UITableViewDelegate, UITableViewDataSource {

    var user: FireUser?
    
    var userQuery: UserQuery!
    var channel: FireChannel?
    var channelQuery: ChannelQuery?
    var userHeader: UserMiniHeaderView!
    var channelHeader: MiniHeaderView!
    
    var userCell: WrapperTableViewCell?
    var channelCell: WrapperTableViewCell?
    var inviteCell: WrapperTableViewCell?
    var membersCell: WrapperTableViewCell?
    var profileCell: WrapperTableViewCell?
    var manageCell: WrapperTableViewCell?
    var settingsCell: WrapperTableViewCell?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.fillSuperview()
    }
    
    func userStateDidChange(notification: NSNotification) {
        bind()
    }
    
    func channelDidChange(notification: NSNotification) {
        bind()
    }
    
    func rightWillOpen(notification: NSNotification?) {
        Reporting.track("view_sidemenu")
    }
    
    func rightDidClose(notification: NSNotification?) {}

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.tableView = UITableView(frame: self.tableView.frame, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 60
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorStyle = .none
        
        self.userHeader = UserMiniHeaderView(frame: CGRect.zero)
        self.channelHeader = MiniHeaderView(frame: CGRect.zero)

        self.userCell = WrapperTableViewCell(view: self.userHeader, padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.channelCell = WrapperTableViewCell(view: self.channelHeader, padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.userCell?.separator.backgroundColor = Colors.brandColorLighter
        self.channelCell?.separator.backgroundColor = Colors.brandColorLighter
        
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.manageCell = WrapperTableViewCell(view: MenuItemView(title: "Manage", image: UIImage(named: "imgGroupLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.profileCell = WrapperTableViewCell(view: MenuItemView(title: "Edit profile", image: UIImage(named: "imgEdit2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        self.view.addSubview(self.tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(channelDidChange(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rightDidClose(notification:)), name: NSNotification.Name(rawValue: Events.RightDidClose), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rightWillOpen(notification:)), name: NSNotification.Name(rawValue: Events.RightWillOpen), object: nil)
    }
    
    func bind() {
        if let userId = UserController.instance.userId,
            let channelId = StateController.instance.channelId {
            self.userQuery?.remove()
            self.userQuery = UserQuery(userId: userId)
            self.userQuery.observe(with: { [weak self] error, user in
                guard let this = self else { return }
                if user != nil {
                    this.user = user
                    this.userHeader.bind(user: user)
                }
            })
            self.channelQuery?.remove()
            self.channelQuery = ChannelQuery(channelId: channelId, userId: userId)
            self.channelQuery?.once(with: { [weak self] error, channel in
                guard let this = self else { return }
                if channel != nil {
                    this.channel = channel
                    this.channelHeader.bind(channel: channel)
                    this.tableView.reloadData()
                }
            })
        }
    }
}

extension SideMenuViewController {
    /*
    * UITableViewDelegate
    */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)

        if selectedCell == self.membersCell {
            Reporting.track("view_channel_members")
            let controller = MemberListController()
            let wrapper = AirNavigationController(rootViewController: controller)
            controller.scope = .channel
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        
        if selectedCell == self.inviteCell {
            Reporting.track("invite_channel_members")
            let controller = ContactPickerController()
            controller.flow = .none
            controller.inputRole = "members"
            controller.inputChannelId = self.channel?.id!
            controller.inputChannelTitle = self.channel?.title
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        
        if selectedCell == self.manageCell {
            Reporting.track("view_channel_manager")
            let controller = ChannelEditViewController()
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        
        if selectedCell == self.profileCell {
            Reporting.track("view_profile_edit")
            let controller = ProfileEditViewController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        
        if selectedCell == self.settingsCell {
            Reporting.track("view_user_settings")
            let controller = SettingsTableViewController()
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        
        slideMenuController()?.closeRight()
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.channel?.role != "owner" {
            if indexPath.row == 2 || indexPath.row == 3 {
                return CGFloat(0)
            }
        }
        if indexPath.row == 0 {
            return CGFloat(96)
        }
        else if indexPath.row == 4 {
            return CGFloat(36)
        }
        else if indexPath.row == 5 {
            return CGFloat(72)
        }
        else {
            return CGFloat(56)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.channelCell!
        }
        else if indexPath.row == 1 {
            return self.membersCell!
        }
        else if indexPath.row == 2 {
            return self.inviteCell!
        }
        else if indexPath.row == 3 {
            return self.manageCell!
        }
        else if indexPath.row == 4 {
            let cell = UITableViewCell()
            cell.backgroundColor = Colors.gray95pcntColor
            return cell
        }
        else if indexPath.row == 5 {
            return self.userCell!
        }
        else if indexPath.row == 6 {
            return self.profileCell!
        }
        else if indexPath.row == 7 {
            return self.settingsCell!
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
}
