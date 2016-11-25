




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
        let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: controller, action: #selector(controller.closeAction(sender:)))
        controller.navigationItem.rightBarButtonItems = [closeButton]
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func closeAction(sender: AnyObject?) {
        close()
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
        
        if StateController.instance.group?.role == "admin" {
            let inviteButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(inviteAction(sender:)))
            self.navigationItem.rightBarButtonItems = [inviteButton]
        }
        
        self.view.addSubview(self.tableView)
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

