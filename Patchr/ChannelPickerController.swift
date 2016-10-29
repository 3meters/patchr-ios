//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseDatabaseUI
import RxSwift
import Material

class ChannelPickerController: UIViewController, UITableViewDelegate {

    let db = FIRDatabase.database().reference()
    var groupId: String!
    var headerView: ChannelsHeaderView!
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FirebaseTableViewDataSource!
    var footerView = AirLinkButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        guard self.groupId != nil else {
            fatalError("Channel picker cannot be launched without a groupId")
        }
        initialize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            self.groupId = groupId
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
        
        let userId = FIRAuth.auth()!.currentUser!.uid
        
        self.headerView.observe(groupId: self.groupId!)
        
        self.tableView.dataSource = nil
        self.tableView.reloadData()
        
        let path = "member-channels/\(userId)/\(self.groupId!)"
        let ref = self.db.child(path)
        
        self.tableViewDataSource = FirebaseTableViewDataSource(ref: ref
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
                cell.backgroundColor = Color.orange.lighten5
                //cell.title?.textColor = Colors.white
            }
            let path = "group-channels/\(self.groupId!)/\(channelId)"
            let ref = self.db.child(path)
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
