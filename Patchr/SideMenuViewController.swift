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

class SideMenuViewController: UITableViewController {

    var user: FireUser?
    var userQuery: UserQuery?
 
    var menuHeader: UserHeaderView!
    var inviteCell: WrapperTableViewCell?
    var membersCell: WrapperTableViewCell?
    var profileCell: WrapperTableViewCell?
    var switchCell: WrapperTableViewCell?
    var settingsCell: WrapperTableViewCell?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* In case the photo needs be retried */
        if self.user != nil {
            self.menuHeader.bind(user: self.user)
            self.tableView.tableHeaderView = self.menuHeader
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        self.userQuery?.remove()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.bounds.size.width = SIDE_MENU_WIDTH
    }
    
    func editProfileAction(sender: AnyObject?) {
        let controller = ProfileEditViewController()
        let wrapper = AirNavigationController()
        wrapper.viewControllers = [controller]
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
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

    func initialize() {

        Reporting.screen("SideMenu")

        self.tableView = UITableView(frame: self.tableView.frame, style: .plain)
        self.tableView.rowHeight = 64
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorStyle = .none
        
        self.menuHeader = UserHeaderView(frame: CGRect.zero)
        let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(editProfileAction(sender:)))
        self.menuHeader.addGestureRecognizer(headerTapGestureRecognizer)
        self.tableView.tableHeaderView = self.menuHeader	// Triggers table binding

        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Group members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.profileCell = WrapperTableViewCell(view: MenuItemView(title: "Edit profile", image: UIImage(named: "imgEdit2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch groups", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserStateDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidChange), object: nil)
    }
    
    func bind() {
        let userId = UserController.instance.userId
        let groupId = StateController.instance.groupId
        
        if userId != nil {
            self.userQuery?.remove()
            self.userQuery = UserQuery(userId: userId!, groupId: groupId)
            self.userQuery!.once(with: { [weak self] user in
                
                guard user != nil else {
                    return
                }
                
                let user = user!
                
                self?.user = user
                self?.menuHeader.bind(user: self?.user)
                self?.tableView.tableHeaderView = self?.menuHeader	// Triggers table binding
                self?.tableView.reloadData()
            })
        }
    }
}

extension SideMenuViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)

        if selectedCell == self.inviteCell {
            
            let controller = InviteViewController()
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        else if selectedCell == self.settingsCell {
            
            let controller = SettingsTableViewController()
            let wrapper = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        else if selectedCell == self.profileCell {
            
            let controller = ProfileEditViewController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        else if selectedCell == self.switchCell {
            
            let controller = GroupPickerController()
            let wrapper = AirNavigationController(rootViewController: controller)
            self.slideMenuController()?.mainViewController?.present(wrapper, animated: true, completion: nil)
        }
        else if selectedCell == self.membersCell {
            
            if let role = StateController.instance.group.role {
                let controller = MemberListController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.scope = (role == "guest") ? .channel : .group
                UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
            }
        }
        
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
        slideMenuController()?.closeRight()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if StateController.instance.group?.role != "owner" && indexPath.row == 1 {
            return CGFloat(0)
        }
        return CGFloat(64)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            return self.settingsCell!
        }
        return UITableViewCell()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}
