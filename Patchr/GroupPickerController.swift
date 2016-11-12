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
    
    let db = FIRDatabase.database().reference()
    var query: FIRDatabaseQuery!
    
    var headerView: GroupsHeaderView!
    var message: String = "Select from groups you are a member of. You can switch groups at anytime."
    var messageLabel = AirLabelTitle()
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
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
            let messageSize = self.messageLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
            self.messageLabel.alignUnder(self.navigationController?.navigationBar, matchingCenterWithTopPadding: 0, width: 288, height: messageSize.height + 24)
            self.rule.alignUnder(self.messageLabel, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 1)
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
            self.dismiss(animated: true, completion: nil)
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
        
        self.view.backgroundColor = Theme.colorBackgroundForm
        self.rule.backgroundColor = Theme.colorSeparator
        
        if self.mode == .drawer {
            self.headerView = Bundle.main.loadNibNamed("GroupsHeaderView", owner: nil, options: nil)?.first as? GroupsHeaderView
            self.headerView.closeButton?.addTarget(self, action: #selector(closeAction(sender:)), for: .touchUpInside)
            self.view.addSubview(self.headerView)
        }
        else {
            self.messageLabel.textAlignment = NSTextAlignment.center
            self.messageLabel.numberOfLines = 0
            self.messageLabel.text = "Select from groups you are a member of. You can switch groups at anytime."
            self.view.addSubview(self.messageLabel)
            self.view.addSubview(self.rule)
        }
        
        self.footerView.setImage(UIImage(named: "imgAddCircleLight"), for: .normal)
        self.footerView.imageView!.contentMode = .scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandOnLight
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        
        self.cellReuseIdentifier = "group-cell"
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerView)
    }
    
    func bind() {
        
        if self.tableViewDataSource == nil {
            
            let userId = UserController.instance.userId
            self.query = self.db.child("member-groups/\(userId!)").queryOrdered(byChild: "sort_priority")
            
            self.tableViewDataSource = FUITableViewDataSource(
                query: self.query,
                view: self.tableView,
                populateCell: { [weak self] (view, indexPath, snap) -> GroupListCell in
                    
                    let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! GroupListCell
                    let groupId = snap.key
                    let link = snap.value as! [String: Any]
                    
                    cell.title?.textColor = Theme.colorText
                    if groupId == StateController.instance.groupId {
                        cell.title?.textColor = Colors.accentColorTextLight
                    }
                    
                    self?.db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                        if let group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key) {
                            group.membershipFrom(dict: link)
                            cell.bind(group: group)
                        }
                    })
                    
                    return cell
            })

            self.tableView.dataSource = self.tableViewDataSource
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        StateController.instance.setGroupId(groupId: cell.group.id)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    enum Mode: Int {
        case drawer
        case fullscreen
    }
}
