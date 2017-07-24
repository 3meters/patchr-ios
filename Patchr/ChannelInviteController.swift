//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Branch
import MessageUI
import Firebase
import FirebaseAuth
import CLTokenInputView

protocol PickerDelegate {
    func update(channels: [String: Any])
}

class ChannelInviteController: BaseEditViewController {
	
	var heading = AirLabelTitle()
    var message = AirLabelDisplay()
    
	var inviteEditorsButton = AirButton()
    var inviteEditorsComment = AirLabelDisplay()
	var inviteReadersButton = AirButton()
    var inviteReadersComment = AirLabelDisplay()

    var inputChannelId: String!
    var inputChannelTitle: String!
    var inputAsOwner = false
    
    var validateFor = "reader"
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		
        let headingSize = self.heading.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))
        let messageSize = self.message.sizeThatFits(CGSize(width: Config.contentWidth, height:CGFloat.greatestFiniteMagnitude))
        
		self.heading.anchorTopCenter(withTopPadding: 0, width: Config.contentWidth, height: headingSize.height)
        self.message.alignUnder(self.heading, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: messageSize.height)
        
		self.inviteReadersButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: Config.contentWidth, height: 48)
		self.inviteEditorsButton.alignUnder(self.inviteReadersButton, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)

        super.viewWillLayoutSubviews()
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func inviteReadersAction(sender: AnyObject?) {
        self.validateFor = "readers"
        invite(role: "reader")
	}
	
	func inviteEditorsAction(sender: AnyObject?) {
        self.validateFor = "editors"
        invite(role: "editor")
	}
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func doneAction(sender: AnyObject?) {
        /* Only called if part of channel create flow */
        let channelId = self.inputChannelId!
        StateController.instance.setChannelId(channelId: channelId) // We know it's good
        MainController.instance.showChannel(channelId: channelId)
        self.close(animated: true)
    }
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
        self.heading.text = "Invite people to #\(self.inputChannelTitle!)."
		self.heading.textAlignment = NSTextAlignment.center
		self.heading.numberOfLines = 0
        
        self.message.text = "An email invitation will be sent. Using the invitation will add them to the channel and help them install Patchr if they don't have it yet."
        self.message.textColor = Theme.colorTextSecondary
        self.message.textAlignment = .center
        self.message.numberOfLines = 0
        
        if self.flow == .internalCreate {
            
            self.inviteReadersButton.setTitle("Invite contacts as readers".uppercased(), for: .normal)
            self.inviteReadersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteReadersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteReadersButton.rightPadding = 12
            self.inviteReadersButton.addTarget(self, action: #selector(inviteReadersAction(sender:)), for: .touchUpInside)
            
            self.inviteEditorsButton.setTitle("Invite contacts as editors".uppercased(), for: .normal)
            self.inviteEditorsButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteEditorsButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteEditorsButton.rightPadding = 12
            self.inviteEditorsButton.addTarget(self, action: #selector(inviteEditorsAction(sender:)), for: .touchUpInside)
            
            self.contentHolder.addSubview(self.heading)
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteReadersButton)
            self.contentHolder.addSubview(self.inviteEditorsButton)
            
            let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            
            self.inviteReadersButton.setTitle("Invite contacts as readers".uppercased(), for: .normal)
            self.inviteReadersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteReadersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteReadersButton.rightPadding = 12
            self.inviteReadersButton.addTarget(self, action: #selector(inviteReadersAction(sender:)), for: .touchUpInside)
            
            self.inviteEditorsButton.setTitle("Invite contacts as editors".uppercased(), for: .normal)
            self.inviteEditorsButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteEditorsButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteEditorsButton.rightPadding = 12
            self.inviteEditorsButton.addTarget(self, action: #selector(inviteEditorsAction(sender:)), for: .touchUpInside)

            self.contentHolder.addSubview(self.heading)
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteReadersButton)
            self.contentHolder.addSubview(self.inviteEditorsButton)

            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
	}

    func invite(role: String) {
        let controller = ContactPickerController()
        controller.flow = self.flow
        controller.inputRole = role
        controller.inputChannelId = self.inputChannelId
        controller.inputChannelTitle = self.inputChannelTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
