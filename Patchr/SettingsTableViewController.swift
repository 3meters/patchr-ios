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

    var notificationsCell = AirTableViewCell()
    var sendFeedbackCell = AirTableViewCell()
    var rateCell = AirTableViewCell()
    var termsOfServiceCell = AirTableViewCell()
    var privacyPolicyCell = AirTableViewCell()
    var softwareLicensesCell = AirTableViewCell()
    var developmentCell = AirTableViewCell()
    var logoutCell = AirTableViewCell()
    var clearHistoryCell = AirTableViewCell()
    var buildInfoCell = AirTableViewCell()

    var buildInfoLabel = AirLabelDisplay()
    var logoutButton = AirLinkButton()
    var clearHistoryButton = AirLinkButton()
    
    var isModal: Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }

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
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth

        self.logoutButton.fillSuperview()
        self.clearHistoryButton.fillSuperview()
        self.buildInfoLabel.fillSuperview()
    }

    func logoutAction(sender: AnyObject) {

        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
        self.progress!.mode = MBProgressHUDMode.indeterminate
        self.progress!.styleAs(progressStyle: .ActivityWithText)
        self.progress!.minShowTime = 0.5
        self.progress!.labelText = "Logging out..."
        self.progress!.removeFromSuperViewOnHide = true
        self.progress!.show(true)
        
        try! FIRAuth.auth()!.signOut()
        
        Reporting.track("Logged Out")
        Log.i("User logged out")
        
        let navController = AirNavigationController()
        navController.viewControllers = [LobbyViewController()]
        MainController.instance.window!.setRootViewController(rootViewController: navController, animated: true)
    }

    func clearHistoryAction(sender: AnyObject) {

        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
        self.progress!.mode = MBProgressHUDMode.indeterminate
        self.progress!.styleAs(progressStyle: .ActivityWithText)
        self.progress!.minShowTime = 0.5
        self.progress!.labelText = "Clearing..."
        self.progress!.removeFromSuperViewOnHide = true
        self.progress!.show(true)

        Utils.clearHistory()
        Reporting.track("Cleared History")

        self.progress!.hide(true)
    }
    
    func cancelAction(sender: AnyObject?){
        if self.isModal {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        Reporting.screen("Settings")

        self.navigationItem.title = "Settings"

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.clearHistoryCell.contentView.addSubview(self.clearHistoryButton)
        self.logoutCell.contentView.addSubview(self.logoutButton)
        self.buildInfoCell.contentView.addSubview(self.buildInfoLabel)
        self.clearHistoryCell.accessoryType = .none
        self.logoutCell.accessoryType = .none
        self.buildInfoCell.accessoryType = .none

        let components = NSCalendar.current.dateComponents([.year, .month, .day], from: Date())
        self.buildInfoLabel.text = "©\(components.year) 3meters LLC\nVersion \(appVersion()) (\(build()))"
        self.buildInfoLabel.textColor = Theme.colorTextTitle
        self.buildInfoLabel.font = Theme.fontTextDisplay
        self.buildInfoLabel.numberOfLines = 2
        self.buildInfoLabel.textAlignment = .center
        self.buildInfoCell.isUserInteractionEnabled = false

        if let user = UserController.instance.currentUser {
            if user.developerValue {
                developmentCell.isHidden = false
                developmentCell.frame.size.height = 0
            }
        }

        self.notificationsCell.textLabel!.text = "Notifications and Sound"
        self.sendFeedbackCell.textLabel!.text = "Send feedback"
        self.rateCell.textLabel!.text = "Rate Patchr"
        self.termsOfServiceCell.textLabel!.text = "Terms of Service"
        self.privacyPolicyCell.textLabel!.text = "Privacy Policy"
        self.softwareLicensesCell.textLabel!.text = "Software Licenses"
        self.developmentCell.textLabel!.text = "Developer"
        
        self.clearHistoryButton.setTitle("Clear search history".uppercased(), for: .normal)
        self.logoutButton.setTitle("Log out".uppercased(), for: .normal)

        self.logoutButton.addTarget(self, action: #selector(SettingsTableViewController.logoutAction(sender:)), for: .touchUpInside)
        self.clearHistoryButton.addTarget(self, action: #selector(SettingsTableViewController.clearHistoryAction(sender:)), for: .touchUpInside)
    }
    
    func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    func build() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "Unknown"
    }

    func pushWebViewController(url: URL?) -> Void {
        let webViewController = PBWebViewController()
        webViewController.url = url
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
}

extension SettingsTableViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)

        if selectedCell == self.notificationsCell {
            let controller = NotificationSettingsSimpleViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
        else if selectedCell == self.sendFeedbackCell {
            let email = "feedback@patchr.com"
            let subject = "Feedback for Patchr iOS"
            if MFMailComposeViewController.canSendMail() {
                MailComposer!.mailComposeDelegate = self
                MailComposer!.setToRecipients([email])
                MailComposer!.setSubject(subject)
                self.present(MailComposer!, animated: true, completion: nil)
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
        else if selectedCell == self.rateCell {
            let appStoreURL = "itms-apps://itunes.apple.com/app/id\(APPLE_APP_ID)"
            if let url = NSURL(string: appStoreURL) {
                UIApplication.shared.openURL(url as URL)
            }
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        else if selectedCell == self.termsOfServiceCell {
            let termsURLString = "http://patchr.com/terms"
            self.pushWebViewController(url: NSURL(string: termsURLString) as URL?)
            Reporting.track("Viewed Terms of Service")
        }
        else if selectedCell == self.privacyPolicyCell {
            let privacyPolicyURLString = "http://patchr.com/privacy"
            self.pushWebViewController(url: NSURL(string: privacyPolicyURLString) as URL?)
            Reporting.track("Viewed Privacy Policy")
        }
        else if selectedCell == self.softwareLicensesCell {
            let softwareLicensesURLString = "http://patchr.com/ios"
            self.pushWebViewController(url: NSURL(string: softwareLicensesURLString) as URL?)
            Reporting.track("Viewed Software Licenses")
        }
        else if selectedCell == self.developmentCell {
            let controller = DevelopmentViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.section == 0 && indexPath.row == 6 {
            if let user = UserController.instance.currentUser {
                if !user.developerValue {
                    developmentCell.isHidden = true
                    return CGFloat(0)
                }
            }
        }
        else if indexPath.section == 2 && indexPath.row == 0 {
            return CGFloat(64)
        }
        return CGFloat(44)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0: return self.notificationsCell
                    case 1: return self.sendFeedbackCell
                    case 2: return self.rateCell
                    case 3: return self.termsOfServiceCell
                    case 4: return self.privacyPolicyCell
                    case 5: return self.softwareLicensesCell
                    case 6: return self.developmentCell
                    default: fatalError("Unknown row in section 1")
                }
            case 1:
                switch (indexPath.row) {
                    case 0: return self.clearHistoryCell
                    case 1: return self.logoutCell
                    default: fatalError("Unknown row in section 2")
                }
            case 2:
                switch (indexPath.row) {
                    case 0: return self.buildInfoCell
                    default: fatalError("Unknown row in section 3")
                }
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "General".uppercased() : nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 48 : 24
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 7
            case 1: return 2
            case 2: return 1
            default: fatalError("Unknown number of sections")
        }
    }
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        switch result {
            case MFMailComposeResult.cancelled:    // 0
                UIShared.Toast(message: "Feedback cancelled", controller: self, addToWindow: false)
            case MFMailComposeResult.saved:        // 1
                UIShared.Toast(message: "Feedback saved", controller: self, addToWindow: false)
            case MFMailComposeResult.sent:        // 2
                Reporting.track("Sent Feedback")
                UIShared.Toast(message: "Feedback sent", controller: self, addToWindow: false)
            case MFMailComposeResult.failed:    // 3
                UIShared.Toast(message: "Feedback send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
                break
        }

        self.dismiss(animated: true) {
            MailComposer = nil
            MailComposer = MFMailComposeViewController()
        }
    }
}
