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

    var menuHeader: UserHeaderView!
    var inviteCell: WrapperTableViewCell?
    var membersCell: WrapperTableViewCell?
    var settingsCell: WrapperTableViewCell?
    var switchCell: WrapperTableViewCell?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        self.navigationController?.presentViewController(navController, animated: true, completion: nil)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("SideMenu")

        self.tableView = UITableView(frame: self.tableView.frame, style: .Plain)
        self.tableView.accessibilityIdentifier = Table.Settings
        self.tableView.rowHeight = 64
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.separatorStyle = .None
        
        self.menuHeader = UserHeaderView()
        let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SideMenuViewController.editProfileAction(_:)))
        self.menuHeader.userGroup.addGestureRecognizer(headerTapGestureRecognizer)
        self.menuHeader.frame = CGRectMake(0, 0, self.tableView.width(), CGFloat(208))
        self.menuHeader.setNeedsLayout()
        self.menuHeader.layoutIfNeeded()
        
        self.tableView.tableHeaderView = menuHeader	// Triggers table binding

        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsetsZero, reuseIdentifier: nil)
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Patch members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsetsZero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsetsZero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch patches", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsetsZero, reuseIdentifier: nil)
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if user != nil {
                self.bind(user!)
            }
        }
        
    }
    
    func bind(authUser: FIRUser) {
        let ref = FIRDatabase.database().reference()
        ref.child("users/\(authUser.uid)").observeEventType(.Value, withBlock: { snapshot in
            if let userMap = snapshot.value as? NSDictionary {
                let fireUser = FireUser.setPropertiesFromDictionary(userMap, onObject: FireUser(id: authUser.uid))
                self.menuHeader.bindToUser(fireUser)
                self.menuHeader.setNeedsLayout()
                self.menuHeader.layoutIfNeeded()
            }
        })
    }
}

extension SideMenuViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)

        if selectedCell == self.inviteCell {
            /* Do something! */
        }
        else if selectedCell == self.settingsCell {
            let controller = SettingsTableViewController()
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: controller, action: #selector(controller.cancelAction(_:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            UIViewController.topMostViewController()?.presentViewController(navController, animated: true, completion: nil)
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(64)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.membersCell!
        }
        else if indexPath.row == 1 {
            return self.settingsCell!
        }
        else if indexPath.row == 2 {
            return self.inviteCell!
        }
        return self.switchCell!
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
}