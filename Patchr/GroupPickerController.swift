//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class GroupPickerController: BaseTableController {
    
    var groupsQuery: FIRDatabaseQuery!
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    
    var gradientImage: UIImage!
    var messageLabel = AirLabelTitle()
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var footerView = AirLinkButton()
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
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.simplePicker {
            self.tableView.fillSuperview()
            return
        }
        
        let messageSize = self.messageLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        if self.navigationController != nil {
            self.messageLabel.alignUnder(self.navigationController?.navigationBar, matchingCenterWithTopPadding: 16, width: 288, height: messageSize.height + 24)
        }
        else {
            self.messageLabel.anchorTopCenter(withTopPadding: 24, width: 288, height:  messageSize.height + 24)
        }
        self.rule.alignUnder(self.messageLabel, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 1)
        
        if self.groupAvailable {
            self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
            self.tableView.alignBetweenTop(self.rule, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
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
        let controller = GroupCreateController()
        let wrapper = AirNavigationController()
        wrapper.viewControllers = [controller]
        self.slideMenuController()?.closeLeft()
        self.present(wrapper, animated: true, completion: nil)
    }
    
    func closeAction(sender: AnyObject?) {
        if self.simplePicker {
            let controller = MainController.instance.channelPickerController
            self.navigationController?.pushViewController(controller, animated: true)
            return
        }
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
            gradient.frame = CGRect(x: 0, y: 0, width: NAVIGATION_DRAWER_WIDTH, height: 64)
            gradient.colors = [Colors.accentColor.cgColor, Colors.brandColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradient.zPosition = 1
            gradient.shouldRasterize = true
            gradient.rasterizationScale = UIScreen.main.scale

            self.gradientImage = Utils.imageFromLayer(layer: gradient)

            self.cellReuseIdentifier = "group-cell"
            self.tableView.backgroundColor = Theme.colorBackgroundTable
            self.tableView.delegate = self
            self.tableView.tableFooterView = UIView()
            self.tableView.rowHeight = 64
            self.tableView.separatorInset = UIEdgeInsets.zero
            self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
            
            self.view.addSubview(self.tableView)
            
            let titleView = AirLabelDisplay(text: " Patchr Groups")
            titleView.font = Theme.fontBarText
            titleView.sizeToFit()
            self.titleView = UIBarButtonItem(customView: titleView)
            
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
            self.navigationItem.leftBarButtonItems = [self.titleView]
            
            let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction(sender:)))
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
                
                self.footerView.setImage(UIImage(named: "imgAddCircleLight"), for: .normal)
                self.footerView.imageView!.contentMode = .scaleAspectFit
                self.footerView.imageView?.tintColor = Colors.brandOnLight
                self.footerView.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
                self.footerView.contentHorizontalAlignment = .center
                self.footerView.backgroundColor = Colors.gray95pcntColor
                self.footerView.addTarget(self, action: #selector(self.addAction(sender:)), for: .touchUpInside)
                
                self.cellReuseIdentifier = "group-cell"
                self.tableView.backgroundColor = Theme.colorBackgroundTable
                self.tableView.delegate = self
                self.tableView.tableFooterView = UIView()
                self.tableView.rowHeight = 64
                self.tableView.separatorInset = UIEdgeInsets.zero
                self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
                
                self.view.addSubview(self.tableView)
                self.view.addSubview(self.footerView)
                
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: (self.cellReuseIdentifier)!, for: indexPath) as! GroupListCell
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

extension GroupPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        
        /* User last channel if available */
        let groupId = cell.group.id!
        let userId = UserController.instance.userId
        
        if let settings = UserDefaults.standard.dictionary(forKey: groupId),
            let lastChannelId = settings["currentChannelId"] as? String {
            let validateQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId!)
            validateQuery.once(with: { channel in
                if channel == nil {
                    Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                    FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                        if firstChannelId != nil {
                            if !self.simplePicker {
                                StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                                MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                                let _ = self.navigationController?.popToRootViewController(animated: false)
                                self.closeAction(sender: nil)
                            }
                            else {
                                StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                                MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                                let controller = MainController.instance.channelPickerController
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                        }
                    }
                }
                else {
                    if !self.simplePicker {
                        StateController.instance.setChannelId(channelId: lastChannelId, groupId: groupId)
                        MainController.instance.showChannel(groupId: groupId, channelId: lastChannelId)
                        let _ = self.navigationController?.popToRootViewController(animated: false)
                        self.closeAction(sender: nil)
                    }
                    else {
                        StateController.instance.setChannelId(channelId: lastChannelId, groupId: groupId)
                        MainController.instance.showChannel(groupId: groupId, channelId: lastChannelId)
                        let controller = MainController.instance.channelPickerController
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            })
        }
        else {
            FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                if firstChannelId != nil {
                    if !self.simplePicker {
                        StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                        MainController.instance.showMain()
                        MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                        let _ = self.navigationController?.popToRootViewController(animated: false)
                        self.closeAction(sender: nil)
                    }
                    else {
                        StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                        MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                        let controller = MainController.instance.channelPickerController
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
        }
    }
}
