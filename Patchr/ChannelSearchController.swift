//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import pop

class ChannelSearchController: BaseTableController, UITableViewDelegate, UITableViewDataSource {

    var channelsQuery: FIRDatabaseQuery!
    var channelsSource: [FireChannel]!
    var channelsFiltered: [FireChannel]!
    
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    var headerView: ChannelsHeaderView!

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
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.definesPresentationContext = true
        self.view.backgroundColor = UIColor.white
        
        self.headerView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.headerView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        
        self.cellReuseIdentifier = "channel-cell"
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
    }
    
    func bind() {
        
        let groupId = StateController.instance.groupId
        let userId = UserController.instance.userId
            
        self.channelsQuery = FireController.db.child("member-channels/\(userId)/\(groupId)").queryOrdered(byChild: "index_priority_joined_at_desc")
        
        self.tableViewDataSource = FUITableViewDataSource(query: self.channelsQuery
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        if let channelId = cell.channel.id {
            let groupId = StateController.instance.groupId
            StateController.instance.setChannelId(channelId: channelId, next: nil) // We know it's good
            MainController.instance.showChannel(groupId: groupId!, channelId: channelId)
            self.slideMenuController()?.closeLeft()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36
    }
    
    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channelsFiltered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: (self.cellReuseIdentifier)!, for: indexPath) as! ChannelListCell
        let channel = self.channelsFiltered[indexPath.row]
        let channelId = channel.id
        let groupId = StateController.instance.groupId
        
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
        
        let path = "group-channels/\(groupId!)/\(channelId)"
        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                    cell.bind(channel: channel)
                }
            }
            else {
                Log.w("Ouch! User is member of channel that does not exist")
            }
        })
        
        return cell
    }
}
