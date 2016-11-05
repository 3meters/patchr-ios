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
    var message = AirLabelTitle()
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FirebaseTableViewDataSource!
    var footerView = AirLinkButton()
    var rule = UIView()
    var mode: Mode = .drawer
    
    var isModal: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }

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
        
        if self.mode == .drawer {
            self.headerView.bounds.size.width = self.view.width()
            self.headerView.title?.sizeToFit()
            self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44 + (self.headerView.title?.height())!)
            self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
            self.tableView.alignBetweenTop(self.headerView, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
        }
        else {
            let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
            self.message.alignUnder(self.navigationController?.navigationBar, matchingCenterWithTopPadding: 0, width: 288, height: messageSize.height + 24)
            self.rule.alignUnder(self.message, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 1)
            self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
            self.tableView.alignBetweenTop(self.rule, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
        }
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
        if self.isModal {
            self.dismiss(animated: (self.mode == .drawer), completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        let userId = ZUserController.instance.fireUserId
        self.query = FIRDatabase.database().reference().child("member-groups/\(userId!)").queryOrdered(byChild: "sort_priority")

        self.view.backgroundColor = Theme.colorBackgroundForm
        self.rule.backgroundColor = Theme.colorSeparator

        if self.mode == .drawer {
            self.headerView = Bundle.main.loadNibNamed("GroupsHeaderView", owner: nil, options: nil)?.first as? GroupsHeaderView
            self.headerView.closeButton?.addTarget(self, action: #selector(closeAction(sender:)), for: .touchUpInside)
            self.view.addSubview(self.headerView)
        }
        else {
            self.message.textAlignment = NSTextAlignment.center
            self.message.numberOfLines = 0
            self.message.text = "Select from groups you are a member of. You can switch groups at anytime."
            self.view.addSubview(self.message)
            self.view.addSubview(self.rule)
        }
        
        self.footerView.setImage(UIImage(named: "imgAddCircleLight"), for: .normal)
        self.footerView.imageView!.contentMode = .scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandOnLight
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        
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
            if groupId == StateController.instance.groupId {
                cell.title?.textColor = Colors.accentColorTextLight
            }
            
            FIRDatabase.database().reference().child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                if let group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key) {
                    group.membershipFrom(dict: link)
                    cell.bind(group: group)
                }
            })
        }
        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        StateController.instance.setGroupId(groupId: cell.group.id)
        self.closeAction(sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    enum Mode: Int {
        case drawer
        case fullscreen
    }
}

