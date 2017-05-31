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
import Firebase
import FirebaseAuth

class SettingsTableViewController: UITableViewController {

    var progress: AirProgress?

    /* Section 1: Global settings */
    var editProfileCell = AirTableViewCell()

    /* Section 2: User settings for group */
    var notificationsCell = AirTableViewCell()
    var hideEmailCell = AirTableViewCell()
    var leaveGroupCell = AirTableViewCell()

    /* Section 3: Informational */
    var sendFeedbackCell = AirTableViewCell()
    var rateCell = AirTableViewCell()
    var aboutCell = AirTableViewCell()
    var developmentCell = AirTableViewCell()

    /* Section 4: Actions */
    var clearHistoryCell = AirTableViewCell()
    var logoutCell = AirTableViewCell()

    var logoutButton = AirLinkButton()
    var clearHistoryButton = AirLinkButton()
    var leaveGroupButton = AirLinkButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
        }
        bind()
    }
    
    deinit {
        self.progress?.hide(true)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let viewWidth = min(Config.contentWidthMax, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth

        self.logoutButton.fillSuperview()
        self.clearHistoryButton.fillSuperview()
        self.leaveGroupButton.fillSuperview()
    }
    
    func leaveGroupAction(sender: AnyObject) {
        
        DeleteConfirmationAlert(
            title: "Confirm",
            message: "Are you sure you want to leave this group? An invitation may be required to rejoin.",
            actionTitle: "Leave", cancelTitle: "Cancel", delegate: self) { doIt in
                if doIt {
                    Reporting.track("leave_group")
                    self.progress = AirProgress.showAdded(to: MainController.instance.window!, animated: true)
                    self.progress!.mode = MBProgressHUDMode.indeterminate
                    self.progress!.styleAs(progressStyle: .activityWithText)
                    self.progress!.minShowTime = 0.5
                    self.progress!.labelText = "Leaving..."
                    self.progress!.removeFromSuperViewOnHide = true
                    self.progress!.show(true)
                    
                    if let group = StateController.instance.group {
                        let userId = UserController.instance.userId!
                        FireController.instance.removeUserFromGroup(userId: userId, groupId: group.id!) { success in
                            self.progress?.hide(true)
                            self.dismiss(animated: true)
                            StateController.instance.clearGroup()   // Make sure group and channel are both unset
                            let controller = GroupSwitcherController()
                            let wrapper = AirNavigationController()
                            wrapper.viewControllers = [controller]
                            UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
                        }
                    }
                }
        }
    }

    func logoutAction(sender: AnyObject) {
        self.dismiss(animated: true) {
            Reporting.track("logout")
            UserController.instance.logout()
        }
    }

    func clearHistoryAction(sender: AnyObject) {

        self.progress = AirProgress.showAdded(to: MainController.instance.window!, animated: true)
        self.progress!.mode = MBProgressHUDMode.indeterminate
        self.progress!.styleAs(progressStyle: .activityWithText)
        self.progress!.minShowTime = 0.5
        self.progress!.labelText = "Clearing..."
        self.progress!.removeFromSuperViewOnHide = true
        self.progress!.show(true)

        Utils.clearSearchHistory()
        Reporting.track("clear_search_history")

        self.progress!.hide(true)
    }
    
    func closeAction(sender: AnyObject?) {
        close(animated: true)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.navigationItem.title = "Settings"

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.clearHistoryCell.contentView.addSubview(self.clearHistoryButton)
        self.logoutCell.contentView.addSubview(self.logoutButton)
        self.leaveGroupCell.contentView.addSubview(self.leaveGroupButton)
        self.clearHistoryCell.accessoryType = .none
        self.logoutCell.accessoryType = .none
        self.leaveGroupCell.accessoryType = .none

        self.editProfileCell.textLabel!.text = "Edit Profile"

        self.notificationsCell.textLabel!.text = "Notifications and Sounds"
        self.hideEmailCell.textLabel!.text = "Hide Email"

        self.sendFeedbackCell.textLabel!.text = "Send feedback"
        self.rateCell.textLabel!.text = "Rate Patchr"
        self.aboutCell.textLabel!.text = "About"
        self.developmentCell.textLabel!.text = "Developer"

        self.clearHistoryButton.setTitle("Clear search history".uppercased(), for: .normal)
        self.logoutButton.setTitle("Log out".uppercased(), for: .normal)
        self.leaveGroupButton.setTitle("Leave group".uppercased(), for: .normal)
        
        if StateController.instance.group?.ownedBy == UserController.instance.userId! {
            self.leaveGroupCell.isHidden = true
        }
        
        self.logoutButton.addTarget(self, action: #selector(SettingsTableViewController.logoutAction(sender:)), for: .touchUpInside)
        self.clearHistoryButton.addTarget(self, action: #selector(SettingsTableViewController.clearHistoryAction(sender:)), for: .touchUpInside)
        self.leaveGroupButton.addTarget(self, action: #selector(SettingsTableViewController.leaveGroupAction(sender:)), for: .touchUpInside)
        
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
    }
    
    func bind() {
        if let group = StateController.instance.group {
            self.hideEmailCell.accessoryView = makeSwitch(notificationType: .hideEmail, state: (group.email == nil))
        }
    }

    func makeSwitch(notificationType: Setting, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = notificationType.rawValue
        switchView.addTarget(self, action: #selector(toggleAction(sender:)), for: UIControlEvents.valueChanged)
        switchView.isOn = state
        return switchView
    }

    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == Setting.hideEmail.rawValue {
                let groupId = StateController.instance.groupId!
                let userId = UserController.instance.userId!
                let memberGroupsPath = "member-groups/\(userId)/\(groupId)/email"
                let groupMembersPath = "group-members/\(groupId)/\(userId)/email"
                if switcher.isOn {
                    Reporting.track("hide_email")
                    let updates: [String: Any] = [
                        groupMembersPath: NSNull(),
                        memberGroupsPath: NSNull()
                    ]
                    FireController.db.updateChildValues(updates)
                }
                else if let email = Auth.auth().currentUser?.email {
                    Reporting.track("show_email")
                    let updates: [String: Any] = [
                        groupMembersPath: email,
                        memberGroupsPath: email
                    ]
                    FireController.db.updateChildValues(updates)
                }
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return UserDefaults.standard.bool(forKey: Prefs.statusBarHidden)
    }
}

extension SettingsTableViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)
        
        if selectedCell == self.editProfileCell {
            Reporting.track("view_profile_edit")
            let controller = ProfileEditViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }

        if selectedCell == self.notificationsCell {
            Reporting.track("view_notification_settings")
            let controller = NotificationSettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if selectedCell == self.sendFeedbackCell {
            Reporting.track("view_feedback_compose")
            let email = "feedback@patchr.com"
            let subject = "Feedback for Patchr iOS"
            if MFMailComposeViewController.canSendMail() {
                Ui.mailComposer!.mailComposeDelegate = self
                Ui.mailComposer!.setToRecipients([email])
                Ui.mailComposer!.setSubject(subject)
                self.present(Ui.mailComposer!, animated: true, completion: nil)
            }
            else {
                var emailURL = "mailto:\(email)"
                emailURL = emailURL.addingPercentEncoding(withAllowedCharacters: NSMutableCharacterSet.urlQueryAllowed) ?? emailURL
                if let url = NSURL(string: emailURL) {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    UIApplication.shared.openURL(url as URL)
                }
            }
        }
            
        if selectedCell == self.rateCell {
            Reporting.track("rate_app")
            let appStoreURL = "itms-apps://itunes.apple.com/app/id\(Ids.appleAppId)"
            if let url = NSURL(string: appStoreURL) {
                UIApplication.shared.openURL(url as URL)
            }
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
            
        if selectedCell == self.aboutCell {
            Reporting.track("view_about")
            let controller = AboutViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
            
        if selectedCell == self.developmentCell {
            Reporting.track("view_development_settings")
            let controller = DevelopmentViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 1 && indexPath.row == 2 {
            if StateController.instance.group?.ownedBy == UserController.instance.userId! {
                return CGFloat(0)
            }
        }
        
        if indexPath.section == 2 && indexPath.row == 3 {
            developmentCell.isHidden = true
            if let developer = UserController.instance.user?.developer {
                if developer {
                    developmentCell.isHidden = false
                    return CGFloat(44)
                }
            }
            return CGFloat(0)
        }
        
        if indexPath.section == 4 && indexPath.row == 0 {
            return CGFloat(64)
        }

        return CGFloat(44)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0: return self.editProfileCell
                    default: fatalError("Unknown row in section 1")
                }
            case 1:
                switch (indexPath.row) {
                    case 0: return self.notificationsCell
                    case 1: return self.hideEmailCell
                    case 2: return self.leaveGroupCell
                    default: fatalError("Unknown row in section 2")
                }
            case 2:
                switch (indexPath.row) {
                    case 0: return self.sendFeedbackCell
                    case 1: return self.rateCell
                    case 2: return self.aboutCell
                    case 3: return self.developmentCell
                    default: fatalError("Unknown row in section 3")
                }
            case 3:
                switch (indexPath.row) {
                    case 0: return self.clearHistoryCell
                    case 1: return self.logoutCell
                    default: fatalError("Unknown row in section 4")
                }
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return nil
            case 1:
                if let group = StateController.instance.group {
                    return "Your settings for group: \(group.title!)".uppercased()
                }
                return "Group settings".uppercased()
            case 2: return nil
            case 3: return nil
            case 4: return nil
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 1) ? 48 : 24
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 1
            case 1: return 3
            case 2: return 4
            case 3: return 2
            default: fatalError("Unknown number of sections")
        }
    }
}

enum Setting: Int {
    case hideEmail
    case playSoundEffects
    case vibrateForNotifications
    case soundForNotifications
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        switch result {
            case MFMailComposeResult.cancelled:    // 0
                Reporting.track("cancel_feedback")
                UIShared.toast(message: "Feedback cancelled", controller: self, addToWindow: false)
            case MFMailComposeResult.saved:        // 1
                Reporting.track("save_feedback")
                UIShared.toast(message: "Feedback saved", controller: self, addToWindow: false)
            case MFMailComposeResult.sent:        // 2
                Reporting.track("send_feedback")
                UIShared.toast(message: "Feedback sent", controller: self, addToWindow: false)
            case MFMailComposeResult.failed:    // 3
                UIShared.toast(message: "Feedback send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
                break
        }

        self.dismiss(animated: true) {
            Ui.mailComposer = nil
            Ui.mailComposer = MFMailComposeViewController()
        }
    }
}
