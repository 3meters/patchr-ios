
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


class SettingsTableViewController: UITableViewController {
	
	var progress: AirProgress?

    var notificationsCell		= AirTableViewCell()
    var sendFeedbackCell		= AirTableViewCell()
    var rateCell				= AirTableViewCell()
    var termsOfServiceCell		= AirTableViewCell()
    var privacyPolicyCell		= AirTableViewCell()
    var softwareLicensesCell	= AirTableViewCell()
    var developmentCell			= AirTableViewCell()
	var logoutCell				= AirTableViewCell()
	var clearHistoryCell		= AirTableViewCell()
	var buildInfoCell			= AirTableViewCell()

    var buildInfoLabel			= AirLabelDisplay()
	var logoutButton			= AirLinkButton()
	var clearHistoryButton		= AirLinkButton()
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
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
		Reporting.track("Cleared History")
		
		self.progress!.hide(true)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		Reporting.screen("Settings")
		
		self.navigationItem.title = "Settings"
		self.view.accessibilityIdentifier = View.Settings
		
		self.tableView = UITableView(frame: self.tableView.frame, style: .Grouped)
		self.tableView.accessibilityIdentifier = Table.Settings
		self.tableView.rowHeight = 48
		self.tableView.tableFooterView = UIView()
		self.tableView.backgroundColor = Colors.gray95pcntColor
		self.tableView.sectionFooterHeight = 0
		
		self.clearHistoryCell.contentView.addSubview(self.clearHistoryButton)
		self.logoutCell.contentView.addSubview(self.logoutButton)
		self.buildInfoCell.contentView.addSubview(self.buildInfoLabel)
		self.clearHistoryCell.accessoryType = .None
		self.logoutCell.accessoryType = .None
		self.buildInfoCell.accessoryType = .None

