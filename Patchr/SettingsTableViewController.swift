//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    
    @IBOutlet weak var notificationsTableViewCell: UITableViewCell!
    @IBOutlet weak var sendFeedbackTableViewCell: UITableViewCell!
    @IBOutlet weak var rateTableViewCell: UITableViewCell!
    @IBOutlet weak var termsOfServiceTableViewCell: UITableViewCell!
    @IBOutlet weak var privacyPolicyTableViewCell: UITableViewCell!
    @IBOutlet weak var softwareLicensesTableViewCell: UITableViewCell!
    @IBOutlet weak var developmentTableViewCell: UITableViewCell!

    @IBOutlet weak var buildInformationLabel: UILabel!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let components = NSCalendar.currentCalendar().components(.YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit, fromDate: NSDate())
        self.buildInformationLabel.text = "©\(components.year) 3meters. Version \(appVersion()) (\(build()))"
        
        if let user = UserController.instance.currentUser {
            if user.developerValue {
                developmentTableViewCell.hidden = false
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func appVersion() -> String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "Unknown"
    }
    
    func build() -> String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("kCFBundleVersionKey") as? String ?? "Unknown"
    }
    
    func pushWebViewController(url: NSURL?) -> Void {
        let webViewController = PBWebViewController()
        webViewController.URL = url
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
}

extension SettingsTableViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        if selectedCell == self.notificationsTableViewCell {
            self.performSegueWithIdentifier("NotificationSettingsSegue", sender: selectedCell)
        }
        else if selectedCell == self.sendFeedbackTableViewCell {
            let email = "feedback@3meters.com"
            let subject = "Feedback for Patchr iOS"
            if MFMailComposeViewController.canSendMail() {
                let composeViewController = MFMailComposeViewController()
                composeViewController.mailComposeDelegate = self
                composeViewController.setToRecipients([email])
                composeViewController.setSubject(subject)
                self.presentViewController(composeViewController, animated: true, completion: nil)
            } else {
                var emailURL = "mailto:\(email)"
                emailURL = emailURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) ?? emailURL
                if let url = NSURL(string: emailURL) {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        else if selectedCell == self.rateTableViewCell {
            let appId = "1234567890"
            let appStoreURL = "itms-apps://itunes.apple.com/app/id\(appId)"
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            if let url = NSURL(string: appStoreURL) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        else if selectedCell == self.termsOfServiceTableViewCell {
            let termsURLString = "http://patchr.com/terms"
            self.pushWebViewController(NSURL(string: termsURLString))
        }
        else if selectedCell == self.privacyPolicyTableViewCell {
            let privacyPolicyURLString = "http://patchr.com/privacy"
            self.pushWebViewController(NSURL(string: privacyPolicyURLString))
        }
        else if selectedCell == self.softwareLicensesTableViewCell {
            let softwareLicensesURLString = "http://patchr.com/android" // TODO: need real URL
            self.pushWebViewController(NSURL(string: softwareLicensesURLString))
        }
        else if selectedCell == self.developmentTableViewCell {
            self.performSegueWithIdentifier("DevelopmentSettingsSegue", sender: selectedCell)
        }
        else {
            assert(false, "Unknown cell selection")
        }
    }
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
