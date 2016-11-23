




//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class UserListController: BaseViewController, UITableViewDelegate {
    
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.fillSuperview()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func inviteAction(sender: AnyObject?) {
        UIShared.Toast(message: "Not implented yet.")
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
        
        let groupId = StateController.instance.groupId
        self.query = self.db.child("group-members/\(groupId!)").queryOrdered(byChild: "index_priority_joined_at_desc")
        
        self.view.backgroundColor = Theme.colorBackgroundForm
        
        self.cellReuseIdentifier = "user-cell"
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        
        let inviteButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(inviteAction(sender:)))
        self.navigationItem.rightBarButtonItems = [inviteButton]
        
        self.view.addSubview(self.tableView)
    }
    
    func bind() {
        
        let groupId = StateController.instance.groupId
        self.db.child("groups/\(groupId!)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                let group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                self.navigationItem.title = group?.title
            }
        })
        
        self.tableViewDataSource = FUITableViewDataSource(
            query: self.query,
            view: self.tableView,
            populateCell: { [weak self] (view, indexPath, snap) -> UserListCell in
                
                let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! UserListCell
                let userId = snap.key
                let link = snap.value as! [String: Any]
                
                self?.db.child("users/\(userId)").observeSingleEvent(of: .value, with: { snap in
                    if let user = FireUser.from(dict: snap.value as? [String: Any], id: snap.key) {
                        user.membershipFrom(dict: link)
                        cell.bind(user: user)
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
    
    enum Mode: Int {
        case drawer
        case fullscreen
    }
}

