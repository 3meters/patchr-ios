//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI

class UserLobbyController: BaseViewController {
    
    var gradientImage: UIImage!
    var headingLabel: AirLabelTitle!
    var buttonLogin: AirButton!
    var buttonSignup: AirButton!
    var buttonGroup: UIView!
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillLayoutSubviews() {
        
        let headingSize = self.headingLabel.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))        
        self.headingLabel.anchorTopCenter(withTopPadding: 74, width: 288, height:  headingSize.height + 24)
        self.buttonGroup.anchorInCenter(withWidth: 240, height: 96)
        self.buttonSignup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 44)
        self.buttonLogin.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 44)
        
        super.viewWillLayoutSubviews()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        
        FireController.instance.isConnected() { connected in
            if connected == nil || !connected! {
                let message = "Creating a group requires a network connection."
                self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
            }
            else {
                let controller = GroupCreateController()
                let wrapper = AirNavigationController(rootViewController: controller)
                controller.flow = .internalCreate
                self.slideMenuController()?.closeLeft()
                self.present(wrapper, animated: true, completion: nil)
            }
        }
    }
    
    func switchLoginAction(sender: AnyObject?) {
        let controller = EmailViewController()
        controller.flow = .onboardLogin
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func logoutAction(sender: AnyObject?) {
        UserController.instance.logout()
        close(animated: true)
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
        
        self.headingLabel = AirLabelTitle()
        self.headingLabel.textAlignment = .center
        self.headingLabel.numberOfLines = 0
        self.headingLabel.text = "You are not currently a member of any Patchr group."

        self.buttonLogin = AirButton()
        self.buttonLogin.setTitle("Log in with another email", for: .normal)
        self.buttonLogin.addTarget(self, action: #selector(self.switchLoginAction(sender:)), for: .touchUpInside)
        self.buttonSignup = AirButton()
        self.buttonSignup.setTitle("Create a new Patchr group", for: .normal)
        self.buttonSignup.addTarget(self, action: #selector(self.addAction(sender:)), for: .touchUpInside)
        
        self.buttonGroup = UIView()
        self.buttonGroup.addSubview(self.buttonLogin)
        self.buttonGroup.addSubview(self.buttonSignup)
        
        self.view.addSubview(self.headingLabel)
        self.view.addSubview(self.buttonGroup)
        
        let logoutButton = UIBarButtonItem(title: "Log out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.logoutAction(sender:)))
        self.navigationItem.rightBarButtonItems = [logoutButton]
        self.navigationItem.hidesBackButton = true
    }
}
