//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import SlideMenuControllerSwift
import pop

class ChannelPickerController: BaseTableController, UITableViewDelegate, SlideMenuControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate {

    var groupQuery: GroupQuery!
    var channelsQuery: FIRDatabaseQuery!
    var group: FireGroup!
    
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var headerView: ChannelsHeaderView!
    var footerView = AirLinkButton()
    
    var searchDataSource: SearchDataSource!
    var searchTableView = AirTableView(frame: CGRect.zero, style: .plain)

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
        self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 116)
        self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.tableView.alignBetweenTop(self.headerView, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
        self.searchTableView.alignUnder(self.headerView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
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
        let wrapper = AirNavigationController(rootViewController: controller)
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
        slideMenuController()?.closeLeft()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.headerView.searchBar?.setShowsCancelButton(true, animated: true)
        self.tableView.fadeOut()
        self.searchTableView.fadeIn()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchDataSource.filter(searchText: searchText)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.tableView.fadeIn()
        self.searchTableView.fadeOut()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.headerView.searchBar?.setShowsCancelButton(false, animated: true)
        self.headerView.searchBar?.endEditing(true)
    }
    
    func leftDidClose() {
        self.headerView.searchBar?.setShowsCancelButton(false, animated: false)
        self.headerView.searchBar?.endEditing(true)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func groupDidChange(notification: NSNotification?) {
        bind()
        self.searchDataSource.load()
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
    
    override func initialize() {
        super.initialize()
        
        self.definesPresentationContext = true
        self.navigationController?.delegate = self
        self.view.backgroundColor = UIColor.white
        
        self.slideMenuController()?.delegate = self
        
        self.headerView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.headerView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        self.headerView.searchBar?.delegate = self
        self.headerView.searchBar?.placeholder = "Search channels"
        
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
        self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: "channel-cell")
        
        self.searchTableView.alpha = 0.0
        self.searchTableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.searchTableView.delegate = self
        self.searchTableView.separatorStyle = .none
        self.searchTableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: "channel-cell")
        self.searchDataSource = SearchDataSource()
        self.searchTableView.dataSource = self.searchDataSource
        self.searchDataSource.tableView = self.searchTableView
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.searchTableView)
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
                if group != nil {
                    self.group = group
                    self.headerView.bind(group: self.group)                    
                }
            })
            
            self.channelsQuery = FireController.db.child("member-channels/\(userId)/\(groupId)").queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.tableViewDataSource = FUITableViewDataSource(query: self.channelsQuery
                , view: self.tableView
                , populateCell: { tableView, indexPath, snap in
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "channel-cell", for: indexPath) as! ChannelListCell
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
    
    func loadOpenChannels() {
        self.searchDataSource.load()
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

extension ChannelPickerController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.searchDataSource.filter(searchText: self.headerView.searchBar!.text!)
    }
}

class SearchDataSource: NSObject, UITableViewDataSource {
    
    var channelsSource = [FireChannel]()
    var channelsFiltered = [FireChannel]()
    var tableView: UITableView? = nil
    
    func filter(searchText: String, scope: String = "All") {
        channelsFiltered = channelsSource.filter { channel in
            return channel.name!.lowercased().contains(searchText.lowercased())
        }
        self.tableView?.reloadData()
    }
    
    func load() {
        
        self.channelsSource.removeAll()
        self.channelsFiltered.removeAll()
        
        let userId = UserController.instance.userId!
        let groupId = StateController.instance.groupId!

        let query = FireController.db.child("group-channels/\(groupId)").queryOrdered(byChild: "name")
        
        query.observe(.childAdded, with: { snap in
            if !(snap.value is NSNull) {
                if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                    let path = "member-channels/\(userId)/\(groupId)/\(channel.id!)"
                    FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                        if !(snap.value is NSNull) {
                            let link = snap.value as! [String: Any]
                            channel.membershipFrom(dict: link)
                            self.channelsSource.append(channel) // Channels user is a member of
                        }
                        else {
                            /* Open channels user is not a member of and they are not a guest member */
                            if StateController.instance.group.role != "guest" && channel.visibility == "open" {
                                self.channelsSource.append(channel)
                            }
                        }
                    })
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channelsFiltered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channel-cell", for: indexPath) as! ChannelListCell
        let channel = self.channelsFiltered[indexPath.row]
        cell.reset()
        cell.bind(channel: channel)
        return cell
    }
}
