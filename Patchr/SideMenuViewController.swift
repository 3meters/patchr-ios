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

    var ref: FIRDatabaseReference!
    var handle: UInt!
    var user: FireUser?

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.handle = self.ref.observe(.value, with: { snap in
            self.user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
            self.bind()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.ref.removeObserver(withHandle: self.handle)
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
        self.navigationController?.present(navController, animated: true, completion: nil)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("SideMenu")
        
        let userId = UserController.instance.fireUserId
        self.ref = FIRDatabase.database().reference().child("users/\(userId!)")

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
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Patch members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch patches", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if user != nil {
                let userId = UserController.instance.fireUserId
                self.ref = FIRDatabase.database().reference().child("users/\(userId!)")
                self.handle = self.ref.observe(.value, with: { snap in
                    self.user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
                    self.bind()
                })
            }
        }
    }
    
    func bind() {
        self.menuHeader.bind(user: user)
    }
}

extension SideMenuViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)

        if selectedCell == self.inviteCell {
            /* Do something! */
        }
        else if selectedCell == self.settingsCell {
            let controller = SettingsTableViewController()
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.cancelAction(sender:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            let navController = AirNavigationController()
            navController.viewControllers = [controller]
            UIViewController.topMostViewController()?.present(navController, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(64)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
}
