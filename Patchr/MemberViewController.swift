//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI
import PhoneNumberKit
import Branch
import Firebase
import FirebaseDatabase

class MemberViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    var inputUserId: String!
    var ref: FIRDatabaseReference!
    var handle: UInt!
    var user: FireUser?

    var headerView = MemberDetailView()
    var email = AirLabelStack()
    var phone = AirLabelStack()
    var skype = AirLabelStack()
    var editButton = AirButton()
    var callButton = AirButton()
    var buttonGroup = UIView()
    var profileGroup = UIView()
    
    var originalRect: CGRect?
    var originalScrollTop = CGFloat(-64.0)
    var lastContentOffset = CGFloat(0)

	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/
	
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.handle = self.ref.observe(.value, with: { snap in
            if snap.value != nil {
                self.ref.onDisconnectUpdateChildValues(["presence":false])
                self.user = FireUser(dict: snap.value as! [String: Any], id: snap.key)
                self.bind()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ref.removeObserver(withHandle: self.handle)
    }
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
        
        let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
        let buttonWidth = (viewWidth - 48) / 2
        self.view.bounds.size.width = viewWidth
        self.contentHolder.bounds.size.width = viewWidth
        
        self.scrollView.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.bounds.height)
        self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: viewWidth * 0.625)
        
        self.buttonGroup.alignUnder(self.headerView, centeredFillingWidthWithLeftAndRightPadding: 16, topPadding: 8, height: self.buttonGroup.isHidden ? 0 : 56)
        self.callButton.anchorCenterLeft(withLeftPadding: 0, width: self.callButton.isHidden ? 0 : buttonWidth, height: 40)
        self.editButton.align(toTheRightOf: self.callButton, matchingCenterWithLeftPadding: 16, width: self.editButton.isHidden ? 0 : buttonWidth, height: 40)

        self.profileGroup.alignUnder(self.buttonGroup, matchingLeftAndRightFillingHeightWithTopPadding: 8, bottomPadding: 0)
        self.phone.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: self.phone.isHidden ? 0 : 64)
        self.email.alignUnder(self.phone, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: self.email.isHidden ? 0 : 64)
        self.skype.alignUnder(self.email, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: self.skype.isHidden ? 0 : 64)
        
        self.contentHolder.resizeToFitSubviews()
        
        /* We want scroll bounce even if the content is too short */
        let contentHeight = max((self.scrollView.height() + self.scrollView.contentOffset.y), self.contentHolder.height())
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:contentHeight)
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: contentHeight)
	}
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func editAction(sender: AnyObject?) {
        let controller = ProfileEditViewController()
        let navController = AirNavigationController()
        navController.viewControllers = [controller]
        self.navigationController?.present(navController, animated: true, completion: nil)
    }
    
    func emailAction(sender: AnyObject?) {
        let email = self.user!.profile!.email!
        if MFMailComposeViewController.canSendMail() {
            MailComposer!.mailComposeDelegate = self
            MailComposer!.setToRecipients([email])
            self.present(MailComposer!, animated: true, completion: nil)
        }
        else {
            var emailURL = "mailto:\(email)"
            emailURL = emailURL.addingPercentEncoding(withAllowedCharacters: NSMutableCharacterSet.urlQueryAllowed) ?? emailURL
            if let url = URL(string: emailURL) {
                UIApplication.shared.openURL(url as URL)
            }
        }
    }

    func phoneAction(sender: AnyObject?) {
        do {
            let phoneNumberKit = PhoneNumberKit()
            let phoneNumber = try phoneNumberKit.parse((self.user?.profile?.phone!)!)
            UIApplication.shared.openURL(URL(string: "tel://\(phoneNumber.adjustedNationalNumber())")!)
        }
        catch {
            Log.w("Invalid phone number: \(self.user?.profile?.phone!)")
        }
    }
    
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/


	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
        self.ref = FIRDatabase.database().reference().child("users/\(self.inputUserId!)")
        
        self.phone.caption.text = "Phone"
        self.phone.label.textColor = Colors.brandColorTextLight
        self.phone.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(phoneAction(sender:))))
        self.phone.isHidden = true

        self.email.caption.text = "Email"
        self.email.label.textColor = Colors.brandColorTextLight
        self.email.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(emailAction(sender:))))
        self.email.isHidden = true
        
        self.skype.caption.text = "Skype"
        self.skype.isHidden = true
        
        self.editButton.setTitle("Edit profile".uppercased(), for: .normal)
        self.editButton.addTarget(self, action: #selector(editAction(sender:)), for: .touchUpInside)
        self.callButton.setTitle("Call".uppercased(), for: .normal)
        self.callButton.addTarget(self, action: #selector(phoneAction(sender:)), for: .touchUpInside)
        
        self.buttonGroup.addSubview(self.editButton)
        self.buttonGroup.addSubview(self.callButton)
        self.profileGroup.addSubview(self.phone)
        self.profileGroup.addSubview(self.email)
        self.profileGroup.addSubview(self.skype)
        
        self.contentHolder.addSubview(self.headerView)
        self.contentHolder.addSubview(self.buttonGroup)
        self.contentHolder.addSubview(self.profileGroup)
        
        self.scrollView.delegate = self
	}
	
	func bind() {
        /* Push data into form and header */

        let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
        let viewHeight = viewWidth * 0.625
        self.originalRect = CGRect(x: -24, y: -36, width: viewWidth + 48, height: viewHeight + 72)
        
        self.headerView.bind(user: self.user)
        
        self.editButton.isHidden = (self.user?.id != UserController.instance.fireUserId)
        self.callButton.isHidden = (self.user?.profile?.phone == nil)
        self.buttonGroup.isHidden = (self.callButton.isHidden && self.editButton.isHidden)
        
        self.phone.isHidden = (self.user?.profile?.phone == nil)
        self.email.isHidden = (self.user?.profile?.email == nil)
        self.skype.isHidden = (self.user?.profile?.skype == nil)
        
        if self.user?.profile?.phone != nil {
            self.phone.label.text = self.user!.profile!.phone!
        }
        
        if self.user?.profile?.email != nil {
            self.email.label.text = self.user!.profile!.email!
        }
        
        if self.user?.profile?.skype != nil {
            self.skype.label.text = self.user!.profile!.skype!
        }
        self.view?.setNeedsLayout()
    }
}

