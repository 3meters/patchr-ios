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
    var userQuery: UserQuery?
 
    var menuHeader: UserHeaderView!
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
    
    deinit {
        self.userQuery?.remove()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.fillSuperview()
    }
    
    func editProfileAction(sender: AnyObject?) {
        let controller = ProfileEditViewController()
        let wrapper = AirNavigationController()
        wrapper.viewControllers = [controller]
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        slideMenuController()?.closeRight()
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
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        Reporting.screen("SideMenu")

        self.tableView = UITableView(frame: self.tableView.frame, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 60
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorStyle = .none
        
        self.menuHeader = UserHeaderView(frame: CGRect.zero)
        let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(editProfileAction(sender:)))
        self.menuHeader.addGestureRecognizer(headerTapGestureRecognizer)
        self.tableView.tableHeaderView = self.menuHeader	// Triggers table binding

        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Group members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite to group", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.profileCell = WrapperTableViewCell(view: MenuItemView(title: "Edit profile", image: UIImage(named: "imgEdit2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch groups", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.manageCell = WrapperTableViewCell(view: MenuItemView(title: "Manage group", image: UIImage(named: "imgGroupLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        self.tableView.tableFooterView = self.settingsCell
        
        self.view.addSubview(self.tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidUpdate), object: nil)
    }
    
    func bind() {
        if let userId = UserController.instance.userId {
            let groupId = StateController.instance.groupId!
            self.userQuery?.remove()
            self.userQuery = UserQuery(userId: userId, groupId: groupId)
            self.userQuery!.once(with: { [weak self] error, user in
                if let user = user {
                    self?.user = user
                    self?.menuHeader.bind(user: self?.user)
                    self?.tableView.tableHeaderView = self?.menuHeader
                    self?.tableView.reloadData()
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
                let controller = MemberListController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.scope = (role == "guest") ? .channel : .group
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
        }
        if selectedCell == self.inviteCell {
            let controller = InviteViewController()
            let wrapper = AirNavigationController(rootViewController: controller)
            controller.flow = .internalInvite
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        if selectedCell == self.profileCell {
            
            let controller = ProfileEditViewController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        if selectedCell == self.switchCell {
            
            let controller = GroupSwitcherController()
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        if selectedCell == self.manageCell {
            if StateController.instance.group?.role != "owner" {
                UIShared.toast(message: "Only group owners can manage groups")
            }
            else {
                let controller = GroupEditViewController()
                let wrapper = AirNavigationController(rootViewController: controller)
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
        }
        if selectedCell == self.settingsCell {
            
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
        return CGFloat(60)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.membersCell!
        }
        else if indexPath.row == 1 {
            return self.inviteCell!
        }
        else if indexPath.row == 2 {
            return self.profileCell!
        }
        else if indexPath.row == 3 {
            return self.switchCell!
        }
        else if indexPath.row == 4 {
            return self.manageCell!
        }
        else if indexPath.row == 5 {
            return self.settingsCell!
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
}
