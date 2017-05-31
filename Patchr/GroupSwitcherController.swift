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
    
    var gradientImage: UIImage!
    var headingLabel: AirLabelTitle!
    var rule: UIView!
    var buttonLogin: AirButton!
    var buttonSignup: AirButton!
    var buttonGroup: UIView!
    var titleView: UIBarButtonItem!
    
    var message: String = "Select from groups you are a member of. You can switch groups at anytime."

    var flow: Flow = .none
    var validateQuery: ChannelQuery!
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UserController.instance.loginAlertShown {
            if let email = Auth.auth().currentUser?.email! {
                UIShared.toast(message: "Logged in using: \(email)", duration: 1.0)
            }
        }
        UserController.instance.loginAlertShown = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.simplePicker {
            self.view.fillSuperview()
            self.tableView.fillSuperview()
        }
        else {
            if self.headingLabel != nil {
                let headingSize = self.headingLabel.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))
                
                self.headingLabel.anchorTopCenter(withTopPadding: 74, width: Config.contentWidth, height:  headingSize.height + 24)
                self.rule.alignUnder(self.headingLabel, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 1)
                
                if self.groupAvailable {
                    self.tableView.alignUnder(self.rule, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
                }
                else {
                    self.buttonGroup.anchorInCenter(withWidth: 240, height: 96)
                    self.buttonSignup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
                    self.buttonLogin.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
                }                
            }
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
                Reporting.track("view_group_new")
                let controller = GroupCreateController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.flow = .internalCreate
                self.slideMenuController()?.closeLeft()
                self.present(wrapper, animated: true, completion: nil)
            }
        }
    }
    
    func closeAction(sender: AnyObject?) {
        Reporting.track("switch_navigation_to_channels")
        close(animated: true)
    }
    
    func logoutAction(sender: AnyObject?) {
        Reporting.track("logout")
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
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
        
        if self.simplePicker { // Shown in navigation drawer
            
            self.tableView.backgroundColor = Theme.colorBackgroundTable
            self.tableView.delegate = self
            self.tableView.tableFooterView = UIView()
            self.tableView.rowHeight = 64
            self.tableView.separatorInset = UIEdgeInsets.zero
            self.tableView.contentInset = UIEdgeInsets(top: 74, left: 0, bottom: 44, right: 0)
            self.tableView.contentOffset = CGPoint(x: 0, y: -74)
            self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: "cell")
            
            self.view.addSubview(self.tableView)
            
            let gradient = CAGradientLayer()
            gradient.frame = CGRect(x: 0, y: 0, width: Config.navigationDrawerWidth, height: 64)
            gradient.colors = [Colors.accentColor.cgColor, Colors.brandColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradient.zPosition = 1
            gradient.shouldRasterize = true
            gradient.rasterizationScale = UIScreen.main.scale
            
            self.gradientImage = ImageUtils.imageFromLayer(layer: gradient)
            
            let titleWidth = (Config.navigationDrawerWidth - 112)
            let titleView = AirLabelDisplay(text: "Patchr Groups")
            titleView.frame = CGRect(x: 0, y: 0, width: titleWidth, height: 24)
            titleView.font = Theme.fontBarText
            titleView.insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.titleView = UIBarButtonItem(customView: titleView)
            
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 30))
            button.setImage(#imageLiteral(resourceName: "imgCancelLight"), for: .normal)
            button.addTarget(self, action: #selector(closeAction(sender:)), for: .touchUpInside)
            let closeButton = UIBarButtonItem(customView: button)
            
            self.navigationItem.rightBarButtonItems = [closeButton]
            self.navigationItem.leftBarButtonItems = [self.titleView]
            
            let addButton = UIBarButtonItem(title: "New Group", style: .plain, target: self, action: #selector(addAction(sender:)))
            self.toolbarItems = [Ui.spacerFlex, addButton, Ui.spacerFlex]
            
            return
        }
        
        guard let userId = UserController.instance.userId else {
            return
        }
        
        FireController.instance.findFirstGroup(userId: userId, next: { group in
            
            if group == nil { /* User is not a member of any group */
                MainController.instance.showUserLobby()
                self.close(animated: false)
            }
            
            else { /* User is a member of at least one group */
                
                self.groupAvailable = true
                
                self.headingLabel = AirLabelTitle()
                self.headingLabel.textAlignment = NSTextAlignment.center
                self.headingLabel.numberOfLines = 0
                self.headingLabel.text = "Select from groups you are a member of. You can switch groups at anytime."
                
                self.rule = UIView()
                self.rule.backgroundColor = Theme.colorSeparator
                
                self.tableView.backgroundColor = Theme.colorBackgroundTable
                self.tableView.delegate = self
                self.tableView.tableFooterView = UIView()
                self.tableView.rowHeight = 64
                self.tableView.separatorInset = UIEdgeInsets.zero
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
                self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: "cell")
                
                self.view.addSubview(self.headingLabel)
                self.view.addSubview(self.rule)
                self.view.addSubview(self.tableView)
                
                let addButton = UIBarButtonItem(title: "New Group", style: .plain, target: self, action: #selector(self.addAction(sender:)))
                self.toolbarItems = [Ui.spacerFlex, addButton, Ui.spacerFlex]
                
                if self.presented {
                    let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
                    self.navigationItem.leftBarButtonItems = [closeButton]
                }
                else if self.flow == .onboardLogin {
                    let logoutButton = UIBarButtonItem(title: "Log out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.logoutAction(sender:)))
                    self.navigationItem.rightBarButtonItems = [logoutButton]
                }
            }
        })
    }
    
    func bind() {
        
        if let userId = UserController.instance.userId {
            
            if self.queryController != nil {
                self.queryController = nil
                self.tableView.reloadData()
            }            
            
            let query = FireController.db.child("member-groups/\(userId)").queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.queryController = DataSourceController(name: "group_switcher")
            self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GroupListCell
                cell.reset()
                guard self != nil else { return cell }
                
                if let userId = UserController.instance.userId,
                    let snap = data as? DataSnapshot {
                    
                    let groupId = snap.key
                    
                    cell.groupQuery = GroupQuery(groupId: groupId, userId: userId)
                    cell.groupQuery!.observe(with: { [weak cell] error, trigger, group in
                        guard let cell = cell else { return }
                        if group != nil {
                            cell.selected(on: (groupId == StateController.instance.groupId), style: .prominent)
                            cell.bind(group: group!)
                            cell.unreadQuery = UnreadQuery(level: .group, userId: userId, groupId: groupId)
                            cell.unreadQuery!.observe(with: { [weak cell] error, total in
                                guard let cell = cell else { return }
                                if total != nil && total! > 0 {
                                    cell.badge?.text = "\(total!)"
                                    cell.badge?.isHidden = false
                                    cell.accessoryType = .none
                                }
                                else {
                                    cell.badge?.isHidden = true
                                    cell.accessoryType = cell.selectedOn ? .checkmark : .none
                                }
                            })
                        }
                    })
                }                
                return cell
            }
            self.view.setNeedsLayout()
        }
    }
}

