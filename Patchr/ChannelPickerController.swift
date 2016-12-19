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

class ChannelPickerController: BaseTableController {

    var groupsQuery: FIRDatabaseQuery!
    var groupsArray: FireArray!
    
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var headerView: NavigationHeaderView!
    
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
        self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 105)
        self.tableView.alignUnder(self.headerView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        
        let controller = ChannelEditViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        controller.mode = .insert
        controller.inputGroupId = StateController.instance.groupId
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        slideMenuController()?.closeLeft()
    }
    
    func segmentAction(sender: AnyObject?) {        
        Log.d("Selected segment: \(self.headerView.segments?.selectedSegmentIndex)")
    }
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func channelDidSwitch(notification: NSNotification?) {  // Switch current channel
        
        if let fromGroupId = notification?.userInfo?["fromGroupId"] as? String,
            let toGroupId = notification?.userInfo?["toGroupId"] as? String {
            
            var indexes = IndexSet()
            if let fromIndex = indexForGroup(groupId: fromGroupId) {
                indexes.insert(fromIndex)
            }
            if let toIndex = indexForGroup(groupId: toGroupId) {
                indexes.insert(toIndex)
            }
            self.tableView.beginUpdates()
            self.tableView.reloadSections(indexes, with: .automatic)
            self.tableView.endUpdates()
        }
    }
    
    func unreadChange(notification: NSNotification?) {
        
        if let groupId = notification?.userInfo?["groupId"] as? String,
            let channelId = notification?.userInfo?["channelId"] as? String {
            if let index = indexForGroup(groupId: groupId) {
                let indexPath = indexPathForChannel(groupId: groupId, channelId: channelId)
                self.tableView.beginUpdates()
                self.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                self.tableView.reloadRows(at: [indexPath!], with: .automatic)
                self.tableView.endUpdates()
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.definesPresentationContext = true
        self.view.backgroundColor = UIColor.white
        
        self.slideMenuController()?.delegate = self
        
        self.headerView = Bundle.main.loadNibNamed("NavigationHeaderView", owner: nil, options: nil)?.first as? NavigationHeaderView
        self.headerView.segments?.addTarget(self, action: #selector(segmentAction(sender:)), for: .valueChanged)
        self.headerView.addButton.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.estimatedRowHeight = 36
        self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: "channel-list-cell")
        self.tableView.register(UINib(nibName: "GroupSectionView", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(unreadChange(notification:)), name: NSNotification.Name(rawValue: Events.UnreadChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(channelDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: nil)
    }
    
    func bind() {
        
        if let userId = UserController.instance.userId {
            
            if self.tableView.dataSource != nil {
                self.tableView.dataSource = nil
                self.tableView.reloadData()
            }
            
            self.groupsQuery = FireController.db.child("member-channels/\(userId)").queryOrderedByKey()
            self.groupsArray = FireArray(query: self.groupsQuery, delegate: self)
            self.tableView.dataSource = self
        }
    }
    
    func indexPathForChannel(groupId: String, channelId: String) -> IndexPath? {
        if let groupIndex = indexForGroup(groupId: groupId) {
            let fromSnap = self.groupsArray.items[Int(groupIndex)] as! FIRDataSnapshot
            var channelIndex = 0
            for child in fromSnap.children.allObjects as! [FIRDataSnapshot] {
                if child.key == channelId {
                    return IndexPath(row: channelIndex, section: groupIndex)
                }
                channelIndex += 1
            }
        }
        return nil
    }
    
    func indexPathsForGroup(groupId: String) -> [IndexPath]? {
        if let groupIndex = indexForGroup(groupId: groupId) {
            var indexPaths: [IndexPath] = []
            let fromSnap = self.groupsArray.items[Int(groupIndex)] as! FIRDataSnapshot
            var channelIndex = 0
            for _ in fromSnap.children.allObjects as! [FIRDataSnapshot] {
                indexPaths.append(IndexPath(row: channelIndex, section: groupIndex))
                channelIndex += 1
            }
            return indexPaths
        }
        return nil
    }
    
    func indexForGroup(groupId: String) -> Int? {
        var index = 0
        for snap in self.groupsArray.items as! [FIRDataSnapshot] {
            if snap.key == groupId {
                return index
            }
            index += 1
        }
        return nil
    }
    
    func groupIdForIndex(index: UInt) -> String? {
        if self.groupsArray.count > 0 {
            if let groupSnap = self.groupsArray.items[Int(index)] as? FIRDataSnapshot {
                return groupSnap.key
            }
        }
        return nil
    }
}

extension ChannelPickerController: SectionToggledDelegate {
    
    func toggled(expanded: Bool, target: UIView) {
        
        if let sectionView = target as? GroupSectionView {
            
            let groupId = sectionView.group.id!
            var groupSettings: [String: Any] = (UserDefaults.standard.dictionary(forKey: groupId) ?? [:])!
            
            groupSettings["expanded"] = expanded
            UserDefaults.standard.set(groupSettings, forKey: groupId)
            
            self.tableView.beginUpdates()
            self.tableView.reloadSections(IndexSet(integer: sectionView.section), with: .none)
            self.tableView.endUpdates()
        }
    }
}

extension ChannelPickerController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        Log.d("Get cell for: \(indexPath.row)")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "channel-list-cell", for: indexPath) as! ChannelListCell
        let groupSnap = self.groupsArray.items[indexPath.section] as! FIRDataSnapshot
        let maps = self.groupsArray.children[indexPath.section]!
        let link = maps[indexPath.row]
        let groupId = groupSnap.key
        let channelId = link["key"] as! String
        
        cell.reset()
        
        if let count = NotificationController.instance.channelBadgeCounts[channelId], count > 0 {
            cell.badge?.text = "\(count)"
            cell.badge?.isHidden = false
        }
        
        if channelId == StateController.instance.channelId {
            cell.selected(on: true)
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
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let groupId = groupIdForIndex(index: UInt(section)) {
            if let groupSettings = UserDefaults.standard.dictionary(forKey: groupId) {
                let expanded = groupSettings["expanded"] as! Bool? ?? false
                if expanded {
                    let snap = self.groupsArray.items[section] as! FIRDataSnapshot
                    Log.d("Rows in section \(section): \(snap.childrenCount)")
                    return Int(snap.childrenCount)
                }
            }
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Log.d("Number of sections: \(self.groupsArray.count)")
        return Int(self.groupsArray.count)
    }
}

extension ChannelPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? GroupSectionView {
            headerView.groupQuery.remove()
            headerView.delegate = nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if self.groupsArray.count == 0 { return nil }
        
        Log.d("Get section header for: \(section)")
        
        if let groupSnap = self.groupsArray.items[section] as? FIRDataSnapshot {
            
            let groupId = groupSnap.key
            let userId = UserController.instance.userId
            
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! GroupSectionView
            headerView.reset()  // Clears badging
            headerView.setExpanded(expanded: false)
            headerView.section = section
            headerView.delegate = self
            
            headerView.groupQuery = GroupQuery(groupId: groupId, userId: userId!)
            headerView.groupQuery!.observe(with: { group in
                if group != nil {
                    headerView.bind(group: group!)
                }
            })
            
            headerView.badge?.isHidden = true
            if let count = NotificationController.instance.groupBadgeCounts[groupId], count > 0 {
                headerView.badge?.text = "\(count)"
                headerView.badge?.isHidden = false
            }
            
            if let groupSettings = UserDefaults.standard.dictionary(forKey: groupId) {
                let expanded = groupSettings["expanded"] as! Bool? ?? false
                headerView.setExpanded(expanded: expanded)
            }
            
            return headerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
        footer.backgroundColor = Colors.white
        return footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        if let channelId = cell.channel.id, let groupId = cell.channel.group {
            if groupId != StateController.instance.groupId {
                StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
            }
            else {
                StateController.instance.setChannelId(channelId: channelId, groupId: groupId, next: nil) // We know it's good
            }
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
            self.slideMenuController()?.closeLeft()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if let groupId = groupIdForIndex(index: UInt(indexPath.section)) {
            if let groupSettings = UserDefaults.standard.dictionary(forKey: groupId) {
                let expanded = groupSettings["expanded"] as! Bool? ?? false
                if expanded {
                    return 36
                }
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let groupId = groupIdForIndex(index: UInt(section)) {
            if let groupSettings = UserDefaults.standard.dictionary(forKey: groupId) {
                let expanded = groupSettings["expanded"] as! Bool? ?? false
                if expanded {
                    return 4
                }
            }
        }
        return 0
    }
}

extension ChannelPickerController: FUIArrayDelegate {
    
    func array(_ array: FUIArray!, didAdd object: Any!, at index: UInt) {
        Log.d("FireArray: didAdd: \(index)")
        if self.groupsArray.count > 0 {
            
            if let groupSnap = object as? FIRDataSnapshot {
                var maps = [[String: Any]]()
                for snap in groupSnap.children.allObjects as! [FIRDataSnapshot] {
                    var map = snap.value as! [String: Any]
                    map["key"] = snap.key
                    maps.append(map)
                }
                
                maps.sort {
                    ($0["index_priority_joined_at_desc"] as? Int)! < ($1["index_priority_joined_at_desc"] as? Int)!
                }
                
                self.groupsArray.children[Int(index)] = maps
            }

            self.tableView.beginUpdates()
            self.tableView.insertSections([Int(index)], with: .automatic)
            self.tableView.endUpdates()
        }
    }
    
    func array(_ array: FUIArray!, didChange object: Any!, at index: UInt) {
        Log.d("FireArray: didChange: \(index)")
        
        if let groupSnap = object as? FIRDataSnapshot {
            var maps = [[String: Any]]()
            for snap in groupSnap.children.allObjects as! [FIRDataSnapshot] {
                var map = snap.value as! [String: Any]
                map["key"] = snap.key
                maps.append(map)
            }
            
            maps.sort {
                ($0["index_priority_joined_at_desc"] as? Int)! < ($1["index_priority_joined_at_desc"] as? Int)!
            }
            
            self.groupsArray.children[Int(index)] = maps
        }
        
        self.tableView.beginUpdates()
        self.tableView.reloadSections([Int(index)], with: .automatic)
        self.tableView.endUpdates()
    }
    
    func array(_ array: FUIArray!, didRemove object: Any!, at index: UInt) {
        Log.d("FireArray: didRemove: \(index)")
        self.tableView.beginUpdates()
        self.tableView.deleteSections([Int(index)], with: .automatic)
        self.tableView.endUpdates()
    }
    
    func array(_ array: FUIArray!, didMove object: Any!, from fromIndex: UInt, to toIndex: UInt) {
        Log.d("FireArray: didMove from: \(fromIndex), to: \(toIndex)")
        self.tableView.beginUpdates()
        self.tableView.moveSection(Int(fromIndex), toSection: Int(toIndex))
        self.tableView.endUpdates()
    }
}

extension ChannelPickerController: SlideMenuControllerDelegate {
    
    func leftDidClose() {
        self.headerView.searchBar?.setShowsCancelButton(false, animated: false)
        self.headerView.searchBar?.endEditing(true)
    }
}
