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

class InviteViewController: BaseEditViewController {
	
	var heading = AirLabelTitle()
	var inviteMembersButton = AirButton()
    var inviteMembersComment = AirLabelDisplay()
	var inviteGuestsButton = AirButton()
    var inviteGuestsComment = AirLabelDisplay()
    var inviteListButton = AirLinkButton()

    var channelQuery: ChannelQuery!
    var channels: [String: Any] = [:]
    var inputGroupId: String?
    var inputGroupTitle: String?
    var inputRole: String?
    
    var validateFor = "member"
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		
        let headingSize = self.heading.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let inviteMembersCommentSize = self.inviteMembersComment.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let inviteGuestsCommentSize = self.inviteGuestsComment.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        
		self.heading.anchorTopCenter(withTopPadding: 0, width: 288, height: headingSize.height)
		self.inviteMembersButton.alignUnder(self.heading, matchingCenterWithTopPadding: 24, width: 288, height: 48)
        self.inviteMembersComment.alignUnder(self.inviteMembersButton, matchingCenterWithTopPadding: 12, width: 288, height: inviteMembersCommentSize.height)
		self.inviteGuestsButton.alignUnder(self.inviteMembersComment, matchingCenterWithTopPadding: 20, width: 288, height: 48)
        self.inviteGuestsComment.alignUnder(self.inviteGuestsButton, matchingCenterWithTopPadding: 12, width: 280, height: inviteGuestsCommentSize.height)
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
    
    func closeAction(sender: AnyObject?) {
        close()
    }
    
    func doneAction(sender: AnyObject?) {
        let groupId = self.inputGroupId!
        FireController.instance.findGeneralChannel(groupId: groupId) { channelId in
            if channelId != nil {
                StateController.instance.setChannelId(channelId: channelId!, groupId: groupId)
                MainController.instance.showChannel(channelId: channelId!, groupId: groupId)
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
        
        let groupTitle = self.inputGroupTitle ?? StateController.instance.group?.title!
        self.heading.text = "Invite people to \(groupTitle!)."
		self.heading.textAlignment = NSTextAlignment.center
		self.heading.numberOfLines = 0
        
        if self.flow == .onboardCreate || self.flow == .internalCreate {
            /*
             * Invite dialog doesn't show if user is already a member or pending.
             */
            self.inviteMembersButton.setTitle("Invite Members".uppercased(), for: .normal)
            self.inviteMembersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteMembersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)

            self.inviteMembersComment.text = "An email invitation will be sent to your selected contacts. Accepting the invitation will add them as members of your group and help them install Patchr if they don't have it yet."
            self.inviteMembersComment.textColor = Theme.colorTextSecondary
            self.inviteMembersComment.textAlignment = .center
            self.inviteMembersComment.numberOfLines = 0
            self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
            
            let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.rightBarButtonItems = [doneButton]
            
            self.contentHolder.addSubview(self.heading)
            self.contentHolder.addSubview(self.inviteMembersButton)
            self.contentHolder.addSubview(self.inviteMembersComment)
        }
        else {
            /*
             * Invite dialog doesn't show if user is already a member or pending.
             */
            self.inviteMembersButton.setTitle("Invite Members".uppercased(), for: .normal)
            self.inviteMembersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteMembersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            self.inviteMembersComment.text = "Members can partipate in any open channel and access the full group directory."
            self.inviteMembersComment.textColor = Theme.colorTextSecondary
            self.inviteMembersComment.textAlignment = .center
            self.inviteMembersComment.numberOfLines = 0
            self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
            
            self.inviteGuestsButton.setTitle("Invite Guests".uppercased(), for: .normal)
            self.inviteGuestsButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
            self.inviteGuestsButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
            
            self.inviteGuestsComment.text = "Guests can only partipate in selected channels."
            self.inviteGuestsComment.textColor = Theme.colorTextSecondary
            self.inviteGuestsComment.textAlignment = .center
            self.inviteGuestsComment.numberOfLines = 0
            
            self.inviteGuestsButton.addTarget(self, action: #selector(inviteGuestsAction(sender:)), for: .touchUpInside)
            
            self.inviteListButton.setTitle("Pending and accepted invites".uppercased(), for: .normal)
            self.inviteListButton.addTarget(self, action: #selector(inviteListAction(sender:)), for: .touchUpInside)

            
            if let groupId = StateController.instance.groupId,
                let channelId = StateController.instance.channelId {
                self.channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: nil)
                self.channelQuery.once(with: { [weak self] error, channel in
                    guard let strongSelf = self else { return }
                    if channel != nil {
                        let channelName = channel!.name!
                        strongSelf.channels[channelId] = channelName
                    }
                })
            }
            
            self.contentHolder.addSubview(self.heading)
            self.contentHolder.addSubview(self.inviteMembersButton)
            self.contentHolder.addSubview(self.inviteMembersComment)
            self.contentHolder.addSubview(self.inviteGuestsButton)
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
        controller.flow = self.flow
        controller.inputRole = self.inputRole
        controller.inputGroupId = self.inputGroupId
        controller.inputGroupTitle = self.inputGroupTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func inviteGuests() {
        let controller = ChannelPickerController()
        controller.flow = self.flow
        controller.inputGroupId = self.inputGroupId
        controller.inputGroupTitle = self.inputGroupTitle
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
