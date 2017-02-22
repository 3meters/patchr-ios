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
import CLTokenInputView

class ChannelPickerController: BaseTableController, CLTokenInputViewDelegate {
    
    var channelsSource = [FireChannel]()
    var channelsFiltered = [FireChannel]()
    var delegate: PickerDelegate?
    
    var channelsView: AirContactView!
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var doneButton: UIBarButtonItem!
    var selectedStyle: SelectedStyle = .prominent
    
    var channels: [String: Any] = [:]
    var inputGroupId: String?
    var inputGroupTitle: String?

    var filterText: String?
    var filterActive = false
    var allowMultiSelect = true
    var simplePicker = false
    
    var flow: Flow = .none
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !self.simplePicker {
            let _ = self.channelsView.beginEditing()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let navHeight = self.navigationController?.navigationBar.height() ?? 0
        let statusHeight = UIApplication.shared.statusBarFrame.size.height
        self.channelsView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: channelsView.height())
        self.tableView.alignUnder(self.channelsView, centeredFillingWidthAndHeightWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
    *--------------------------------------------------------------------------------------------*/
    
    func doneAction(sender: AnyObject?) {
        if isValid() {
            if self.simplePicker {
                self.delegate?.update(channels: self.channels)
                close()
                return
            }
            
            let controller = ContactPickerController()
            controller.role = "guests"
            controller.flow = self.flow
            controller.channels = self.channels
            controller.inputGroupId = self.inputGroupId
            controller.inputGroupTitle = self.inputGroupTitle
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func closeAction(sender: AnyObject?) {
        close()
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/
    
    func keyboardWillShow(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let value = info.value(forKey: UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize = value.cgRectValue.size
        
        let contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, keyboardSize.height, 0)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    func keyboardWillHide(notification: Notification) {
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0, 0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = Colors.white
        
        self.channelsView = AirContactView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.channelsView.placeholder.text = "Search"
        self.channelsView.placeholder.textColor = Theme.colorTextPlaceholder
        self.channelsView.placeholder.font = Theme.fontComment
        self.channelsView.backgroundColor = Colors.white
        self.channelsView.drawBottomBorder = true
        self.channelsView.delegate = self
        self.channelsView.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleWidth]

        self.tableView.register(UINib(nibName: "ChannelSearchCell", bundle: nil), forCellReuseIdentifier: "channel-search-cell")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 36
        self.tableView.separatorInset = UIEdgeInsets.zero
        
        self.view.addSubview(self.channelsView)
        self.view.addSubview(self.tableView)
        
        self.selectedStyle = .normal
        self.navigationItem.title = "Select channel(s) for guest"
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if self.simplePicker {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
            self.doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            self.doneButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        if self.channels.count > 0 {
            for (channelId, channelName) in self.channels {
                let token = CLToken(displayText: channelName as! String, context: channelId as NSObject)
                self.channelsView.add(token)
            }
        }
    }
    
    func bind() {
        
        self.channelsSource.removeAll()
        self.channelsFiltered.removeAll()
        
        let groupId = StateController.instance.groupId!
        
        let query = FireController.db.child("group-channels/\(groupId)")
            .queryOrdered(byChild: "name")
        
        query.observe(.value, with: { [weak self] snap in
            self?.channelsSource.removeAll()
            if !(snap.value is NSNull) && snap.hasChildren() {
                for item in snap.children {
                    let snapChannel = item as! FIRDataSnapshot
                    if let channel = FireChannel.from(dict: snapChannel.value as? [String: Any], id: snapChannel.key) {
                        self?.channelsSource.append(channel)
                    }
                }
            }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }, withCancel: { error in
            Log.w("Permission denied")
        })
    }
    
    func filter() {
        
        self.channelsFiltered.removeAll()
        for channel in self.channelsSource {
            let match = channel.name!.lowercased().contains(self.filterText!.lowercased())
            if match {
                self.channelsFiltered.append(channel)
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func isValid() -> Bool {
        
        if self.channels.count == 0 {
            alert(title: "Select a channel")
            return false
        }
        
        return true
    }
}

extension ChannelPickerController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channel-search-cell", for: indexPath) as! ChannelListCell
        let channel = self.filterActive ? self.channelsFiltered[indexPath.row] : self.channelsSource[indexPath.row]
        let channelId = channel.id!
        
        cell.selectionStyle = .none
        cell.reset()
        cell.selected(on: (self.channels[channelId] != nil), style: .normal)
        cell.bind(channel: channel)
        cell.status?.isHidden = true

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterActive ? self.channelsFiltered.count : self.channelsSource.count
    }
    
    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
}

extension ChannelPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? ChannelListCell {
            let channel = cell.channel!
            let channelId = channel.id!
            let channelName = channel.name!
            let included = (self.channels[channelId] != nil)
            let token = CLToken(displayText: channelName, context: channelId as NSObject?)
            if included {
                self.channelsView.remove(token)
                cell.selected(on: false, style: .normal)
            }
            else {
                self.channelsView.add(token)
                cell.selected(on: true, style: .normal)
            }
        }
    }
}

extension ChannelPickerController {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        self.filterActive = (text != nil && !text!.trimmingCharacters(in: .whitespaces).isEmpty)
        self.filterText = (text != nil) ? text!.trimmingCharacters(in: .whitespaces) : nil
        if filterActive {
            filter()
        }
        else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        self.doneButton.isEnabled = (self.channelsView.allTokens.count > 0)
        if let channelId = token.context as? String {
            self.channels[channelId] = token.displayText
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        self.doneButton.isEnabled = (self.channelsView.allTokens.count > 0)
        if let channelId = token.context as? String {
            self.channels.removeValue(forKey: channelId)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.channelsView.frame.size.height = height
            let navHeight = self.navigationController?.navigationBar.height() ?? 0
            let statusHeight = UIApplication.shared.statusBarFrame.size.height
            self.channelsView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: self.channelsView.height())
            self.tableView.alignUnder(self.channelsView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
        })
    }
    
    func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        Log.d("tokenForText")
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ChannelListCell {
            let channel = cell.channel!
            self.channels[channel.id!] = channel
            return CLToken(displayText: channel.name!, context: cell)
        }
        
        return nil
    }
    
    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        self.channelsView.editingEnd()
        self.tableView.reloadData()
    }
    
    func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        self.channelsView.editingBegin()
        self.tableView.reloadData()
    }
    
    func tokenInputViewShouldReturn(_ view: CLTokenInputView) -> Bool {
        Log.d("tokenInputViewShouldReturn")
        return true
    }
}