extension GroupSwitcherController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        Reporting.track("select_group")
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        
        /* User last channel if available */
        let groupId = cell.group.id!
        let userId = UserController.instance.userId!
        let role = cell.group.role!
        
        if let lastChannelIds = UserDefaults.standard.dictionary(forKey: PerUserKey(key: Prefs.lastChannelIds)),
            let lastChannelId = lastChannelIds[groupId] as? String {
            self.validateQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId)
            self.validateQuery.once(with: { [weak self] error, channel in
                guard let this = self else { return }
                if channel == nil {
                    Log.w("Last channel invalid: \(lastChannelId): trying auto pick channel")
                    FireController.instance.autoPickChannel(groupId: groupId, role: role) { channelId in
                        if channelId != nil {
                            this.showChannel(channelId: channelId!, groupId: groupId)
                        }
                    }
                }
                else {
                    this.showChannel(channelId: lastChannelId, groupId: groupId)
                }
            })
        }
        else {
            FireController.instance.autoPickChannel(groupId: groupId, role: role) { channelId in
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
            MainController.instance.showChannel(channelId: channelId, groupId: groupId)
            let _ = self.navigationController?.popViewController(animated: true)
        }
        else {
            StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
            MainController.instance.showChannel(channelId: channelId, groupId: groupId)
            let _ = self.navigationController?.popViewController(animated: true)
            self.closeAction(sender: nil)
        }
    }
}
