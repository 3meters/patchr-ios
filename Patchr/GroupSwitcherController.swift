//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class GroupSwitcherController: BaseTableController {
    
    var groupsQuery: FIRDatabaseQuery!
    var tableViewDataSource: FUITableViewDataSource!
    let cellReuseIdentifier = "group-cell"
    
    var gradientImage: UIImage!
    var messageLabel = AirLabelTitle()
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var rule = UIView()
    var buttonLogin	= AirButton()
    var buttonSignup = AirButton()
    var buttonGroup	= UIView()
    var titleView: UIBarButtonItem!
    
    var message: String = "Select from groups you are a member of. You can switch groups at anytime."

    var groupAvailable = false
    var simplePicker = false
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    public convenience init(simplePicker: Bool = false) {
        self.init(nibName: nil, bundle: nil)
        self.simplePicker = simplePicker
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.simplePicker {
            self.navigationController?.navigationBar.setBackgroundImage(self.gradientImage, for: .default)
            self.navigationController?.navigationBar.tintColor = Colors.white
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.simplePicker {
            self.view.anchorTopCenter(withTopPadding: 74, width: Config.navigationDrawerWidth, height: self.view.height())
            self.tableView.fillSuperview()
            return
        }
        
        let messageSize = self.messageLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
        self.messageLabel.anchorTopCenter(withTopPadding: 64, width: 288, height:  messageSize.height + 24)
        self.rule.alignUnder(self.messageLabel, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 1)
        
        if self.groupAvailable {
            self.tableView.alignUnder(self.rule, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
        }
        else {
            self.buttonGroup.anchorInCenter(withWidth: 240, height: 96)
            self.buttonSignup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
            self.buttonLogin.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        
        FireController.instance.isConnected() { connected in
            if connected == nil || !connected! {
                let message = "Creating a group requires a network connection."
                self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
            }
            else {
                let controller = GroupCreateController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.flow = .internalCreate
                self.slideMenuController()?.closeLeft()
                self.present(wrapper, animated: true, completion: nil)
            }
        }
    }
    
    func closeAction(sender: AnyObject?) {
        close(animated: true)
    }
    
    func switchLoginAction(sender: AnyObject?) {
        let controller = EmailViewController()
        controller.flow = .onboardLogin
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func logoutAction(sender: AnyObject?) {
        UserController.instance.logout()
        close(animated: true)
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    func userDidSwitch(notification: NSNotification?) {
        bind()
    }
    
    func groupDidSwitch(notification: NSNotification?) {
        self.tableView.reloadData()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.rule.backgroundColor = Theme.colorSeparator
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
        
        if self.simplePicker {
            
            let gradient = CAGradientLayer()
            gradient.frame = CGRect(x: 0, y: 0, width: Config.navigationDrawerWidth, height: 64)
            gradient.colors = [Colors.accentColor.cgColor, Colors.brandColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradient.zPosition = 1
            gradient.shouldRasterize = true
            gradient.rasterizationScale = UIScreen.main.scale

            self.gradientImage = ImageUtils.imageFromLayer(layer: gradient)

            self.tableView.backgroundColor = Theme.colorBackgroundTable
            self.tableView.delegate = self
            self.tableView.tableFooterView = UIView()
            self.tableView.rowHeight = 64
            self.tableView.separatorInset = UIEdgeInsets.zero
            self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
            
            self.view.addSubview(self.tableView)
            
            let titleWidth = (Config.navigationDrawerWidth - 112)
            let titleView = AirLabelDisplay(text: " Patchr Groups")
            titleView.frame = CGRect(x: 0, y: 0, width: titleWidth, height: 24)
            titleView.font = Theme.fontBarText
            self.titleView = UIBarButtonItem(customView: titleView)
            
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
            self.navigationItem.leftBarButtonItems = [self.titleView]
            
            self.navigationController?.setToolbarHidden(false, animated: true)
            let addButton = UIBarButtonItem(title: "New Group", style: .plain, target: self, action: #selector(addAction(sender:)))
            self.toolbarItems = [spacerFlex, addButton, spacerFlex]
            
            return
        }
        
        guard let userId = UserController.instance.userId else {
            return
        }
        
        FireController.instance.findFirstGroup(userId: userId, next: { group in
            
            /* User is a member of at least one group */
            if group != nil {
                
                self.groupAvailable = true
                
                self.messageLabel.textAlignment = NSTextAlignment.center
                self.messageLabel.numberOfLines = 0
                self.messageLabel.text = "Select from groups you are a member of. You can switch groups at anytime."
                self.view.addSubview(self.messageLabel)
                self.view.addSubview(self.rule)
                
                self.tableView.backgroundColor = Theme.colorBackgroundTable
                self.tableView.delegate = self
                self.tableView.tableFooterView = UIView()
                self.tableView.rowHeight = 64
                self.tableView.separatorInset = UIEdgeInsets.zero
                self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
                
                self.view.addSubview(self.tableView)
                
                self.navigationController?.setToolbarHidden(false, animated: true)
                let addButton = UIBarButtonItem(title: "New Group", style: .plain, target: self, action: #selector(self.addAction(sender:)))
                self.toolbarItems = [spacerFlex, addButton, spacerFlex]
                
                if self.presented {
                    let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
                    self.navigationItem.rightBarButtonItems = [closeButton]
                }
            }
                
            /* User is not a member of any group */
            else {
                
                self.messageLabel.textAlignment = NSTextAlignment.center
                self.messageLabel.numberOfLines = 0
                self.messageLabel.text = "Oops, you are not a member of any Patchr group."
                self.view.addSubview(self.messageLabel)
                self.view.addSubview(self.rule)
                
                self.buttonLogin.setTitle("Log in with another email", for: .normal)
                self.buttonSignup.setTitle("Create a new Patchr group", for: .normal)
                
                self.buttonGroup.addSubview(self.buttonLogin)
                self.buttonGroup.addSubview(self.buttonSignup)
                self.view.addSubview(self.buttonGroup)
                
                self.buttonLogin.addTarget(self, action: #selector(self.switchLoginAction(sender:)), for: .touchUpInside)
                self.buttonSignup.addTarget(self, action: #selector(self.addAction(sender:)), for: .touchUpInside)
                
                /* Navigation bar buttons */
                self.navigationController?.setToolbarHidden(true, animated: true)
                let logoutButton = UIBarButtonItem(title: "Log out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.logoutAction(sender:)))
                self.navigationItem.rightBarButtonItems = [logoutButton]
            }
        })
    }
    
    func bind() {
        
        if let userId = UserController.instance.userId {
            
            if self.tableViewDataSource != nil {
                self.tableViewDataSource = nil
                self.tableView.reloadData()
            }            
            
            self.groupsQuery = FireController.db.child("member-groups/\(userId)").queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.tableViewDataSource = FUITableViewDataSource(
                query: self.groupsQuery,
                view: self.tableView,
                populateCell: { [weak self] (tableView, indexPath, snap) -> UITableViewCell in
                    return (self?.populateCell(tableView, cellForRowAt: indexPath, snap: snap))!
            })
            
            self.tableView.dataSource = self.tableViewDataSource
        }
    }
    
    func populateCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, snap: FIRDataSnapshot) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as! GroupListCell
        let link = snap.value as! [String: Any]
        let groupId = snap.key
        
        cell.reset()
        
        if groupId == StateController.instance.groupId {
            cell.selected(on: true)
        }
        
        FireController.db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) {
                if let group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key) {
                    group.membershipFrom(dict: link)
                    cell.bind(group: group)
                }
            }
            else {
                Log.w("Ouch! User is member of group that does not exist")
            }
        })
        
        return cell
    }
}

extension GroupSwitcherController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        
        /* User last channel if available */
        let groupId = cell.group.id!
        let userId = UserController.instance.userId
        
        if let lastChannelIds = UserDefaults.standard.dictionary(forKey: PerUserKey(key: Prefs.lastChannelIds)),
            let lastChannelId = lastChannelIds[groupId] as? String {
            let validateQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId!)
            validateQuery.once(with: { error, channel in
                if channel == nil {
                    Log.w("Last channel invalid: \(lastChannelId): trying auto pick channel")
                    FireController.instance.autoPickChannel(groupId: groupId) { channelId in
                        if channelId != nil {
                            self.showChannel(channelId: channelId!, groupId: groupId)
                        }
                    }
                }
                else {
                    self.showChannel(channelId: lastChannelId, groupId: groupId)
                }
            })
        }
        else {
            FireController.instance.autoPickChannel(groupId: groupId) { channelId in
                if channelId != nil {
                    self.showChannel(channelId: channelId!, groupId: groupId)
                }
                else {
                    StateController.instance.setChannelId(channelId: nil, groupId: groupId)
                    MainController.instance.showEmpty() // Replaced if we ever get a real channel
                    let _ = self.navigationController?.popViewController(animated: true)
                    self.closeAction(sender: nil)
                }
            }
        }
    }
    
    func showChannel(channelId: String, groupId: String) {
        if self.simplePicker {
            StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
            let _ = self.navigationController?.popViewController(animated: true)
        }
        else {
            StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
            let _ = self.navigationController?.popViewController(animated: true)
            self.closeAction(sender: nil)
        }
    }
}
