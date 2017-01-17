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
import CLTokenInputView

protocol PickerDelegate {
    func update(channels: [String: Any])
}

class InviteViewController: BaseEditViewController {
	
	var message	= AirLabelTitle()
	var inviteMembersButton = AirButton()
    var inviteMembersComment = AirLabelDisplay()
	var inviteGuestsButton = AirButton()
    var inviteGuestsLabel = AirLabelDisplay()
    var channelButton = AirButton()
    var inviteGuestsComment = AirLabelDisplay()
    var inviteListButton = AirLinkButton()

    var channels: [String: Any] = [:]
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
        
        self.channelButton.sizeToFit()
		
		self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
		self.inviteMembersButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 288, height: 48)
        self.inviteMembersComment.alignUnder(self.inviteMembersButton, matchingCenterWithTopPadding: 12, width: 288, height: inviteMembersCommentSize.height)
		self.inviteGuestsButton.alignUnder(self.inviteMembersComment, matchingCenterWithTopPadding: 20, width: 288, height: 48)
        self.inviteGuestsLabel.alignUnder(self.inviteGuestsButton, matchingCenterWithTopPadding: 4, width: 288, height: 48)
        self.channelButton.alignUnder(self.inviteGuestsLabel, matchingCenterWithTopPadding: 4, width: 288, height: max(self.channelButton.height(), 48))
        self.inviteGuestsComment.alignUnder(self.channelButton, matchingCenterWithTopPadding: 12, width: 280, height: inviteGuestsCommentSize.height)
        self.inviteListButton.alignUnder(self.inviteGuestsComment, matchingCenterWithTopPadding: 12, width: 288, height: 48)
		
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
    
    func pickChannel(sender: AnyObject?) {
        let controller = ChannelPickerController()
        let wrapper = AirNavigationController(rootViewController: controller)
        if self.channels.count > 0 {
            for channelId in self.channels.keys {
                let channel = self.channels[channelId]
                controller.channels[channelId] = channel
            }
        }
        controller.delegate = self
        self.navigationController?.present(wrapper, animated: true, completion: nil)
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
            
            self.inviteGuestsLabel.text = "Selected channel"
            self.inviteGuestsLabel.textColor = Theme.colorTextSecondary
            self.inviteGuestsLabel.textAlignment = .center

            self.inviteGuestsComment.text = "Guests can only partipate in selected channels."
            self.inviteGuestsComment.textColor = Theme.colorTextSecondary
            self.inviteGuestsComment.textAlignment = .center
            self.inviteGuestsComment.numberOfLines = 0
            
            self.inviteGuestsButton.addTarget(self, action: #selector(inviteGuestsAction(sender:)), for: .touchUpInside)
            
            self.inviteListButton.setTitle("Pending and accepted invites".uppercased(), for: .normal)
            self.inviteListButton.addTarget(self, action: #selector(inviteListAction(sender:)), for: .touchUpInside)

            
            self.channelButton.imageRight = UIImageView(image: UIImage(named: "imgArrowDownLight"))
            self.channelButton.imageRight?.tintColor = Colors.white
            self.channelButton.imageRight?.bounds.size = CGSize(width: 14, height: 10)
            self.channelButton.titleLabel?.textAlignment = .center
            self.channelButton.titleLabel?.numberOfLines = 0
            self.channelButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 36, bottom: 0, right: 36)
            self.channelButton.backgroundColor = Colors.accentColorFill
            self.channelButton.titleLabel?.textColor = Colors.white
            self.channelButton.layer.cornerRadius = 6
            self.channelButton.setTitleColor(Colors.white, for: .normal)
            self.channelButton.setTitleColor(Colors.gray90pcntColor, for: .highlighted)
            self.channelButton.addTarget(self, action: #selector(pickChannel(sender:)), for: .touchUpInside)
            
            if let groupId = StateController.instance.groupId,
                let channelId = StateController.instance.channelId {
                let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: nil)
                channelQuery.once(with: { channel in
                    if channel != nil {
                        let channelName = channel!.name!
                        self.channels[channelId] = channelName
                        self.channelButton.setTitle(channelName, for: .normal)
                    }
                })
            }
            
            self.contentHolder.addSubview(self.message)
            self.contentHolder.addSubview(self.inviteMembersButton)
            self.contentHolder.addSubview(self.inviteMembersComment)
            self.contentHolder.addSubview(self.inviteGuestsButton)
            self.contentHolder.addSubview(self.inviteGuestsLabel)
            self.contentHolder.addSubview(self.channelButton)
            self.contentHolder.addSubview(self.inviteGuestsComment)
            self.contentHolder.addSubview(self.inviteListButton)
            
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
        }
	}
    
    func inviteList() {
        let controller = InviteListController()
        self.navigationController?.pushViewController(controller, animated: true)
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
        controller.channels = self.channels
        controller.inputGroupId = self.inputGroupId
        controller.inputGroupTitle = self.inputGroupTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func isValid() -> Bool {
        if self.validateFor == "guests" {
            if (self.channelButton.titleLabel?.text?.isEmpty)! {
                alert(title: "Select a channel")
                return false
            }
            /* Check for channel that exists */
        }
        return true
    }
}

extension InviteViewController: PickerDelegate {
    internal func update(channels: [String: Any]) {
        self.channels = channels
        var channelsLabel = ""
        for channelName in channels.values {
            if !channelsLabel.isEmpty {
                channelsLabel += "\r"
            }
            channelsLabel += "\(channelName)"
        }
        self.inviteGuestsLabel.text = channels.count > 1 ? "Selected channels" : "Selected channel"
        self.channelButton.setTitle(channelsLabel, for: .normal)
        self.view.setNeedsLayout()
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
