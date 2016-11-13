//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD
import PBWebViewController
import AddressBookUI
import ContactsUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

class SideMenuViewController: UITableViewController {

    var user: FireUser?
    var userQuery: UserQuery?
 
    var menuHeader: UserHeaderView!
    var inviteCell: WrapperTableViewCell?
    var membersCell: WrapperTableViewCell?
    var profileCell: WrapperTableViewCell?
    var settingsCell: WrapperTableViewCell?
    var switchCell: WrapperTableViewCell?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        if UserController.instance.userId != nil {
            self.userQuery = UserQuery(userId: UserController.instance.userId!)
            self.userQuery!.observe(with: { user in
                
                guard user != nil else {
                    assertionFailure("user not found or no longer exists")
                    return
                }

                self.user = user
                self.bind()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.bounds.size.width = SIDE_MENU_WIDTH        
    }
    
    func editProfileAction(sender: AnyObject?) {
        let controller = ProfileEditViewController()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: controller, action: #selector(controller.cancelAction(sender:)))
        controller.navigationItem.rightBarButtonItems = [cancelButton]
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        UIViewController.topMostViewController()?.present(navController, animated: true, completion: nil)
    }
    
    func userStateDidChange(notification: NSNotification) {
        if UserController.instance.userId != nil {
            self.userQuery?.remove()
            self.userQuery = UserQuery(userId: UserController.instance.userId!)
            self.userQuery!.observe(with: { user in
                
                guard user != nil else {
                    assertionFailure("user not found or no longer exists")
                    return
                }

                self.user = user
                self.bind()
            })
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("SideMenu")

        self.tableView = UITableView(frame: self.tableView.frame, style: .plain)
        self.tableView.rowHeight = 64
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorStyle = .none
        
        self.menuHeader = UserHeaderView()
        let headerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SideMenuViewController.editProfileAction(sender:)))
        self.menuHeader.userGroup.addGestureRecognizer(headerTapGestureRecognizer)
        self.menuHeader.frame = CGRect(x:0, y:0, width:self.tableView.width(), height:CGFloat(208))
        self.menuHeader.setNeedsLayout()
        self.menuHeader.layoutIfNeeded()
        
        self.tableView.tableHeaderView = menuHeader	// Triggers table binding

        self.inviteCell = WrapperTableViewCell(view: MenuItemView(title: "Invite", image: UIImage(named: "imgInvite2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.membersCell = WrapperTableViewCell(view: MenuItemView(title: "Group members", image: UIImage(named: "imgUsersLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.profileCell = WrapperTableViewCell(view: MenuItemView(title: "Edit profile", image: UIImage(named: "imgEdit2Light")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.settingsCell = WrapperTableViewCell(view: MenuItemView(title: "Settings", image: UIImage(named: "imgSettingsLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        self.switchCell = WrapperTableViewCell(view: MenuItemView(title: "Switch groups", image: UIImage(named: "imgSwitchLight")!), padding: UIEdgeInsets.zero, reuseIdentifier: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStateDidChange(notification:)), name: NSNotification.Name(rawValue: Events.UserStateDidChange), object: nil)
    }
    
    func bind() {
        self.menuHeader.bind(user: self.user)
    }
}

extension SideMenuViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)

        if selectedCell == self.inviteCell {
            
            BranchProvider.inviteMember(group: StateController.instance.group, completion: { response, error in
                
                if let error = ServerError(error) {
                    UIViewController.topMostViewController()!.handleError(error)
                }
                else {
                    let invite = response as! InviteItem
                    let inviteUrl = invite.url
                    
                    let group = StateController.instance.group
                    let userTitle = self.user!.profile?.fullName != nil ? self.user!.profile!.fullName! : self.user!.username!
                    let groupTitle = group!.title != nil ? group!.title! : group!.name!
                    let groupName = group!.name!
                    let userEmail = UserController.instance.user?.profile?.email!
                    let subject = "\(userTitle) invited you to \(groupTitle) on Patchr"
                    
                    let htmlFile = Bundle.main.path(forResource: "invite", ofType: "html")
                    
                    let templateString = try? String(contentsOfFile: htmlFile!, encoding: .utf8)
                    var htmlString = templateString?.replacingOccurrences(of: "[[group.name]]", with: groupName)
                    htmlString = htmlString?.replacingOccurrences(of: "[[user.fullName]]", with: userTitle)
                    htmlString = htmlString?.replacingOccurrences(of: "[[user.email]]", with: userEmail!)
                    htmlString = htmlString?.replacingOccurrences(of: "[[link]]", with: inviteUrl)
                    
                    if MFMailComposeViewController.canSendMail() {
                        MailComposer!.mailComposeDelegate = self
                        MailComposer!.setSubject(subject)
                        MailComposer!.setMessageBody(htmlString!, isHTML: true)
                        self.present(MailComposer!, animated: true, completion: nil)
                    }
                }
            })
            
        }
        else if selectedCell == self.settingsCell {
            
            let controller = SettingsTableViewController()
            let wrapper = AirNavigationController(rootViewController: controller)
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.cancelAction(sender:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        else if selectedCell == self.profileCell {
            
            editProfileAction(sender: self)
        }
        else if selectedCell == self.switchCell {
            
            let controller = GroupPickerController()
            let wrapper = AirNavigationController(rootViewController: controller)
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.dismissAction(sender:)))
            controller.mode = .fullscreen
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            self.slideMenuController()?.mainViewController?.present(wrapper, animated: true, completion: nil)
        }
        else if selectedCell == self.membersCell {
            
            let controller = UserListController()
            let wrapper = AirNavigationController(rootViewController: controller)
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: controller, action: #selector(controller.closeAction(sender:)))
            controller.navigationItem.rightBarButtonItems = [cancelButton]
            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
        }
        
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
        slideMenuController()?.closeRight()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(64)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.membersCell!
        }
        else if indexPath.row == 1 {
            return self.inviteCell!
        }
        else if indexPath.row == 2 {
            return self.profileCell!
        }
        else if indexPath.row == 4 {
            return self.settingsCell!
        }
        return self.switchCell!
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}

extension SideMenuViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case MFMailComposeResult.cancelled:    // 0
            UIShared.Toast(message: "Invites cancelled", controller: self, addToWindow: false)
        case MFMailComposeResult.saved:        // 1
            UIShared.Toast(message: "Invites saved", controller: self, addToWindow: false)
        case MFMailComposeResult.sent:        // 2
            Reporting.track("Sent Invites")
            UIShared.Toast(message: "Invites sent", controller: self, addToWindow: false)
        case MFMailComposeResult.failed:    // 3
            UIShared.Toast(message: "Invites send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
            break
        }
        
        self.dismiss(animated: true) {
            MailComposer = nil
            MailComposer = MFMailComposeViewController()
        }
    }
}
