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
    
	var inviteMembersButton = AirButton()
    var inviteMembersComment = AirLabelDisplay()
	var inviteGuestsButton = AirButton()
    var inviteGuestsComment = AirLabelDisplay()
    var inviteListButton = AirLinkButton()

    var channels: [String: Any] = [:]
    var inputChannelId: String!
    var inputChannelName: String!
    var inputAsOwner = false
    
    var validateFor = "member"
	
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
        
		self.inviteGuestsButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: Config.contentWidth, height: 48)
		self.inviteMembersButton.alignUnder(self.inviteGuestsButton, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
        self.inviteListButton.alignUnder(self.inviteMembersButton, matchingCenterWithTopPadding: 16, width: Config.contentWidth, height: 48)
		
        super.viewWillLayoutSubviews()
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
	func inviteMembersAction(sender: AnyObject?) {
        self.validateFor = "members"
		inviteMembers()
	}
	
	func inviteGuestsAction(sender: AnyObject?) {
        self.validateFor = "guests"
		inviteGuests()
	}
    
    func inviteListAction(sender: AnyObject?) {
        inviteList()
    }
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func doneAction(sender: AnyObject?) {
        /* Only called if part of channel create flow */
        let groupId = StateController.instance.groupId!
        let channelId = self.inputChannelId!
        StateController.instance.setChannelId(channelId: channelId, groupId: groupId) // We know it's good
        MainController.instance.showChannel(channelId: channelId, groupId: groupId)
        self.close(animated: true)
    }
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
        self.channels[self.inputChannelId] = self.inputChannelName
        
        self.heading.text = "Invite people to #\(self.inputChannelName!)."
		self.heading.textAlignment = NSTextAlignment.center
		self.heading.numberOfLines = 0
        
        self.message.text = "An email invitation will be sent. Using the invitation will add them to the channel and help them install Patchr if they don't have it yet."
        self.message.textColor = Theme.colorTextSecondary
        self.message.textAlignment = .center
        self.message.numberOfLines = 0
        
        if self.flow == .internalCreate {
            
            self.inviteGuestsButton.setTitle("Invite contacts as guests".uppercased(), for: .normal)
            self.inviteGuestsButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteGuestsButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteGuestsButton.rightPadding = 12
            self.inviteGuestsButton.addTarget(self, action: #selector(inviteGuestsAction(sender:)), for: .touchUpInside)
            
            self.inviteMembersButton.setTitle("Invite group members".uppercased(), for: .normal)
            self.inviteMembersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteMembersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteMembersButton.rightPadding = 12
            self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
            
            self.contentHolder.addSubview(self.heading)
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteGuestsButton)
            self.contentHolder.addSubview(self.inviteMembersButton)
            
            let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            
            self.inviteGuestsButton.setTitle("Invite contacts as guests".uppercased(), for: .normal)
            self.inviteGuestsButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteGuestsButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteGuestsButton.rightPadding = 12
            self.inviteGuestsButton.addTarget(self, action: #selector(inviteGuestsAction(sender:)), for: .touchUpInside)
            
            self.inviteMembersButton.setTitle("Invite group members".uppercased(), for: .normal)
            self.inviteMembersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteMembersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteMembersButton.rightPadding = 12
            self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
            
            self.inviteListButton.setTitle("Pending invites".uppercased(), for: .normal)
            self.inviteListButton.addTarget(self, action: #selector(inviteListAction(sender:)), for: .touchUpInside)
            
            self.contentHolder.addSubview(self.heading)
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteGuestsButton)
            self.contentHolder.addSubview(self.inviteMembersButton)
            self.contentHolder.addSubview(self.inviteListButton)
            
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
	}
    
    func inviteList() {
        let controller = InviteListController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func inviteGuests() {
        let controller = ContactPickerController()
        controller.flow = self.flow
        controller.inputRole = "guests"
        controller.inputChannelId = self.inputChannelId
        controller.inputChannelName = self.inputChannelName
        controller.inputGroupId = StateController.instance.groupId!
        controller.inputGroupTitle = StateController.instance.group.title
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func inviteMembers() {
        let controller = MemberPickerController()
        controller.flow = self.flow
        controller.inputAsOwner = self.inputAsOwner
        controller.inputChannelId = self.inputChannelId
        controller.inputChannelName = self.inputChannelName
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
