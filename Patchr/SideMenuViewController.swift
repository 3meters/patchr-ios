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
    var group: FireGroup?
    
    var userQuery: UserQuery!
    var groupQuery: GroupQuery!
 
    var userHeader: UserMiniHeaderView!
    var groupHeader: GroupMiniHeaderView!
    
    var userCell: WrapperTableViewCell?
    var groupCell: WrapperTableViewCell?
    var inviteCell: WrapperTableViewCell?
    var membersCell: WrapperTableViewCell?
    var profileCell: WrapperTableViewCell?
    var switchCell: WrapperTableViewCell?
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
    
    func groupDidSwitch(notification: NSNotification) {
        bind()
    }
    
    func groupDidChange(notification: NSNotification) {
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
        self.groupHeader = GroupMiniHeaderView(frame: CGRect.zero)

        self.userCell = WrapperTableViewCell(view: self.userHeader, padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.groupCell = WrapperTableViewCell(view: self.groupHeader, padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.userCell?.separator.backgroundColor = Colors.brandColorLighter
        self.groupCell?.separator.backgroundColor = Colors.brandColorLighter
        
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Group members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite to group", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.profileCell = WrapperTableViewCell(view: MenuItemView(title: "Edit profile", image: UIImage(named: "imgEdit2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch groups", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.manageCell = WrapperTableViewCell(view: MenuItemView(title: "Manage group", image: UIImage(named: "imgGroupLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        self.view.addSubview(self.tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rightDidClose(notification:)), name: NSNotification.Name(rawValue: Events.RightDidClose), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rightWillOpen(notification:)), name: NSNotification.Name(rawValue: Events.RightWillOpen), object: nil)
    }
    
    func bind() {
        if let userId = UserController.instance.userId,
            let groupId = StateController.instance.groupId {
            self.userQuery?.remove()
            self.userQuery = UserQuery(userId: userId)
            self.userQuery.observe(with: { [weak self] error, user in
                guard let this = self else { return }
                if user != nil {
                    this.user = user
                    this.userHeader.bind(user: user)
                }
            })
            self.groupQuery?.remove()
            self.groupQuery = GroupQuery(groupId: groupId, userId: userId)
            self.groupQuery.once(with: { [weak self] error, trigger, group in
                guard let this = self else { return }
                if group != nil {
                    this.group = group
                    this.groupHeader.bind(group: group)
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
            
            if let role = StateController.instance.group.role {
                Reporting.track("view_group_members")
                let controller = MemberListController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.scope = (role == "guest") ? .channel : .group
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
        }
        if selectedCell == self.inviteCell {
            
            if StateController.instance.group?.role == "guest" {
                UIShared.toast(message: "Guests can\'t send group invites")
            }
            else {
                Reporting.track("invite_group_members")
                let controller = ContactPickerController()
                controller.flow = .none
                controller.inputRole = "members"
                controller.inputGroupId = StateController.instance.groupId!
                controller.inputGroupTitle = StateController.instance.group.title
                let wrapper = AirNavigationController(rootViewController: controller)
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
        }
        if selectedCell == self.profileCell {
            
            Reporting.track("view_profile_edit")
            let controller = ProfileEditViewController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        if selectedCell == self.switchCell {
            
            Reporting.track("view_group_switcher")
            let controller = GroupSwitcherController()
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        if selectedCell == self.manageCell {
            if StateController.instance.group?.role != "owner" {
                UIShared.toast(message: "Only group owners can manage groups")
            }
            else {
                Reporting.track("view_group_manager")
                let controller = GroupEditViewController()
                let wrapper = AirNavigationController(rootViewController: controller)
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
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
        if self.group?.role == "guest" {
            if indexPath.row == 2 || indexPath.row == 4 {
                return CGFloat(0)
            }
        }

        if self.group?.role != "owner" {
            if indexPath.row == 4 {
                return CGFloat(0)
            }
        }

        if indexPath.row == 0 {
            return CGFloat(96)
        }
        else if indexPath.row == 5 {
            return CGFloat(36)
        }
        else if indexPath.row == 6 {
            return CGFloat(72)
        }
        else {
            return CGFloat(56)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.groupCell!
        }
        else if indexPath.row == 1 {
            return self.membersCell!
        }
        else if indexPath.row == 2 {
            return self.inviteCell!
        }
        else if indexPath.row == 3 {
            return self.switchCell!
        }
        else if indexPath.row == 4 {
            return self.manageCell!
        }
        else if indexPath.row == 5 {
            let cell = UITableViewCell()
            cell.backgroundColor = Colors.gray95pcntColor
            return cell
        }
        else if indexPath.row == 6 {
            return self.userCell!
        }
        else if indexPath.row == 7 {
            return self.profileCell!
        }
        else if indexPath.row == 8 {
            return self.settingsCell!
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
}
