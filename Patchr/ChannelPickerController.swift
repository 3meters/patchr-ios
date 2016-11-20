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
import SlideMenuControllerSwift
import pop

class ChannelPickerController: UIViewController, UITableViewDelegate, SlideMenuControllerDelegate, UINavigationControllerDelegate {

    var groupQuery: GroupQuery!
    var channelsQuery: FIRDatabaseQuery!
    var group: FireGroup!
    
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    var headerView: ChannelsHeaderView!
    var footerView = AirLinkButton()
    
    var hasFavorites = false

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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        
        let controller = ChannelEditViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        controller.mode = .insert
        controller.inputGroupId = self.group.id!
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
        slideMenuController()?.closeLeft()
    }
    
    func switchAction(sender: AnyObject?) {
        
        let controller = GroupPickerController()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.dismissAction(sender:)))
        let wrapper = AirNavigationController(rootViewController: controller)
        
        controller.navigationItem.rightBarButtonItems = [cancelButton]
        
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
        slideMenuController()?.closeLeft()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func groupDidChange(notification: NSNotification?) {
        bind()
    }
    
    func channelDidChange(notification: NSNotification?) {
        self.tableView.reloadData()
    }

    func channelDidSwitch(notification: NSNotification?) {
        bind()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.definesPresentationContext = true
        self.navigationController?.delegate = self
        self.view.backgroundColor = UIColor.white
        
        self.slideMenuController()?.delegate = self
        
        self.headerView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.headerView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        
        self.footerView.setImage(UIImage(named: "imgAddCircleLight"), for: .normal)
        self.footerView.imageView!.contentMode = .scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandOnLight
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        
        self.cellReuseIdentifier = "channel-cell"
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(channelDidChange(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(channelDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: nil)
    }
    
    func bind() {
        
        if self.tableViewDataSource != nil {
            self.tableView.dataSource = nil
            self.tableView.reloadData()
        }

        if let groupId = StateController.instance.groupId,
            let userId = UserController.instance.userId {
            
            self.groupQuery?.remove()
            self.groupQuery = GroupQuery(groupId: groupId, userId: userId)
            self.groupQuery!.observe(with: { group in
                self.group = group
                self.headerView.bind(group: self.group)
            })
            
            self.channelsQuery = FireController.db.child("member-channels/\(userId)/\(groupId)").queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.tableViewDataSource = ChannelsDataSource(query: self.channelsQuery
                , view: self.tableView
                , populateCell: { tableView, indexPath, snap in
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: (self.cellReuseIdentifier)!, for: indexPath) as! ChannelListCell
                    let channelId = snap.key
                    let link = snap.value as! [String: Any]
                    
                    cell.reset()
                    cell.backgroundColor = Colors.white
                    cell.title?.textColor = Theme.colorText
                    cell.lock?.tintColor = Colors.brandColorLight
                    cell.star?.tintColor = Colors.brandColorLight
                    cell.accessoryType = .none
                    
                    if channelId == StateController.instance.channelId {
                        cell.backgroundColor = Colors.accentColorFill
                        cell.title?.textColor = Colors.white
                        cell.lock?.tintColor = Colors.white
                        cell.star?.tintColor = Colors.white
                        cell.tintColor = Colors.white
                        cell.accessoryType = .checkmark
                    }
                    
                    let path = "group-channels/\(groupId)/\(channelId)"
                    FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                        if !(snap.value is NSNull) {
                            if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                                channel.membershipFrom(dict: link)
                                cell.bind(channel: channel)
                            }
                        }
                        else {
                            Log.w("Ouch! User is member of channel that does not exist")
                        }
                    })
                    
                    return cell
            })
            
            self.tableView.dataSource = self.tableViewDataSource
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        if let channelId = cell.channel.id {
            StateController.instance.setChannelId(channelId: channelId, next: nil) // We know it's good
            MainController.instance.showChannel(groupId: self.group.id!, channelId: channelId)
            self.slideMenuController()?.closeLeft()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36
    }
}

extension ChannelPickerController {
    /* 
     * UITableViewDataSource 
     */
    class ChannelsDataSource: FUITableViewDataSource {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "Channels"
        }
    }
}
