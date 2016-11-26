




//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class UserListController: BaseTableController, UITableViewDelegate {
    
    let db = FIRDatabase.database().reference()
    var query: FIRDatabaseQuery!
    
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
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
    
    func inviteAction(sender: AnyObject?) {
        let controller = InviteViewController()
        self.navigationController?.pushViewController(controller, animated: true)
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
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        if let role = StateController.instance.group.role {
            if role != "guest" {
                let groupId = StateController.instance.groupId
                self.query = self.db.child("group-members/\(groupId!)").queryOrdered(byChild: "index_priority_joined_at_desc")
            }
            else {
                let channelId = StateController.instance.channelId
                self.query = self.db.child("channel-members/\(channelId!)")
            }
        }
        
        self.cellReuseIdentifier = "user-cell"
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        
        if StateController.instance.group?.role == "owner" {
            let inviteButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(inviteAction(sender:)))
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [inviteButton]
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
        else {
            if self.presented {
                let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(self.closeAction(sender:)))
                self.navigationItem.rightBarButtonItems = [closeButton]
            }
        }
    }

    func bind() {
        
        let group = StateController.instance.group
        self.navigationItem.title = group!.title
        
        self.tableViewDataSource = FUITableViewDataSource(
            query: self.query,
            view: self.tableView,
            populateCell: { [weak self] (view, indexPath, snap) -> UserListCell in
                
                let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! UserListCell
                let userId = snap.key
                
                let userQuery = UserQuery(userId: userId, groupId: group!.id!)
                userQuery.once(with: { user in
                    if user != nil {
                        cell.bind(user: user!)
                        cell.manageButton?.data = user
                        cell.manageButton?.addTarget(self, action: #selector(self?.manageUserAction(sender:)), for: .touchUpInside)
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
}

