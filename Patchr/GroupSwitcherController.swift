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
    var headingLabel = AirLabelTitle()
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
        
        self.view.fillSuperview()
        
        if self.simplePicker {
            self.tableView.fillSuperview()
        }
        else {
            let headingSize = self.headingLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
            
            self.headingLabel.anchorTopCenter(withTopPadding: 74, width: 288, height:  headingSize.height + 24)
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
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.rule.backgroundColor = Theme.colorSeparator
        
        if self.simplePicker {
            
            self.tableView.backgroundColor = Theme.colorBackgroundTable
            self.tableView.delegate = self
            self.tableView.tableFooterView = UIView()
            self.tableView.rowHeight = 64
            self.tableView.separatorInset = UIEdgeInsets.zero
            self.tableView.contentInset = UIEdgeInsets(top: 74, left: 0, bottom: 44, right: 0)
            self.tableView.contentOffset = CGPoint(x: 0, y: -74)
            self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
            
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
                
                self.headingLabel.textAlignment = NSTextAlignment.center
                self.headingLabel.numberOfLines = 0
                self.headingLabel.text = "Select from groups you are a member of. You can switch groups at anytime."
                
                self.tableView.backgroundColor = Theme.colorBackgroundTable
                self.tableView.delegate = self
                self.tableView.tableFooterView = UIView()
                self.tableView.rowHeight = 64
                self.tableView.separatorInset = UIEdgeInsets.zero
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
                self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
                
                self.view.addSubview(self.headingLabel)
                self.view.addSubview(self.rule)
                self.view.addSubview(self.tableView)
                
                let addButton = UIBarButtonItem(title: "New Group", style: .plain, target: self, action: #selector(self.addAction(sender:)))
                self.toolbarItems = [spacerFlex, addButton, spacerFlex]
                
                if self.presented {
                    let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
                    self.navigationItem.rightBarButtonItems = [closeButton]
                }
            }
                
            /* User is not a member of any group */
            else {
                
                self.headingLabel.textAlignment = NSTextAlignment.center
                self.headingLabel.numberOfLines = 0
                self.headingLabel.text = "Oops, you are not a member of any Patchr group."
                
                self.buttonLogin.setTitle("Log in with another email", for: .normal)
                self.buttonLogin.addTarget(self, action: #selector(self.switchLoginAction(sender:)), for: .touchUpInside)
                self.buttonSignup.setTitle("Create a new Patchr group", for: .normal)
                self.buttonSignup.addTarget(self, action: #selector(self.addAction(sender:)), for: .touchUpInside)
                
                self.buttonGroup.addSubview(self.buttonLogin)
                self.buttonGroup.addSubview(self.buttonSignup)
                
                self.view.addSubview(self.headingLabel)
                self.view.addSubview(self.rule)
                self.view.addSubview(self.buttonGroup)
                
                /* Navigation bar buttons */
                self.navigationController?.setToolbarHidden(true, animated: true)
                self.tableView.contentInset = UIEdgeInsets(top: 74, left: 0, bottom: 44, right: 0)

                let logoutButton = UIBarButtonItem(title: "Log out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.logoutAction(sender:)))
                self.navigationItem.rightBarButtonItems = [logoutButton]
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
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
            self.view.setNeedsLayout()
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
