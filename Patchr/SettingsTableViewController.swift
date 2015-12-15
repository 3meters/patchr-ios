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
	
	var progress: AirProgress?

    @IBOutlet weak var notificationsCell: UITableViewCell!
    @IBOutlet weak var sendFeedbackCell: UITableViewCell!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var termsOfServiceCell: UITableViewCell!
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    @IBOutlet weak var softwareLicensesCell: UITableViewCell!
    @IBOutlet weak var developmentCell: UITableViewCell!

    @IBOutlet weak var buildInformationLabel: UILabel!
	@IBOutlet weak var logoutButton: AirButtonLink!
	@IBOutlet weak var clearHistoryButton: AirButtonLink!
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let components = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: NSDate())
        self.buildInformationLabel.text = "©\(components.year) 3meters LLC - Version \(appVersion()) (\(build()))"
		self.buildInformationLabel.textColor = Theme.colorTextTitle
		self.buildInformationLabel.font = Theme.fontTextDisplay
        
        if let user = UserController.instance.currentUser {
            if user.developerValue {
                developmentCell.hidden = false
            }
        }
        
        self.notificationsCell.textLabel!.font = Theme.fontTextDisplay
        self.sendFeedbackCell.textLabel!.font = Theme.fontTextDisplay
        self.rateCell.textLabel!.font = Theme.fontTextDisplay
        self.termsOfServiceCell.textLabel!.font = Theme.fontTextDisplay
        self.privacyPolicyCell.textLabel!.font = Theme.fontTextDisplay
        self.softwareLicensesCell.textLabel!.font = Theme.fontTextDisplay
        self.developmentCell.textLabel!.font = Theme.fontTextDisplay
		
		self.logoutButton.addTarget(self, action: Selector("logoutAction:"), forControlEvents: .TouchUpInside)
		self.clearHistoryButton.addTarget(self, action: Selector("clearHistoryAction:"), forControlEvents: .TouchUpInside)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("Settings")
    }
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self.logoutButton.fillSuperview()
		self.clearHistoryButton.fillSuperview()
		self.buildInformationLabel.fillSuperview()
	}
	
	func logoutAction(sender: AnyObject) {
		
		self.progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		self.progress!.mode = MBProgressHUDMode.Indeterminate
		self.progress!.styleAs(.ActivityWithText)
		self.progress!.minShowTime = 0.5
		self.progress!.labelText = "Logging out..."
		self.progress!.removeFromSuperViewOnHide = true
		self.progress!.show(true)
		
		UserController.instance.signout()	// Blocks until finished
	}
	
	func clearHistoryAction(sender: AnyObject) {
		
		self.progress = AirProgress.showHUDAddedTo(self.view.window, animated: true)
		self.progress!.mode = MBProgressHUDMode.Indeterminate
		self.progress!.styleAs(.ActivityWithText)
		self.progress!.minShowTime = 0.5
		self.progress!.labelText = "Clearing..."
		self.progress!.removeFromSuperViewOnHide = true
		self.progress!.show(true)
		
		Utils.clearHistory()
		
		self.progress!.hide(true)
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
    }
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
