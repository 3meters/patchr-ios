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
import Localize_Swift

class SettingsTableViewController: UITableViewController {

    var progress: AirProgress?

    /* Section 1: Global settings */
    var soundEffectsCell = AirTableViewCell()
    var languageCell = AirTableViewCell()
    
    /* Section 2: Informational */
    var sendFeedbackCell = AirTableViewCell()
    var rateCell = AirTableViewCell()
    var aboutCell = AirTableViewCell()
    var developmentCell = AirTableViewCell()

    /* Section 3: Actions */
    var clearHistoryCell = AirTableViewCell()
    var logoutCell = AirTableViewCell()

    var logoutButton = AirLinkButton()
    var clearHistoryButton = AirLinkButton()

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
        self.progress!.labelText = "progress_clearing".localized()
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

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        
        self.soundEffectsCell.accessoryView = makeSwitch(notificationType: .playSoundEffects
            , state: UserDefaults.standard.bool(forKey: PerUserKey(key: Prefs.soundEffects)))


        self.clearHistoryCell.contentView.addSubview(self.clearHistoryButton)
        self.logoutCell.contentView.addSubview(self.logoutButton)
        self.clearHistoryCell.accessoryType = .none
        self.logoutCell.accessoryType = .none
        
        self.logoutButton.addTarget(self, action: #selector(SettingsTableViewController.logoutAction(sender:)), for: .touchUpInside)
        self.clearHistoryButton.addTarget(self, action: #selector(SettingsTableViewController.clearHistoryAction(sender:)), for: .touchUpInside)
        
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        bindLanguage()
    }
    
    func bindLanguage() {
        self.navigationItem.title = "settings".localized()
        self.soundEffectsCell.textLabel!.text = "play_sound_effects".localized()
        self.languageCell.textLabel?.text = "settings_language_label".localized()
        self.languageCell.detailTextLabel?.text = Localize.displayNameForLanguage(Localize.currentLanguage())
        self.sendFeedbackCell.textLabel!.text = "send_feedback".localized()
        self.rateCell.textLabel!.text = "\("rate".localized()) \(Strings.appName)"
        self.aboutCell.textLabel!.text = "\("about".localized()) \(Strings.appName)"
        self.developmentCell.textLabel!.text = "developer".localized()
        self.clearHistoryButton.setTitle("clear_search_history".localized().uppercased(), for: .normal)
        self.logoutButton.setTitle("log_out".localized().uppercased(), for: .normal)
        self.tableView.reloadData()
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
            if switcher.tag == Setting.playSoundEffects.rawValue {
                Reporting.track(switcher.isOn ? "enable_sound_effects" : "disable_sound_effects")
                UserDefaults.standard.set(switcher.isOn, forKey: PerUserKey(key: Prefs.soundEffects))
            }
        }
    }
}

extension SettingsTableViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)
        
        if selectedCell == self.sendFeedbackCell {
            Reporting.track("view_feedback_compose")
            let email = "feedback@patchr.com"
            let subject = "\("feedback_subject".localized()) \(Strings.appName)"
            if MFMailComposeViewController.canSendMail() {
                UI.mailComposer!.mailComposeDelegate = self
                UI.mailComposer!.setToRecipients([email])
                UI.mailComposer!.setSubject(subject)
                self.present(UI.mailComposer!, animated: true, completion: nil)
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
        
        if selectedCell == self.languageCell {
            Reporting.track("view_language_settings")
            let controller = LanguageSettingsController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 1 && indexPath.row == 3 {
            developmentCell.isHidden = true
            if let developer = UserController.instance.user?.developer {
                if developer {
                    developmentCell.isHidden = false
                    return CGFloat(44)
                }
            }
            return CGFloat(0)
        }
        
        return CGFloat(44)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0: return self.soundEffectsCell
                    case 1: return self.languageCell
                    default: fatalError("Unknown row in section 1")
                }
            case 1:
                switch (indexPath.row) {
                    case 0: return self.sendFeedbackCell
                    case 1: return self.rateCell
                    case 2: return self.aboutCell
                    case 3: return self.developmentCell
                    default: fatalError("Unknown row in section 2")
                }
            case 2:
                switch (indexPath.row) {
                    case 0: return self.clearHistoryCell
                    case 1: return self.logoutCell
                    default: fatalError("Unknown row in section 3")
                }
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
            case 0: return "settings".localized().uppercased()
            case 1: return nil
            case 2: return nil
            default: fatalError("Unknown number of sections")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 48 : 24
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 2
            case 1: return 4
            case 2: return 2
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
                UIShared.toast(message: "feedback_cancelled".localized(), controller: self, addToWindow: false)
            case MFMailComposeResult.saved:        // 1
                Reporting.track("save_feedback")
                UIShared.toast(message: "feedback_saved".localized(), controller: self, addToWindow: false)
            case MFMailComposeResult.sent:        // 2
                Reporting.track("send_feedback")
                UIShared.toast(message: "feedback_sent".localized(), controller: self, addToWindow: false)
            case MFMailComposeResult.failed:    // 3
                UIShared.toast(message: "\("feedback_send_failure".localized()): \(error!.localizedDescription)", controller: self, addToWindow: false)
                break
        }

        self.dismiss(animated: true) {
            UI.mailComposer = nil
            UI.mailComposer = MFMailComposeViewController()
        }
    }
}
