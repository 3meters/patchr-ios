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

class InviteViewController: BaseEditViewController {
	
	var heading = AirLabelTitle()
    var message = AirLabelDisplay()
    
    var inviteReadersButton = AirButton()
	var inviteEditorsButton = AirButton()
    var inviteComment = AirLabelDisplay()

    var inputCode: String!
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
        
        self.inviteComment.bounds.size.width = Config.contentWidth
        self.inviteComment.sizeToFit()
        
		self.heading.anchorTopCenter(withTopPadding: 0, width: Config.contentWidth, height: headingSize.height)
        self.message.alignUnder(self.heading, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: messageSize.height)
        
		self.inviteReadersButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: Config.contentWidth, height: 48)
		self.inviteEditorsButton.alignUnder(self.inviteReadersButton, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
        self.inviteComment.alignUnder(self.inviteEditorsButton, matchingCenterWithTopPadding: 16, width: self.inviteComment.width(), height: self.inviteComment.height())

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
		
        self.heading.text = "Invite people to '\(self.inputChannelTitle!)'."
		self.heading.textAlignment = NSTextAlignment.center
		self.heading.numberOfLines = 0
        
        self.message.text = "An email invitation will be sent. Using the invitation will add them to the channel and help them install Teeny Social if they don't have it yet."
        self.message.textColor = Theme.colorTextSecondary
        self.message.textAlignment = .center
        self.message.numberOfLines = 0
        
        self.inviteReadersButton.setTitle("Invite readers".uppercased(), for: .normal)
        self.inviteReadersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
        self.inviteReadersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
        self.inviteReadersButton.rightPadding = 12
        self.inviteReadersButton.addTarget(self, action: #selector(inviteReadersAction(sender:)), for: .touchUpInside)
        
        self.inviteEditorsButton.setTitle("Invite contributors".uppercased(), for: .normal)
        self.inviteEditorsButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
        self.inviteEditorsButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
        self.inviteEditorsButton.rightPadding = 12
        self.inviteEditorsButton.addTarget(self, action: #selector(inviteEditorsAction(sender:)), for: .touchUpInside)
        
        self.inviteComment.text = "Contributors can post new messages. Both contributors and readers can browse and comment on posted messages."
        self.inviteComment.textColor = Theme.colorTextSecondary
        self.inviteComment.textAlignment = .center
        self.inviteComment.numberOfLines = 0
        
        self.contentHolder.addSubview(self.heading)
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.inviteReadersButton)
        self.contentHolder.addSubview(self.inviteEditorsButton)
        self.contentHolder.addSubview(self.inviteComment)
        
        if self.flow == .internalCreate {   // Invite to new channel
            let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {  // Invite to existing channel
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
	}

    func invite(role: String) {
        let controller = ContactPickerController()
        controller.flow = self.flow
        controller.inputRole = role
        controller.inputCode = self.inputCode
        controller.inputChannelId = self.inputChannelId
        controller.inputChannelTitle = self.inputChannelTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
