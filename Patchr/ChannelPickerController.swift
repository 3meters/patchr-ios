//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import RxSwift

class ChannelPickerController: UIViewController, UITableViewDelegate {

    var groupRef: FIRDatabaseReference!
    var groupHandle: UInt!
    var channelsQuery: FIRDatabaseQuery!
    var group: FireGroup!
    
    var headerView: ChannelsHeaderView!
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FirebaseTableViewDataSource!
    var footerView = AirLinkButton()
    var hasFavorites = false

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bindGroup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 72)
        self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.tableView.alignBetweenTop(self.headerView, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    func switchAction(sender: AnyObject?) {
        let controller = GroupPickerController()
        controller.modalPresentationStyle = .overCurrentContext
        if let nav = self.slideMenuController()?.leftViewController as? UINavigationController {
           nav.present(controller, animated: true, completion: nil)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func groupDidChange(notification: NSNotification?) {
        bindGroup()
        if (self.slideMenuController()?.isLeftOpen())! && StateController.instance.channelId != nil {
            self.slideMenuController()?.closeLeft()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.view.backgroundColor = UIColor.white
        
        self.headerView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.headerView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        
        self.footerView.setImage(UIImage(named: "imgAddCircleLight"), for: .normal)
        self.footerView.imageView!.contentMode = .scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandOnLight
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidChange), object: nil)
    }
    
    func bindGroup() {
        
        let groupId = StateController.instance.groupId
        let userId = UserController.instance.userId
        
        if userId != nil && groupId != nil {
            
            self.groupRef = FIRDatabase.database().reference().child("groups/\(groupId!)")
            self.channelsQuery = FIRDatabase.database().reference().child("member-channels/\(userId!)/\(groupId!)").queryOrdered(byChild: "sort_priority")
            
            self.groupHandle = self.groupRef.observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                    self.bind()
                }
            })
        }
        else {
            self.tableView.dataSource = nil
            self.tableView.reloadData()
        }
    }
    
    func bind() {
        
        let groupId = StateController.instance.groupId
        
        self.headerView.bind(patch: self.group)
        
        self.tableView.dataSource = nil
        self.tableView.reloadData()
        
        self.tableViewDataSource = ChannelsDataSource(query: self.channelsQuery
            , nibNamed: "ChannelListCell"
            , cellReuseIdentifier: "ChannelViewCell"
            , view: self.tableView)
        
        self.tableViewDataSource.populateCell { (cell, data) in
            
            let snap = data as! FIRDataSnapshot
            let cell = cell as! ChannelListCell
            
            let channelId = snap.key
            let link = snap.value as! [String: Any]
            
            cell.backgroundColor = Colors.white
            cell.title?.textColor = Theme.colorText
            cell.lock?.tintColor = Colors.brandColorLight
            if channelId == StateController.instance.channelId {
                cell.backgroundColor = Colors.accentColorFill
                cell.title?.textColor = Colors.white
                cell.lock?.tintColor = Colors.white
            }
            let path = "group-channels/\(groupId!)/\(channelId)"
            let ref = FIRDatabase.database().reference().child(path)
            
            ref.observeSingleEvent(of: .value, with: { snap in
                if !(snap.value is NSNull) {
                    if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                        channel.membershipFrom(dict: link)
                        cell.bind(channel: channel)
                    }
                }
            })
        }
        
        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        StateController.instance.setChannelId(channelId: cell.channel.id)
        self.slideMenuController()?.closeLeft()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36
    }
}

extension ChannelPickerController {
    /* 
     * UITableViewDataSource 
     */
    class ChannelsDataSource: FirebaseTableViewDataSource {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "Channels"
        }
    }
}
