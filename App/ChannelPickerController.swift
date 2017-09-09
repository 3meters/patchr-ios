//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import FirebaseAuth
import pop
import PopupDialog

class ChannelPickerController: BaseTableController {
    
    weak var popup: PopupDialog?
    var selectedChannel: FireChannel?
    var titles: [String: String] = [:]

    fileprivate var baseView: PopupTableView {
        return self.view as! PopupTableView
    }
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    /* Replace the original controller view with our dedicated view */
    override func loadView() {
        self.view = PopupTableView(frame: .zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.baseView.titleLabel.text = "channel_picker_title".localized()
        
        self.baseView.searchBar.delegate = self
        
        self.baseView.tableView.register(UINib(nibName: "ChannelPickerCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.baseView.tableView.backgroundColor = Theme.colorBackgroundTable
        self.baseView.tableView.separatorInset = UIEdgeInsets.zero
        self.baseView.tableView.tableFooterView = UIView()
        self.baseView.tableView.delegate = self
    }
    
    func bind() {
        
        if let userId = UserController.instance.userId {
            
            let query = FireController.db.child("member-channels/\(userId)")
                .queryOrdered(byChild: "role")
                .queryStarting(atValue: "editor")
                .queryEnding(atValue: "owner")
            
            self.queryController = DataSourceController(name: "channel_picker")
            self.queryController.delegate = self
            self.queryController.matcher = { [weak self] searchText, data in
                guard let this = self else { return false }
                let snap = data as! DataSnapshot
                let key = snap.key
                let title = this.titles[key]! as String
                return title.lowercased().contains(searchText.lowercased())
            }

            self.queryController.bind(to: self.baseView.tableView, query: query) { [weak self] scrollView, indexPath, data in
                
                let tableView = scrollView as! UITableView
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChannelPickerCell
                cell.reset()    // Releases previous data observers
                
                guard self != nil else { return cell }
                
                if let snap = data as? DataSnapshot {
                    let channelId = snap.key
                    cell.channelQuery = ChannelQuery(channelId: channelId, userId: userId)    // Just channel lookup
                    cell.channelQuery!.observe(with: { [weak cell] error, channel in
                        guard let cell = cell else { return }
                        if channel != nil {
                            cell.bind(channel: channel!)
                        }
                    })
                }
                return cell
            }
            self.view.setNeedsLayout()
        }
    }
}

extension ChannelPickerController: FUICollectionDelegate {
    
    func arrayDidEndUpdates(_ collection: FUICollection) {
        self.titles.removeAll()
        for data in self.queryController.items {
            let snap = data as! DataSnapshot // Membership
            let channelId = snap.key
            let path = "channels/\(channelId)"
            FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                if let dict = snap.value as? [String: Any] {
                    let channel = FireChannel(dict: dict, id: snap.key)
                    self.titles[channel.id!] = channel.title!
                }
            })
        }
    }
}

extension ChannelPickerController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.queryController.filterActive = true
        searchBar.becomeFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.queryController.filter(searchText: searchText.isEmpty ? nil : searchText)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !(searchBar.text?.isEmpty)! {
            self.queryController.filter(searchText: nil)
        }
        searchBar.endEditing(true)
        self.queryController.filterActive = false
    }
}

extension ChannelPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ChannelPickerCell
        self.selectedChannel = cell.channel
        self.popup?.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
}
