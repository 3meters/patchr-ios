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

class ChannelSwitcherController: BaseTableController {
    
    var channelsQuery: FIRDatabaseQuery!
    var unreadsTotalQuery: UnreadQuery?
    var unreadsGroupQuery: UnreadQuery?
    var tableViewDataSource: FUITableViewDataSource!
    
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var searchBar: UISearchBar!
    var searchController: SearchController!
    var searchTableView = AirTableView(frame: CGRect.zero, style: .plain)
    var searchOn = false
    var rule = UIView()
    
    var gradientImage: UIImage!
    var backButton: UIBarButtonItem!
    var searchBarButton: UIBarButtonItem!
    var searchButton: UIBarButtonItem!
    var titleButton: UIBarButtonItem!
    
    var role = "guest"
    
    var unreadTotal = 0
    var unreadGroup = 0
    var unreadOther: Int? {
        didSet {
            if unreadOther != oldValue {
                updateBackButton()
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(self.gradientImage, for: .default)
        self.navigationController?.navigationBar.tintColor = Colors.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.searchTableView.fillSuperview()
        self.tableView.fillSuperview()
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
    *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        let groupId = StateController.instance.groupId!
        let controller = ChannelEditViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        controller.mode = .insert
        controller.inputGroupId = groupId
        self.slideMenuController()?.closeLeft()
        self.present(wrapper, animated: true, completion: nil)
    }

    func switchAction(sender: AnyObject?) {
        let _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func backAction(sender: AnyObject?) {
        let _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func searchAction(sender: AnyObject?) {
        search(on: true)
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/
    
    func userDidSwitch(notification: NSNotification?) {
        bind()
    }
    
    func groupDidSwitch(notification: NSNotification?) {
        bind()
    }
    
    func channelDidSwitch(notification: NSNotification?) {
        self.tableView.reloadData()
    }
    
    func leftDidClose(notification: NSNotification?) {
        if self.searchOn {
            self.search(on: false)
            self.searchBar?.setShowsCancelButton(false, animated: false)
            self.searchBar?.endEditing(true)
            self.searchController.channelsFiltered.removeAll()
            self.searchTableView.reloadData()
        }
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.rule.backgroundColor = Theme.colorSeparator
        
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 36
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: "channel-list-cell")
        
        self.searchBar = UISearchBar(frame: CGRect.zero)
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Search"
        self.searchBar.searchBarStyle = .prominent
        self.searchBar.autocapitalizationType = .none
        for subview in self.searchBar.subviews[0].subviews {
            if subview is UITextField {
                subview.tintColor = Colors.accentColor
            }
        }
        
        self.searchBarButton = UIBarButtonItem(customView: self.searchBar)
        self.searchController = SearchController(tableView: self.searchTableView)
        self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchAction(sender:)))
        
        self.searchTableView.alpha = 0.0
        self.searchTableView.backgroundColor = Theme.colorBackgroundTable
        self.searchTableView.tableFooterView = UIView()
        self.searchTableView.delegate = self
        self.searchTableView.dataSource = self.searchController
        self.searchTableView.separatorInset = UIEdgeInsets.zero
        self.searchTableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: "channel-search-cell")
        
        self.view.addSubview(self.searchTableView)
        self.view.addSubview(self.tableView)
        
        /* Navigation button */
        let unreadBackView = UnreadBackView()
        unreadBackView.buttonScrim.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        unreadBackView.frame = CGRect(x: 0, y: 0, width: 24, height: 36)
        unreadBackView.badge.alpha = CGFloat(0)
        
        self.backButton = UIBarButtonItem(customView: unreadBackView)
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: NAVIGATION_DRAWER_WIDTH, height: 64)
        gradient.colors = [Colors.accentColor.cgColor, Colors.brandColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.zPosition = 1
        gradient.shouldRasterize = true
        gradient.rasterizationScale = UIScreen.main.scale
        
        self.gradientImage = ImageUtils.imageFromLayer(layer: gradient)
        
        let titleWidth = (NAVIGATION_DRAWER_WIDTH - 112)
        let titleView = AirLabelDisplay(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 24))
        titleView.font = Theme.fontBarText
        self.titleButton = UIBarButtonItem(customView: titleView)
        
        self.navigationItem.leftBarButtonItem = self.titleButton
        self.navigationItem.rightBarButtonItems = [self.backButton, self.searchButton]
        self.navigationItem.hidesBackButton = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(channelDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(leftDidClose(notification:)), name: NSNotification.Name(rawValue: Events.LeftDidClose), object: nil)
    }
    
