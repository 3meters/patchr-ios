//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class GroupPickerController: UIViewController, UITableViewDelegate {
    
    var query: FIRDatabaseQuery!
    
    var headerView: GroupsHeaderView!
    var message: String = "Select from groups you are a member of. You can switch groups at anytime."
    var messageLabel = AirLabelTitle()
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    var footerView = AirLinkButton()
    var rule = UIView()
    
    var buttonLogin		= AirButton()
    var buttonSignup	= AirButton()
    var buttonGroup		= UIView()
    
    var groupAvailable = false
    
    var isModal: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
    
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
        
        let messageSize = self.messageLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        if self.navigationController != nil {
            self.messageLabel.alignUnder(self.navigationController?.navigationBar, matchingCenterWithTopPadding: 24, width: 288, height: messageSize.height + 24)
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
        if self.groupAvailable {
            let controller = GroupCreateController()
            let wrapper = AirNavigationController()
            wrapper.viewControllers = [controller]
            self.present(wrapper, animated: true, completion: nil)
        }
        else {
            let controller = GroupCreateController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func dismissAction(sender: AnyObject?) {
        self.performBack(animated: true)
    }
    
    func loginAction(sender: AnyObject?) {
        let controller = EmailViewController()
        controller.mode = .login
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func logoutAction(sender: AnyObject?) {
        UserController.instance.logout()
        self.dismiss(animated: true, completion: nil)
    }
    
    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.view.backgroundColor = Theme.colorBackgroundForm
        self.rule.backgroundColor = Theme.colorSeparator
        
        let userId = UserController.instance.userId
        FireController.instance.findFirstGroup(userId: userId!, next: { group in
            
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
                self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
                self.tableView.delegate = self
                self.tableView.register(UINib(nibName: "GroupListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
                
                self.view.addSubview(self.tableView)
                self.view.addSubview(self.footerView)
            }
                
            /* User is not a member of any group */
            else {
                
                self.messageLabel.textAlignment = NSTextAlignment.center
                self.messageLabel.numberOfLines = 0
                self.messageLabel.text = "Oops, you are not a member of any Patchr group."
                self.view.addSubview(self.messageLabel)
                self.view.addSubview(self.rule)
                
                self.buttonLogin.setTitle("Log in with another email", for: .normal)
//                self.buttonLogin.setTitleColor(Colors.white, for: .normal)
//                self.buttonLogin.setTitleColor(Theme.colorTint, for: .highlighted)
//                self.buttonLogin.borderColor = Colors.white
//                self.buttonLogin.borderWidth = Theme.dimenButtonBorderWidth
//                self.buttonLogin.cornerRadius = Theme.dimenButtonCornerRadius
                
                self.buttonSignup.setTitle("Create a new Patchr group", for: .normal)
//                self.buttonSignup.setTitleColor(Colors.white, for: .normal)
//                self.buttonSignup.setTitleColor(Theme.colorTint, for: .highlighted)
//                self.buttonSignup.borderColor = Colors.white
//                self.buttonSignup.borderWidth = Theme.dimenButtonBorderWidth
//                self.buttonSignup.cornerRadius = Theme.dimenButtonCornerRadius
                
                self.buttonGroup.addSubview(self.buttonLogin)
                self.buttonGroup.addSubview(self.buttonSignup)
                self.view.addSubview(self.buttonGroup)
                
                self.buttonLogin.addTarget(self, action: #selector(self.loginAction(sender:)), for: .touchUpInside)
                self.buttonSignup.addTarget(self, action: #selector(self.addAction(sender:)), for: .touchUpInside)
                
                /* Navigation bar buttons */
                let logoutButton = UIBarButtonItem(title: "Log out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.logoutAction(sender:)))
                self.navigationItem.rightBarButtonItems = [logoutButton]
            }
        })
    }
    
    func bind() {
        
        if self.tableViewDataSource == nil {
            
            let userId = UserController.instance.userId
            self.query = FireController.db.child("member-groups/\(userId!)").queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.tableViewDataSource = FUITableViewDataSource(
                query: self.query,
                view: self.tableView,
                populateCell: { [weak self] (view, indexPath, snap) -> GroupListCell in
                    
                    let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! GroupListCell
                    let groupId = snap.key
                    let link = snap.value as! [String: Any]
                    
                    cell.reset()
                    cell.backgroundColor = Colors.white
                    cell.title?.textColor = Theme.colorText
                    cell.subtitle?.textColor = Theme.colorTextSecondary
                    cell.photoView?.layer.borderWidth = 0
                    cell.accessoryType = .none
                    
                    if groupId == StateController.instance.groupId {
                        cell.backgroundColor = Colors.accentColorFill
                        cell.title?.textColor = Colors.white
                        cell.subtitle?.textColor = Colors.black
                        cell.photoView?.layer.borderColor = Colors.opacity50pcntWhite.cgColor
                        cell.photoView?.layer.borderWidth = 0.5
                        cell.tintColor = Colors.white
                        cell.accessoryType = .checkmark
                    }
                    
                    FireController.db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                        if let group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key) {
                            group.membershipFrom(dict: link)
                            cell.bind(group: group)
                        }
                    })
                    
                    return cell
            })

            self.tableView.dataSource = self.tableViewDataSource
        }
    }
    
    func performBack(animated: Bool = true) {
        /* Override in subclasses for control of dismiss/pop process */
        if isModal {
            if self.navigationController != nil {
                self.navigationController!.dismiss(animated: animated, completion: nil)
            }
            else {
                self.dismiss(animated: animated, completion: nil)
            }
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! GroupListCell
        
        /* User last channel if available */
        let groupId = cell.group.id!
        let userId = UserController.instance.userId
        
        if let lastChannelId = UserDefaults.standard.string(forKey: groupId)  {
            let validateQuery = ChannelQuery(groupId: groupId, channelId: lastChannelId, userId: userId!)
            validateQuery.once(with: { channel in
                if channel == nil {
                    Log.w("Last channel invalid: \(lastChannelId): trying first channel")
                    FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                        if firstChannelId != nil {
                            StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
                            MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                            let _ = self.navigationController?.popToRootViewController(animated: false)
                            self.dismissAction(sender: nil)
                        }
                    }
                }
                else {
                    StateController.instance.setGroupId(groupId: groupId, channelId: lastChannelId)
                    MainController.instance.showChannel(groupId: groupId, channelId: lastChannelId)
                    let _ = self.navigationController?.popToRootViewController(animated: false)
                    self.dismissAction(sender: nil)
                }
            })
        }
        else {
            FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
                if firstChannelId != nil {
                    StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
                    MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                    let _ = self.navigationController?.popToRootViewController(animated: false)
                    self.dismissAction(sender: nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