extension MemberViewController {
    /*
     * UITableViewDelegate
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        self.lastContentOffset = scrollView.contentOffset.y
        
        /* Parallax effect when user scrolls down */
        let offset = scrollView.contentOffset.y
        if self.originalRect != nil && offset >= self.originalScrollTop && offset <= 300 {
            let movement = self.originalScrollTop - scrollView.contentOffset.y
            let ratio: CGFloat = (movement <= 0) ? 0.50 : 1.0
            self.headerView.photo.frame.origin.y = self.originalRect!.origin.y + (-(movement) * ratio)
        }
        else {
            let movement = (originalScrollTop - scrollView.contentOffset.y) * 0.35
            if movement > 0 {
                self.headerView.photo.frame.origin.y = self.originalRect!.origin.y - (movement * 0.5)
                self.headerView.photo.frame.origin.x = self.originalRect!.origin.x - (movement * 0.5)
                self.headerView.photo.frame.size.width = self.originalRect!.size.width + movement
                self.headerView.photo.frame.size.height = self.originalRect!.size.height + movement
            }
        }
    }    
}

extension MemberViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		switch result {
			case MFMailComposeResult.cancelled:	// 0
				UIShared.Toast(message: "Report cancelled", controller: self, addToWindow: false)
			case MFMailComposeResult.saved:		// 1
				UIShared.Toast(message: "Report saved", controller: self, addToWindow: false)
			case MFMailComposeResult.sent:		// 2
				Reporting.track("Sent Report", properties: ["target":"Message" as AnyObject])
				UIShared.Toast(message: "Report sent", controller: self, addToWindow: false)
			case MFMailComposeResult.failed:	// 3
				UIShared.Toast(message: "Report send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
				break
		}
		
		self.dismiss(animated: true) {
			MailComposer = nil
			MailComposer = MFMailComposeViewController()
		}
	}
}

class MemberItem: NSObject, UIActivityItemSource {
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return ""
    }
}
