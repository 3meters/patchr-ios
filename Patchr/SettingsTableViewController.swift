//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController {
    
    
    @IBOutlet weak var notificationsCell: UITableViewCell!
    @IBOutlet weak var sendFeedbackCell: UITableViewCell!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var termsOfServiceCell: UITableViewCell!
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    @IBOutlet weak var softwareLicensesCell: UITableViewCell!
    @IBOutlet weak var developmentCell: UITableViewCell!

    @IBOutlet weak var buildInformationLabel: UILabel!
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let components = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: NSDate())
        self.buildInformationLabel.text = "©\(components.year) 3meters LLC - Version \(appVersion()) (\(build()))"
        
        if let user = UserController.instance.currentUser {
            if user.developerValue {
                developmentCell.hidden = false
            }
        }
        
        self.notificationsCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.sendFeedbackCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.rateCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.termsOfServiceCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.privacyPolicyCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.softwareLicensesCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
        self.developmentCell.textLabel!.font = UIFont(name:"HelveticaNeue-Light", size: 18)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("Settings")
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func appVersion() -> String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "Unknown"
    }
    
    func build() -> String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? "Unknown"
    }
    
    func pushWebViewController(url: NSURL?) -> Void {
        let webViewController = PBWebViewController()
        webViewController.URL = url
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
}

extension SettingsTableViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        if selectedCell == self.notificationsCell {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("NotificationSettingsViewController") as? NotificationSettingsViewController {
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        else if selectedCell == self.sendFeedbackCell {
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
                emailURL = emailURL.stringByAddingPercentEncodingWithAllowedCharacters(NSMutableCharacterSet.URLQueryAllowedCharacterSet()) ?? emailURL
                if let url = NSURL(string: emailURL) {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        else if selectedCell == self.rateCell {
            let appId = "983436323"
            let appStoreURL = "itms-apps://itunes.apple.com/app/id\(appId)"
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            if let url = NSURL(string: appStoreURL) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        else if selectedCell == self.termsOfServiceCell {
            let termsURLString = "http://patchr.com/terms"
            self.pushWebViewController(NSURL(string: termsURLString))
        }
        else if selectedCell == self.privacyPolicyCell {
            let privacyPolicyURLString = "http://patchr.com/privacy"
            self.pushWebViewController(NSURL(string: privacyPolicyURLString))
        }
        else if selectedCell == self.softwareLicensesCell {
            let softwareLicensesURLString = "http://patchr.com/ios" // TODO: need real URL
            self.pushWebViewController(NSURL(string: softwareLicensesURLString))
        }
        else if selectedCell == self.developmentCell {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("DevelopmentViewController") as? DevelopmentViewController {
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        else {
            assert(false, "Unknown cell selection")
        }
    }
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
