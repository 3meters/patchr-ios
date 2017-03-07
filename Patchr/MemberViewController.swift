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
import Firebase
import FirebaseDatabase

class MemberViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    var inputUserId: String!
    
    var queryUser: UserQuery?
    var user: FireUser!

    var headerView = MemberDetailView()
    var email = AirLabelStack()
    var phone = AirLabelStack()
    var editButton = AirButton()
    var callButton = AirButton()
    var messageButton = AirButton()
    var buttonGroup = UIView()
    var profileGroup = UIView()
    
    var headerHeight: CGFloat!
    /*
     * Buttons
     * Logged in user: Message, Edit Profile
     * Other users: Message, Call, Options:
     */
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/
	
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        let groupId = StateController.instance.groupId!
        self.queryUser = UserQuery(userId: self.inputUserId, groupId: groupId)
        self.queryUser?.observe(with: { [weak self] error, user in
            self?.user = user
            self?.bind()
        })
    }
    
	override func viewWillLayoutSubviews() {
        
        let viewWidth = min(Config.contentWidthMax, self.view.bounds.size.width)
        let buttonWidth = (viewWidth - 48) / 2
        
        self.view.bounds.size.width = viewWidth
        self.contentHolder.bounds.size.width = viewWidth
        
        self.scrollView.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.bounds.height)

        self.buttonGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 8, height: self.buttonGroup.isHidden ? 0 : 56)
        self.callButton.anchorCenterLeft(withLeftPadding: 0, width: self.callButton.isHidden ? 0 : buttonWidth, height: 40)
        self.editButton.align(toTheRightOf: self.callButton, matchingCenterWithLeftPadding: 16, width: self.editButton.isHidden ? 0 : buttonWidth, height: 40)

        self.profileGroup.alignUnder(self.buttonGroup, matchingLeftAndRightFillingHeightWithTopPadding: 8, bottomPadding: 0)
        self.phone.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: self.phone.isHidden ? 0 : 64)
        self.email.alignUnder(self.phone, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: self.email.isHidden ? 0 : 64)
        
        self.contentHolder.resizeToFitSubviews()
        
        /* We want scroll bounce even if the content is too short */
        let contentHeight = max((self.scrollView.height() + self.scrollView.contentOffset.y), self.contentHolder.height())
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:contentHeight)
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: contentHeight)
	}
    
    deinit {
        self.queryUser?.remove()
    }
	
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func editAction(sender: AnyObject?) {
        let controller = ProfileEditViewController()
        let wrapper = AirNavigationController()
        wrapper.viewControllers = [controller]
        UIViewController.topMostViewController()?.present(wrapper, animated: true, completion: nil)
    }
    
    func emailAction(sender: AnyObject?) {
        
        if let email = self.user!.email {
            if MFMailComposeViewController.canSendMail() {
                Ui.mailComposer!.mailComposeDelegate = self
                Ui.mailComposer!.setToRecipients([email])
                self.present(Ui.mailComposer!, animated: true, completion: nil)
            }
            else {
                var emailURL = "mailto:\(email)"
                emailURL = emailURL.addingPercentEncoding(withAllowedCharacters: NSMutableCharacterSet.urlQueryAllowed) ?? emailURL
                if let url = URL(string: emailURL) {
                    UIApplication.shared.openURL(url as URL)
                }
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
    
    func closeAction(sender: AnyObject?) {
        close(animated: true)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Notifications
	*--------------------------------------------------------------------------------------------*/


	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
        
        self.automaticallyAdjustsScrollViewInsets = false
        let viewWidth = min(Config.contentWidthMax, self.view.bounds.size.width)
        self.headerHeight = viewWidth * 0.625
        self.scrollView.contentInset = UIEdgeInsets(top: self.headerHeight + 64, left: 0, bottom: 0, right: 0)
        self.scrollView.contentOffset = CGPoint(x: 0, y: -(self.headerHeight + 64))
        updateHeaderView()
        
        self.phone.caption.text = "Phone"
        self.phone.label.textColor = Colors.brandColorTextLight
        self.phone.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(phoneAction(sender:))))
        self.phone.isHidden = true

        self.email.caption.text = "Email"
        self.email.label.textColor = Colors.brandColorTextLight
        self.email.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(emailAction(sender:))))
        self.email.isHidden = true
        
        self.editButton.setTitle("Edit profile".uppercased(), for: .normal)
        self.editButton.addTarget(self, action: #selector(editAction(sender:)), for: .touchUpInside)
        self.callButton.setTitle("Call".uppercased(), for: .normal)
        self.callButton.addTarget(self, action: #selector(phoneAction(sender:)), for: .touchUpInside)
        
        self.buttonGroup.addSubview(self.editButton)
        self.buttonGroup.addSubview(self.callButton)
        self.profileGroup.addSubview(self.phone)
        self.profileGroup.addSubview(self.email)
        
        self.scrollView.addSubview(self.headerView)
        self.contentHolder.addSubview(self.buttonGroup)
        self.contentHolder.addSubview(self.profileGroup)
        
        self.scrollView.delegate = self
        
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
        }
	}
	
	func bind() {
        
        /* Push data into form and header */
        self.headerView.bind(user: self.user)   // Triggers layoutSubviews for header view
        
        self.editButton.isHidden = (self.user.id! != UserController.instance.userId!)
        self.callButton.isHidden = (self.user.profile?.phone?.isEmpty ?? true)
        self.buttonGroup.isHidden = (self.callButton.isHidden && self.editButton.isHidden)
        
        self.phone.isHidden = (self.user?.profile?.phone?.isEmpty ?? true)
        
        if self.user?.profile?.phone != nil {
            self.phone.label.text = self.user!.profile!.phone!
        }
        
        self.email.isHidden = true
        if self.user?.email != nil && !self.user!.email!.isEmpty {
            self.email.isHidden = false
            self.email.label.text = self.user!.email!
        }
        
        self.view?.setNeedsLayout() // Does NOT trigger layoutSubviews for header view
    }
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -self.headerHeight, width: self.view.width(), height: self.headerHeight)
        if self.scrollView.contentOffset.y < -(self.headerHeight + 64) {
            headerRect.origin.y = (self.scrollView.contentOffset.y + 64)
            headerRect.size.height = -(self.scrollView.contentOffset.y + 64)
        }
        self.headerView.frame = headerRect
    }
}

extension MemberViewController {
    /*
     * UITableViewDelegate
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
}

extension MemberViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		switch result {
			case MFMailComposeResult.cancelled:	// 0
				UIShared.toast(message: "Report cancelled", controller: self, addToWindow: false)
			case MFMailComposeResult.saved:		// 1
				UIShared.toast(message: "Report saved", controller: self, addToWindow: false)
			case MFMailComposeResult.sent:		// 2
				Reporting.track("Sent Report", properties: ["target":"Message" as AnyObject])
				UIShared.toast(message: "Report sent", controller: self, addToWindow: false)
			case MFMailComposeResult.failed:	// 3
				UIShared.toast(message: "Report send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
				break
		}
		
		self.dismiss(animated: true) {
			Ui.mailComposer = nil
			Ui.mailComposer = MFMailComposeViewController()
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