    func bind() {
        
        if let userId = UserController.instance.userId,
            let groupId = StateController.instance.groupId {
            FireController.db.child("member-groups/\(userId)/\(groupId)/role").observeSingleEvent(of: .value, with: { [weak self] snap in
                if let role = snap.value as? String {
                    self?.searchController.role = role
                    self?.searchController.load()
                    
                    if role == "guest" {
                        self?.navigationController?.setToolbarHidden(true, animated: true)
                        self?.toolbarItems = []
                    }
                    else {
                        self?.navigationController?.setToolbarHidden(false, animated: true)
                        let addButton = UIBarButtonItem(title: "New Channel", style: .plain, target: self, action: #selector(self?.addAction(sender:)))
                        self?.toolbarItems = [spacerFlex, addButton, spacerFlex]
                    }
                }
            })
            
            if self.titleButton != nil {
                FireController.db.child("groups/\(groupId)/title").observe(.value, with: { [weak self] snap in
                    if let title = snap.value as? String {
                        (self?.titleButton.customView as? UILabel)?.text = title
                    }
                })
            }
            
            if self.tableViewDataSource != nil {
                self.tableViewDataSource = nil
                self.tableView.reloadData()
            }
            
            self.unreadsTotalQuery?.remove()
            self.unreadsTotalQuery = UnreadQuery(level: .user, userId: userId)
            self.unreadsTotalQuery!.observe(with: { total in
                if total != self.unreadTotal {
                    self.unreadTotal = total
                    self.unreadOther = self.unreadTotal - self.unreadGroup
                }
            })
            
            self.unreadsGroupQuery?.remove()
            self.unreadsGroupQuery = UnreadQuery(level: .group, userId: userId, groupId: groupId)
            self.unreadsGroupQuery!.observe(with: { total in
                if total != self.unreadGroup {
                    self.unreadGroup = total
                    self.unreadOther = self.unreadTotal - self.unreadGroup
                }
            })
            
            self.channelsQuery = FireController.db.child("member-channels/\(userId)/\(groupId)")
                .queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.tableViewDataSource = FUITableViewDataSource(
                query: self.channelsQuery,
                view: self.tableView,
                populateCell: { [weak self] (tableView, indexPath, snap) -> UITableViewCell in
                    return (self?.populateCell(tableView, cellForRowAt: indexPath, snap: snap))!
            })
            
            self.tableView.dataSource = self.tableViewDataSource
            self.view.setNeedsLayout()
        }
    }
    
    func search(on: Bool) {
        self.searchOn = on
        if on {
            self.navigationItem.title = nil
            self.navigationItem.setLeftBarButton(self.searchBarButton, animated: true)
            self.navigationItem.setRightBarButtonItems(nil, animated: true)
            self.searchBar.frame = CGRect(x: 0, y: 0, width: (self.navigationController?.navigationBar.width())! - 32, height: 44)
            self.searchBar.becomeFirstResponder()
        }
        else {
            self.navigationItem.setLeftBarButton(self.titleButton, animated: true)
            self.navigationItem.setRightBarButtonItems([self.backButton, self.searchButton], animated: true)
            self.searchBar.resignFirstResponder()
        }
    }
    
    func updateBackButton() {
        let unreadOther = (self.unreadTotal - self.unreadGroup)
        if let backButtonView = self.backButton.customView as? UnreadBackView {
            backButtonView.badge.text = unreadOther > 0 ? "\(unreadOther)" : nil
            backButtonView.setNeedsLayout()
            backButtonView.layoutIfNeeded()
            if unreadOther > 0 {
                backButtonView.badge.fadeIn()
            }
            else {
                backButtonView.badge.fadeOut()
            }
            Log.d("ChannelPicker: Setting other groups unread to \(unreadOther)")
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func populateCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, snap: FIRDataSnapshot) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "channel-list-cell", for: indexPath) as! ChannelListCell
        
        cell.reset()    // Releases previous data observers
        
        let userId = UserController.instance.userId!
        let groupId = StateController.instance.groupId!
        let channelId = snap.key
        
        cell.query = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)    // Just channel lookup
        cell.query!.observe(with: { channel in
            
            if channel != nil {
                cell.selected(on: (channelId == StateController.instance.channelId), style: .prominent)
                cell.bind(channel: channel!)
                cell.unreadQuery = UnreadQuery(level: .channel, userId: userId, groupId: groupId, channelId: channelId)
                cell.unreadQuery!.observe(with: { total in
                    if total > 0 {
                        cell.badge?.text = "\(total)"
                        cell.badge?.isHidden = false
                        cell.accessoryType = .none
                    }
                    else {
                        cell.badge?.isHidden = true
                        cell.accessoryType = cell.selectedOn ? .checkmark : .none
                    }
                })
            }
            else {
                Log.w("Ouch! User is member of channel that does not exist")
            }
        })
        
