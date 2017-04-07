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

    var inputGroupId: String?
    var inputGroupTitle: String?

    var headingLabel	= AirLabelTitle()
    var tokenView: AirTokenView!
    var doneButton: UIBarButtonItem!

    var channels: [String: Any] = [:]
    var delegate: PickerDelegate?
    var selectedStyle: SelectedStyle = .prominent
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
            let _ = self.tokenView.beginEditing()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let headingSize = self.headingLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.headingLabel.anchorTopCenter(withTopPadding: 74, width: 288, height: headingSize.height)
        self.tokenView.alignUnder(self.headingLabel, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 16, height: tokenView.height())
        self.tableView.alignUnder(self.tokenView, centeredFillingWidthAndHeightWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
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
            controller.flow = self.flow
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
        
        self.headingLabel.text = "Select channels"
        self.headingLabel.textAlignment = NSTextAlignment.center
        self.headingLabel.numberOfLines = 0

        self.tokenView = AirTokenView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.tokenView.placeholder.text = "Search"
        self.tokenView.placeholder.textColor = Theme.colorTextPlaceholder
        self.tokenView.placeholder.font = Theme.fontComment
        self.tokenView.backgroundColor = Colors.white
        self.tokenView.drawBottomBorder = true
        self.tokenView.delegate = self
        self.tokenView.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleWidth]

        self.tableView.register(UINib(nibName: "ChannelSearchCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 36
        self.tableView.separatorInset = UIEdgeInsets.zero
        
        self.view.addSubview(self.headingLabel)
        self.view.addSubview(self.tokenView)
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
                self.tokenView.add(token)
            }
        }
    }
    
    func bind() {
        
        let groupId = StateController.instance.groupId!
        
        let query = FireController.db.child("group-channels/\(groupId)")
            .queryOrdered(byChild: "name")
        
        self.queryController = DataSourceController(name: "channel_picker")
        self.queryController.matcher = { searchText, data in
            let snap = data as! FIRDataSnapshot
            let dict = snap.value as! [String: Any]
            let name = dict["name"] as! String
            return name.lowercased().contains(searchText.lowercased())
        }
        
        self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChannelListCell
            if self != nil {
                let snap = data as! FIRDataSnapshot
                let channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key)
                let channelId = channel.id!
                cell.selectionStyle = .none
                cell.reset()
                cell.selected(on: (self!.channels[channelId] != nil), style: .normal)
                cell.bind(channel: channel)
                cell.status?.isHidden = true
            }
            return cell
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

extension ChannelPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? ChannelListCell {
            let channel = cell.channel!
            let channelId = channel.id!
            let channelName = channel.name!
            let included = (self.channels[channelId] != nil)
            let token = CLToken(displayText: channelName, context: channelId as NSObject?)
            if included {
                self.tokenView.remove(token)
                cell.selected(on: false, style: .normal)
            }
            else {
                self.tokenView.add(token)
                cell.selected(on: true, style: .normal)
            }
        }
    }
}

extension ChannelPickerController {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        if text != nil && !text!.trimmingCharacters(in: .whitespaces).isEmpty {
            let searchText = text!.trimmingCharacters(in: .whitespaces)
            self.queryController.filter(searchText: searchText)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        self.doneButton.isEnabled = (self.tokenView.allTokens.count > 0)
        if let channelId = token.context as? String {
            self.channels[channelId] = token.displayText
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        self.doneButton.isEnabled = (self.tokenView.allTokens.count > 0)
        if let channelId = token.context as? String {
            self.channels.removeValue(forKey: channelId)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.tokenView.frame.size.height = height
            let navHeight = self.navigationController?.navigationBar.height() ?? 0
            let statusHeight = UIApplication.shared.statusBarFrame.size.height
            self.tokenView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: self.tokenView.height())
            self.tableView.alignUnder(self.tokenView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
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
        self.tokenView.editingEnd()
        self.tableView.reloadData()
    }
    
    func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        self.tokenView.editingBegin()
        self.tableView.reloadData()
    }
    
    func tokenInputViewShouldReturn(_ view: CLTokenInputView) -> Bool {
        Log.d("tokenInputViewShouldReturn")
        return true
    }
}