		let components = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: NSDate())
		self.buildInfoLabel.text = "©\(components.year) 3meters LLC\nVersion \(appVersion()) (\(build()))"
		self.buildInfoLabel.textColor = Theme.colorTextTitle
		self.buildInfoLabel.font = Theme.fontTextDisplay
		self.buildInfoLabel.numberOfLines = 2
		self.buildInfoLabel.textAlignment = .Center
		self.buildInfoCell.userInteractionEnabled = false
		
		if let user = UserController.instance.currentUser {
			if user.developerValue {
				developmentCell.hidden = false
				developmentCell.frame.size.height = 0
			}
		}
		
		self.notificationsCell.textLabel!.text = "Notifications"
		self.sendFeedbackCell.textLabel!.text = "Send feedback"
		self.rateCell.textLabel!.text = "Rate Patchr"
		self.termsOfServiceCell.textLabel!.text = "Terms of Service"
		self.privacyPolicyCell.textLabel!.text = "Privacy Policy"
		self.softwareLicensesCell.textLabel!.text = "Software Licenses"
		self.developmentCell.textLabel!.text = "Developer"
		
		self.notificationsCell.accessibilityIdentifier = Button.Notifications
		self.sendFeedbackCell.accessibilityIdentifier = Button.SendFeedback
		self.rateCell.accessibilityIdentifier = Button.RateApp
		self.termsOfServiceCell.accessibilityIdentifier = Button.TermsOfService
		self.privacyPolicyCell.accessibilityIdentifier = Button.PrivacyPolicy
		self.softwareLicensesCell.accessibilityIdentifier = Button.Licensing
		self.logoutCell.accessibilityIdentifier = Button.Logout
		self.clearHistoryCell.accessibilityIdentifier = Button.ClearHistory
		
		self.clearHistoryButton.setTitle("Clear search history".uppercaseString, forState: .Normal)
		self.logoutButton.setTitle("Log out".uppercaseString, forState: .Normal)
		
		self.logoutButton.addTarget(self, action: #selector(SettingsTableViewController.logoutAction(_:)), forControlEvents: .TouchUpInside)
		self.clearHistoryButton.addTarget(self, action: #selector(SettingsTableViewController.clearHistoryAction(_:)), forControlEvents: .TouchUpInside)		
	}
	
    func appVersion() -> String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "Unknown"
    }
    
    func build() -> String {
        return NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String ?? "Unknown"
    }
    
	func pushWebViewController(url: NSURL?, identifier: String?) -> Void {
        let webViewController = PBWebViewController()
		webViewController.view.accessibilityIdentifier = identifier
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
			let controller = NotificationSettingsViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
        else if selectedCell == self.sendFeedbackCell {
            let email = "feedback@patchr.com"
            let subject = "Feedback for Patchr iOS"
            if MFMailComposeViewController.canSendMail() {
				MailComposer!.view.accessibilityIdentifier = View.Feedback
                MailComposer!.mailComposeDelegate = self
                MailComposer!.setToRecipients([email])
                MailComposer!.setSubject(subject)
                self.presentViewController(MailComposer!, animated: true, completion: nil)
            }
			else {
                var emailURL = "mailto:\(email)"
                emailURL = emailURL.stringByAddingPercentEncodingWithAllowedCharacters(NSMutableCharacterSet.URLQueryAllowedCharacterSet()) ?? emailURL
                if let url = NSURL(string: emailURL) {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        else if selectedCell == self.rateCell {
            let appStoreURL = "itms-apps://itunes.apple.com/app/id\(APPLE_APP_ID)"
            if let url = NSURL(string: appStoreURL) {
                UIApplication.sharedApplication().openURL(url)
            }
			self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        else if selectedCell == self.termsOfServiceCell {
            let termsURLString = "http://patchr.com/terms"
            self.pushWebViewController(NSURL(string: termsURLString), identifier: View.TermsOfService)
			Reporting.track("Viewed Terms of Service")
        }
        else if selectedCell == self.privacyPolicyCell {
            let privacyPolicyURLString = "http://patchr.com/privacy"
            self.pushWebViewController(NSURL(string: privacyPolicyURLString), identifier: View.PrivacyPolicy)
			Reporting.track("Viewed Privacy Policy")
        }
        else if selectedCell == self.softwareLicensesCell {
            let softwareLicensesURLString = "http://patchr.com/ios"
            self.pushWebViewController(NSURL(string: softwareLicensesURLString), identifier: View.Licensing)
			Reporting.track("Viewed Software Licenses")
        }
        else if selectedCell == self.developmentCell {
			let controller = DevelopmentViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		
		if indexPath.section == 0 && indexPath.row == 6 {
			if let user = UserController.instance.currentUser {
				if !user.developerValue {
					developmentCell.hidden = true
					return CGFloat(0)
				}
			}
		}
		else if indexPath.section == 2 && indexPath.row == 0 {
			return CGFloat(64)
		}
		return CGFloat(44)
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		switch(indexPath.section) {
			case 0:
				switch(indexPath.row) {
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
				switch(indexPath.row) {
					case 0: return self.clearHistoryCell
					case 1: return self.logoutCell
					default: fatalError("Unknown row in section 2")
				}
			case 2:
				switch(indexPath.row) {
					case 0: return self.buildInfoCell
					default: fatalError("Unknown row in section 3")
				}
			default: fatalError("Unknown section")
		}
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == 0 ?  "General".uppercaseString : nil
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 0 ? 48 : 24
	}

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 3
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch(section) {
			case 0: return 7
			case 1: return 2
			case 2: return 1
			default: fatalError("Unknown number of sections")
		}
	}
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		
		switch result.rawValue {
		case MFMailComposeResultCancelled.rawValue:	// 0
			UIShared.Toast("Feedback cancelled", controller: self, addToWindow: false)
		case MFMailComposeResultSaved.rawValue:		// 1
			UIShared.Toast("Feedback saved", controller: self, addToWindow: false)
		case MFMailComposeResultSent.rawValue:		// 2
			Reporting.track("Sent Feedback")
			UIShared.Toast("Feedback sent", controller: self, addToWindow: false)
		case MFMailComposeResultFailed.rawValue:	// 3
			UIShared.Toast("Feedback send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
		default:
			break
		}
		
		self.dismissViewControllerAnimated(true) {
			MailComposer = nil
			MailComposer = MFMailComposeViewController()
		}
	}
}