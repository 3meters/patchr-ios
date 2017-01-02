//
//  InviteViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-17.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Branch
import MessageUI
import Firebase
import FirebaseAuth

class InviteViewController: BaseEditViewController {
	
	var message	= AirLabelTitle()
	var inviteMembersButton = AirButton()
    var inviteMembersComment = AirLabelDisplay()
	var inviteGuestsButton = AirButton()
    var inviteGuestsComment = AirLabelDisplay()
    var channelField = AirTextField()

    var channel: FireChannel!
    var inputGroupId: String?
    var inputGroupTitle: String?
    
    var validateFor = "member"
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let inviteMembersCommentSize = self.inviteMembersComment.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let inviteGuestsCommentSize = self.inviteGuestsComment.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
		
		self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
		self.inviteMembersButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 288, height: 48)
        self.inviteMembersComment.alignUnder(self.inviteMembersButton, matchingCenterWithTopPadding: 12, width: 288, height: inviteMembersCommentSize.height)
		self.inviteGuestsButton.alignUnder(self.inviteMembersComment, matchingCenterWithTopPadding: 20, width: 288, height: 48)
        self.channelField.alignUnder(self.inviteGuestsButton, matchingCenterWithTopPadding: 12, width: 288, height: 48)
        self.inviteGuestsComment.alignUnder(self.channelField, matchingCenterWithTopPadding: 12, width: 280, height: inviteGuestsCommentSize.height)
		
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
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func doneAction(sender: AnyObject?) {
        let groupId = self.inputGroupId!
        FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
            if firstChannelId != nil {
                StateController.instance.setChannelId(channelId: firstChannelId!, groupId: groupId)
                MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                let _ = self.navigationController?.popToRootViewController(animated: false)
                self.close()
            }
        }
    }
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
		
		Reporting.screen("PatchInvite")
		
        if self.flow != .onboardCreate {
            self.message.text = "Invite people to \(StateController.instance.group.title!)."
        }
        else {
            self.message.text = "Invite people to \(self.inputGroupTitle!)."
        }
        
		self.message.textAlignment = NSTextAlignment.center
		self.message.numberOfLines = 0
        
        if self.flow == .onboardCreate {
            /*
             * Invite dialog doesn't show if user is already a member or pending.
             */
            self.inviteMembersButton.setTitle("Invite Members".uppercased(), for: .normal)
            self.inviteMembersComment.text = "An email invitation will be sent to your selected contacts. Accepting the invitation will add them as members of your group and help them install Patchr if they don't have it yet."
            self.inviteMembersComment.textColor = Theme.colorTextSecondary
            self.inviteMembersComment.textAlignment = .center
            self.inviteMembersComment.numberOfLines = 0
            self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
            
            let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
            
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteMembersButton)
            self.contentHolder.addSubview(self.inviteMembersComment)
        }
        else {
            /*
             * Invite dialog doesn't show if user is already a member or pending.
             */
            self.inviteMembersButton.setTitle("Invite Members".uppercased(), for: .normal)
            self.inviteMembersComment.text = "Members can partipate in any open channel and access the full group directory."
            self.inviteMembersComment.textColor = Theme.colorTextSecondary
            self.inviteMembersComment.textAlignment = .center
            self.inviteMembersComment.numberOfLines = 0
            self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
            
            self.inviteGuestsButton.setTitle("Invite Guests".uppercased(), for: .normal)
            self.inviteGuestsComment.text = "Guests can only partipate in selected channels."
            self.inviteGuestsComment.textColor = Theme.colorTextSecondary
            self.inviteGuestsComment.textAlignment = .center
            self.inviteGuestsComment.numberOfLines = 0
            
            self.inviteGuestsButton.addTarget(self, action: #selector(inviteGuestsAction(sender:)), for: .touchUpInside)
            
            self.channelField.setPlaceholder("Select a channel", floatingTitle: "Selected channel")
            self.channelField.floatingLabel.textAlignment = .center
            self.channelField.textAlignment = .center
            self.channelField.textColor = Colors.accentColorDark
            self.channelField.delegate = self
            self.channelField.keyboardType = .default
            self.channelField.autocapitalizationType = .none
            self.channelField.autocorrectionType = .no
            self.channelField.returnKeyType = .default
            self.channelField.isUserInteractionEnabled = false
            
            if let groupId = StateController.instance.groupId, let channelId = StateController.instance.channelId {
                let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: nil)
                channelQuery.once(with: { channel in
                    if channel != nil {
                        self.channel = channel
                        self.channelField.text = channel?.name
                    }
                })
            }
            
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteMembersButton)
            self.contentHolder.addSubview(self.inviteMembersComment)
            self.contentHolder.addSubview(self.inviteGuestsButton)
            self.contentHolder.addSubview(self.inviteGuestsComment)
            self.contentHolder.addSubview(self.channelField)
            
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
        }
	}
    
    func inviteMembers() {
        let controller = ContactPickerController()
        controller.role = "members"
        controller.flow = self.flow
        controller.inputGroupId = self.inputGroupId
        controller.inputGroupTitle = self.inputGroupTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func inviteGuests() {
        let controller = ContactPickerController()
        controller.role = "guests"
        controller.flow = self.flow
        controller.channel = self.channel
        controller.inputGroupId = self.inputGroupId
        controller.inputGroupTitle = self.inputGroupTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func isValid() -> Bool {
        if self.validateFor == "guests" {
            if self.channelField.isEmpty {
                Alert(title: "Select a channel")
                return false
            }
            /* Check for channel that exists */
        }
        return true
    }
}

extension InviteViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case MFMailComposeResult.cancelled:    // 0
            UIShared.Toast(message: "Invites cancelled", controller: self, addToWindow: false)
        case MFMailComposeResult.saved:        // 1
            UIShared.Toast(message: "Invites saved", controller: self, addToWindow: false)
        case MFMailComposeResult.sent:        // 2
            Reporting.track("Sent Invites")
            UIShared.Toast(message: "Invites sent", controller: self, addToWindow: false)
            if self.flow == .onboardCreate {
                doneAction(sender: nil)
            }
        case MFMailComposeResult.failed:    // 3
            UIShared.Toast(message: "Invites send failure: \(error!.localizedDescription)", controller: self, addToWindow: false)
            break
        }
        
        self.dismiss(animated: true) {
            MailComposer = nil
            MailComposer = MFMailComposeViewController()
        }
    }
}
