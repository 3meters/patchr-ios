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
import Localize_Swift

class MemberViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    var inputUserId: String!
    
    var authHandle: AuthStateDidChangeListenerHandle!
    var queryUser: UserQuery!
    var user: FireUser!
    
    var chromeBackground = UIView(frame: .zero)
    var headerView = MemberDetailView()
    var email = AirLabelStack()
    var phone = AirLabelStack()
    var settingsButton = AirButton()
    var editButton = AirButton()
    var callButton = AirButton()
    var messageButton = AirButton()
    var buttonGroup = UIView()
    var profileGroup = UIView()
    
    var headerHeight: CGFloat!
    var authenticatedUser = false
    /*
     * Buttons
     * Logged in user: Message, Edit Profile
     * Other users: Message, Call, Options:
     */
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/
	
    init(userId: String?) {
        self.inputUserId = userId
        super.init(nibName: nil, bundle: nil) // Must call designated inititializer for super class
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("NSCoding (storyboards) not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        UIShared.styleChrome(navigationBar: (self.navigationController?.navigationBar)!, translucent: true)
        if let navigationController = self.navigationController as? AirNavigationController {
            navigationController.statusBarView.backgroundColor = Colors.clear
        }

        let userId = self.inputUserId!
        self.queryUser = UserQuery(userId: userId)
        self.queryUser?.observe(with: { [weak self] error, user in
            guard let this = self else { return }
            this.user = user
            this.bind()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = .default
        if self.isMovingFromParentViewController {
            UIShared.styleChrome(navigationBar: self.navigationController!.navigationBar, translucent: false)
        }
    }
    
	override func viewWillLayoutSubviews() {
        
        /* view -> scrollView -> contentHolder -> buttonGroup/profileGroup
           view -> scrollView -> header
           view -> chromeBackground */

        let viewWidth = min(Config.contentWidthMax, self.view.bounds.size.width)
        let buttonWidth = (viewWidth - 48) / 2
        
        self.chromeBackground.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 64)

        self.contentHolder.bounds.size.width = viewWidth
        
        self.scrollView.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.bounds.height)
        self.buttonGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 8, height: self.buttonGroup.isHidden ? 0 : 56)
        
        if self.authenticatedUser {
            self.settingsButton.anchorCenterLeft(withLeftPadding: 0, width: buttonWidth, height: 40)
            self.editButton.align(toTheRightOf: self.settingsButton, matchingCenterWithLeftPadding: 16, width: self.editButton.isHidden ? 0 : buttonWidth, height: 40)
        }
        else {
            self.callButton.anchorCenterLeft(withLeftPadding: 0, width: self.callButton.isHidden ? 0 : buttonWidth, height: 40)
            self.editButton.align(toTheRightOf: self.callButton, matchingCenterWithLeftPadding: 16, width: self.editButton.isHidden ? 0 : buttonWidth, height: 40)
        }

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
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/
    
    func editAction(sender: AnyObject?) {
        Reporting.track("view_profile_edit")
        let controller = ProfileEditViewController()
        let wrapper = AirNavigationController()
        wrapper.viewControllers = [controller]
        UIViewController.topController?.present(wrapper, animated: true, completion: nil)
    }
    
    func settingsAction(sender: AnyObject?) {
        Reporting.track("view_settings")
        let controller = SettingsTableViewController()
        let wrapper = AirNavigationController(rootViewController: controller)
        UIViewController.topController?.present(wrapper, animated: true, completion: nil)
    }
    
    func phoneAction(sender: AnyObject?) {
        do {
            Reporting.track("call_member")
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
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	/*--------------------------------------------------------------------------------------------
	* MARK: - Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
        
        self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
            guard let this = self else { return }
            if user == nil {
                this.close(animated: true)
            }
        }
        
        if let navigationBar = self.navigationController?.navigationBar {
            UIShared.styleChrome(navigationBar: navigationBar, translucent: true)
        }
        
        self.view.backgroundColor = Theme.colorBackgroundWindow
        self.automaticallyAdjustsScrollViewInsets = false
        let viewWidth = min(Config.contentWidthMax, self.view.bounds.size.width)

        self.headerHeight = viewWidth * 0.625
        self.scrollView.contentInset = UIEdgeInsets(top: self.headerHeight, left: 0, bottom: 0, right: 0)
        self.scrollView.contentOffset = CGPoint(x: 0, y: -(self.headerHeight))

        updateHeaderView()

        self.phone.label.textColor = Colors.brandColorTextLight
        self.phone.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(phoneAction(sender:))))
        self.phone.isHidden = true

        self.email.label.textColor = Colors.brandColorTextLight
        self.email.isHidden = true

        self.editButton.addTarget(self, action: #selector(editAction(sender:)), for: .touchUpInside)
        self.settingsButton.addTarget(self, action: #selector(settingsAction(sender:)), for: .touchUpInside)
        self.callButton.addTarget(self, action: #selector(phoneAction(sender:)), for: .touchUpInside)
        
        self.chromeBackground.backgroundColor = Colors.accentColor

        self.buttonGroup.addSubview(self.editButton)
        self.buttonGroup.addSubview(self.callButton)
        self.buttonGroup.addSubview(self.settingsButton)
        self.profileGroup.addSubview(self.phone)
        self.profileGroup.addSubview(self.email)
        
        /* Base class adds contentHolder to scrollView and scrollView to view */
        self.scrollView.addSubview(self.headerView)
        self.contentHolder.addSubview(self.buttonGroup)
        self.contentHolder.addSubview(self.profileGroup)
        self.view.addSubview(self.chromeBackground)
        self.view.sendSubview(toBack: self.chromeBackground)
        
        self.scrollView.delegate = self
        self.authenticatedUser = (self.inputUserId == UserController.instance.userId)
        
        self.headerView.setPhotoButton.addTarget(self, action: #selector(editAction(sender:)), for: .touchUpInside)
        
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
            closeButton.tintColor = Colors.white
            self.navigationItem.leftBarButtonItems = [closeButton]
        }

        NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        bindLanguage()
	}

    func bindLanguage() {
        self.phone.caption.text = "phone".localized()
        self.phone.setNeedsLayout()
        self.email.caption.text = "email".localized()
        self.email.setNeedsLayout()
        self.editButton.setTitle("edit_profile".localized().uppercased(), for: .normal)
        self.settingsButton.setTitle("settings".localized().uppercased(), for: .normal)
        self.callButton.setTitle("call".localized().uppercased(), for: .normal)
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
        
        if self.user.id! == UserController.instance.userId! {
            if self.user.profile?.photo == nil {
                self.headerView.setPhotoButton.fadeIn()
            }
            else {
                self.headerView.setPhotoButton.fadeOut()
            }
        }
        
        self.email.isHidden = true
        if self.authenticatedUser {
            if let email = Auth.auth().currentUser?.email! {
                self.email.isHidden = false
                self.email.label.text = email
            }
        }
        
        self.view?.setNeedsLayout() // Does NOT trigger layoutSubviews for header view
        updateHeaderView()
    }
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -self.headerHeight, width: self.contentHolder.width(), height: self.headerHeight)
        if self.scrollView.contentOffset.y < -(self.headerHeight) {
            headerRect.origin.y = (self.scrollView.contentOffset.y)
            headerRect.size.height = -(self.scrollView.contentOffset.y)
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
