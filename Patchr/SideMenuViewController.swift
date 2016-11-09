//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD
import PBWebViewController
import Firebase
import FirebaseAuth
import FirebaseDatabase

class SideMenuViewController: UITableViewController {

    let db = FIRDatabase.database().reference()
    var ref: FIRDatabaseReference!
    var handle: UInt!
    var user: FireUser?

    var menuHeader: UserHeaderView!
    var inviteCell: WrapperTableViewCell?
    var membersCell: WrapperTableViewCell?
    var profileCell: WrapperTableViewCell?
    var settingsCell: WrapperTableViewCell?
    var switchCell: WrapperTableViewCell?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        if UserController.instance.userId != nil {
            self.ref = self.db.child("users/\(UserController.instance.userId!)")
            self.handle = self.ref.observe(.value, with: { snap in
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                self.bind()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: controller, action: #selector(controller.cancelAction(sender:)))
        controller.navigationItem.rightBarButtonItems = [cancelButton]
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        UIViewController.topMostViewController()?.present(navController, animated: true, completion: nil)
    }
    
    func userStateDidChange(notification: NSNotification) {
        if UserController.instance.userId != nil {
            self.ref = self.db.child("users/\(UserController.instance.userId!)")
            self.handle = self.ref.observe(.value, with: { snap in
                self.user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key)
                self.bind()
            })
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("SideMenu")
        
        if UserController.instance.userId != nil {
            self.ref = self.db.child("users/\(UserController.instance.userId!)")
        }

        self.tableView = UITableView(frame: self.tableView.frame, style: .plain)
        self.tableView.rowHeight = 64
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorStyle = .none
        
        self.menuHeader = UserHeaderView()
        let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SideMenuViewController.editProfileAction(sender:)))
        self.menuHeader.userGroup.addGestureRecognizer(headerTapGestureRecognizer)
        self.menuHeader.frame = CGRect(x:0, y:0, width:self.tableView.width(), height:CGFloat(208))
        self.menuHeader.setNeedsLayout()
        self.menuHeader.layoutIfNeeded()
        
        self.tableView.tableHeaderView = menuHeader	// Triggers table binding

        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Group members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.profileCell = WrapperTableViewCell(view: MenuItemView(title: "Edit profile", image: UIImage(named: "imgEdit2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch groups", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserStateDidChange), object: nil)
    }
    
    func bind() {
        self.menuHeader.bind(user: self.user)
    }
}

extension SideMenuViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)

        if selectedCell == self.inviteCell {
            /* Show contact picker */
        }
        else if selectedCell == self.settingsCell {
            let controller = SettingsTableViewController()
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.cancelAction(sender:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(navController, animated: true, completion: nil)
        }
        else if selectedCell == self.profileCell {
            editProfileAction(sender: self)
        }
        else if selectedCell == self.switchCell {
            let controller = GroupPickerController()
            controller.mode = .fullscreen
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.closeAction(sender:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            let nav = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(nav, animated: true, completion: nil)
        }
        else if selectedCell == self.membersCell {
            let controller = UserListController()
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.closeAction(sender:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            let nav = AirNavigationController(rootViewController: controller)
            UIViewController.topMostViewController()?.present(nav, animated: true, completion: nil)
        }
        
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
        slideMenuController()?.closeRight()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
        else if indexPath.row == 4 {
            return self.settingsCell!
        }
        return self.switchCell!
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}
