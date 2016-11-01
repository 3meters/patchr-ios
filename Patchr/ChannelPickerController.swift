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

    var inputGroupId: String!
    
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
        guard self.inputGroupId != nil else {
            fatalError("Channel picker cannot be launched without a groupId")
        }
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.groupHandle = self.groupRef.observe(.value, with: { snap in
            if snap.value is NSNull {
                Log.w("Group snapshot is null")
                return
            }
            self.group = FireGroup(dict: snap.value as! [String: Any], id: snap.key)
            self.bind()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.groupRef.removeObserver(withHandle: self.groupHandle)
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

    func groupChanged(notification: NSNotification) {
        let groupId = notification.userInfo?["groupId"] as? String
        if groupId != nil {
            self.inputGroupId = groupId
            let userId = UserController.instance.fireUserId
            self.groupRef = FIRDatabase.database().reference().child("groups/\(self.inputGroupId!)")
            self.channelsQuery = FIRDatabase.database().reference().child("member-channels/\(userId!)/\(self.inputGroupId!)").queryOrdered(byChild: "sort_priority")
            bind()
        }
        else {
            self.tableView.dataSource = nil
            self.tableView.reloadData()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.view.backgroundColor = UIColor.white
        
        let userId = UserController.instance.fireUserId
        self.groupRef = FIRDatabase.database().reference().child("groups/\(self.inputGroupId!)")
        self.channelsQuery = FIRDatabase.database().reference().child("member-channels/\(userId!)/\(self.inputGroupId!)").queryOrdered(byChild: "sort_priority")
        
        self.headerView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.headerView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        
        self.footerView.setTitle("Add channel", for: .normal)
        self.footerView.setImage(UIImage(named: "imgAddLight"), for: .normal)
        self.footerView.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandColorDark
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 24)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(ChannelPickerController.addAction(sender:)), for: .touchUpInside)
        
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChannelPickerController.groupChanged(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidChange), object: nil)
    }
    
    func bind() {
        
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
            if channelId == MainController.instance.channelId {
                cell.backgroundColor = MaterialColor.orange.lighten5
            }
            let path = "group-channels/\(self.inputGroupId!)/\(channelId)"
            let ref = FIRDatabase.database().reference().child(path)
            ref.observeSingleEvent(of: .value, with: { snap in
                if let channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key) {
                    channel.membershipFrom(dict: link)
                    cell.bind(channel: channel)
                }
            })
        }
        
        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        MainController.instance.setChannelId(channelId: cell.channel.id)
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