        return cell
    }
}

extension ChannelSwitcherController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        let channelId = cell.channel.id!
        let groupId = cell.channel.group!
        self.slideMenuController()?.closeLeft()
        if let currentChannelId = StateController.instance.channelId {
            if channelId != currentChannelId {
                StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
                MainController.instance.showChannel(groupId: groupId, channelId: channelId)
            }
        }
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}

extension ChannelSwitcherController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar?.setShowsCancelButton(true, animated: true)
        self.tableView.fadeOut()
        self.searchTableView.fadeIn()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchController.filter(searchText: searchText)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar?.text = nil
        self.tableView.fadeIn()
        self.searchTableView.fadeOut()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        search(on: false)
        self.searchBar?.setShowsCancelButton(false, animated: true)
        self.searchBar?.endEditing(true)
        self.searchController.channelsFiltered.removeAll()
        self.searchTableView.reloadData()
    }
}

extension ChannelSwitcherController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        self.searchController.filter(searchText: self.searchBar!.text!)
    }
}

class SearchController: NSObject, UITableViewDataSource {
    
    var channelsSource = [FireChannel]()
    var channelsFiltered = [FireChannel]()
    var tableView: UITableView? = nil
    var role: String!
    
    init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    func filter(searchText: String, scope: String = "All") {
        self.channelsFiltered = channelsSource.filter { channel in
            return channel.name!.lowercased().contains(searchText.lowercased())
        }
        self.tableView?.reloadData()
    }
    
    func load() {
        
        self.channelsSource.removeAll()
        self.channelsFiltered.removeAll()
        
        let userId = UserController.instance.userId!
        let groupId = StateController.instance.groupId!

        let query = FireController.db.child("group-channels/\(groupId)")
            .queryOrdered(byChild: "name")
        
        query.observe(.value, with: { [weak self] snap in
            self?.channelsSource.removeAll()
            if !(snap.value is NSNull) && snap.hasChildren() {
                for item in snap.children {
                    let snapChannel = item as! FIRDataSnapshot
                    if let channel = FireChannel.from(dict: snapChannel.value as? [String: Any], id: snapChannel.key) {
                        let channelId = channel.id!
                        let path = "member-channels/\(userId)/\(groupId)/\(channelId)"
                        FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                            if !(snap.value is NSNull) {
                                /* Channels public or private the user is already a member of */
                                let link = snap.value as! [String: Any]
                                channel.membershipFrom(dict: link)
                                self?.channelsSource.append(channel) // Channels user is a member of
                            }
                            else {
                                /* Open channels user is not a member of and they are not a guest member */
                                if self?.role != "guest" && channel.visibility == "open" {
                                    self?.channelsSource.append(channel)
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channelsFiltered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channel-search-cell", for: indexPath) as! ChannelListCell
        let channel = self.channelsFiltered[indexPath.row]
        cell.reset()
        cell.bind(channel: channel)
        return cell
    }
}
