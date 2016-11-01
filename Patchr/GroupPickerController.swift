//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class GroupPickerController: UIViewController, UITableViewDelegate {
    
    var query: FIRDatabaseQuery!

    var headerView: GroupsHeaderView!
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FirebaseTableViewDataSource!
    var footerView = AirLinkButton()

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
        self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 72)
        self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.tableView.alignBetweenTop(self.headerView, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        let controller = PatchEditViewController()
        let navController = AirNavigationController()
        controller.inputState = .Creating
        controller.inputType = "group"
        navController.viewControllers = [controller]
        self.present(navController, animated: true, completion: nil)
    }
    
    func closeAction(sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        let userId = UserController.instance.fireUserId
        self.query = FIRDatabase.database().reference().child("member-groups/\(userId!)").queryOrdered(byChild: "sort_priority")
        
        self.view.backgroundColor = UIColor.clear
        self.view.isOpaque = false
        
        self.headerView = Bundle.main.loadNibNamed("GroupsHeaderView", owner: nil, options: nil)?.first as? GroupsHeaderView
        self.headerView.closeButton?.addTarget(self, action: #selector(GroupPickerController.closeAction(sender:)), for: .touchUpInside)
        
        self.footerView.setTitle("Create group", for: .normal)
        self.footerView.setImage(UIImage(named: "imgAddLight"), for: .normal)
        self.footerView.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandColorDark
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 24)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(GroupPickerController.addAction(sender:)), for: .touchUpInside)
        
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerView)
    }
    
    func bind() {
        
        self.tableViewDataSource = FirebaseTableViewDataSource(query: self.query, nibNamed: "GroupListCell", cellReuseIdentifier: "GroupListCell", view: self.tableView)
        self.tableViewDataSource.populateCell { (cell, data) in
            
            let snap = data as! FIRDataSnapshot
            let cell = cell as! GroupListCell
            
            let groupId = snap.key
            let link = snap.value as! [String: Any]
            
            cell.title?.textColor = Theme.colorText
            if groupId == MainController.instance.groupId {
                cell.title?.textColor = Colors.accentColorTextLight
            }
            
            FIRDatabase.database().reference().child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                if let group = FireGroup(dict: snap.value as! [String: Any], id: snap.key) {
                    group.membershipFrom(dict: link)
                    cell.bind(group: group)
                }
            })
        }
        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        MainController.instance.setGroupId(groupId: cell.group.id)
        self.slideMenuController()?.closeLeft()
        self.closeAction(sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
