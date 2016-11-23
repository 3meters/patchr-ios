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
    var inputUsername: String?
    
    var validateFor = "member"
    
    var userTitle: String? {
        var userTitle: String?
        if let profile = UserController.instance.user?.profile, profile.fullName != nil {
            userTitle = profile.fullName
        }
        if userTitle == nil, let username = StateController.instance.group.username {
            userTitle = username
        }
        if userTitle == nil, let displayName = FIRAuth.auth()?.currentUser?.displayName {
            userTitle = displayName
        }
        return userTitle
    }
    
    var userEmail: String? {
        var userEmail: String?
        if let email = UserController.instance.user?.email {
            userEmail = email
        }
        if userEmail == nil, let authEmail = FIRAuth.auth()?.currentUser?.email {
            userEmail = authEmail
        }
        return userEmail
    }
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}
    
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let inviteMembersCommentSize = self.inviteMembersComment.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let inviteGuestsCommentSize = self.inviteGuestsComment.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
		
		self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
		self.inviteMembersButton.alignUnder(self.message, matchingCenterWithTopPadding: 24, width: 288, height: 48)
        self.inviteMembersComment.alignUnder(self.inviteMembersButton, matchingCenterWithTopPadding: 12, width: 288, height: inviteMembersCommentSize.height)
		self.inviteGuestsButton.alignUnder(self.inviteMembersComment, matchingCenterWithTopPadding: 20, width: 288, height: 48)
        self.channelField.alignUnder(self.inviteGuestsButton, matchingCenterWithTopPadding: 12, width: 288, height: 48)
        self.inviteGuestsComment.alignUnder(self.channelField, matchingCenterWithTopPadding: 12, width: 280, height: inviteGuestsCommentSize.height)
		
		self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.contentHolder.frame.size.height)
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
                StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
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
		/*
		 * Invite dialog doesn't show if user is already a member or pending.
		 */
		self.inviteMembersButton.setTitle("Full members".uppercased(), for: .normal)
        self.inviteMembersComment.text = "Full members can partipate in any open channel and access the full group directory."
        self.inviteMembersComment.textColor = Theme.colorTextSecondary
        self.inviteMembersComment.textAlignment = .center
        self.inviteMembersComment.numberOfLines = 0
        self.inviteMembersButton.addTarget(self, action: #selector(inviteMembersAction(sender:)), for: .touchUpInside)
        
        if self.flow != .onboardCreate {
            
            self.inviteGuestsButton.setTitle("Guest members".uppercased(), for: .normal)
            self.inviteGuestsComment.text = "Guests can only partipate in selected channels."
            self.inviteGuestsComment.textColor = Theme.colorTextSecondary
            self.inviteGuestsComment.textAlignment = .center
            self.inviteGuestsComment.numberOfLines = 0
            
            self.inviteGuestsButton.addTarget(self, action: #selector(inviteGuestsAction(sender:)), for: .touchUpInside)
            
            self.channelField.setPlaceholder("Select a channel", floatingTitle: "Selected channel")
            self.channelField.floatingLabel.textAlignment = .center
            self.channelField.textAlignment = .center
            self.channelField.delegate = self
            self.channelField.keyboardType = .default
            self.channelField.autocapitalizationType = .none
            self.channelField.autocorrectionType = .no
            self.channelField.returnKeyType = .default
            
            if let groupId = StateController.instance.groupId, let channelId = StateController.instance.channelId {
                let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: nil)
                channelQuery.once(with: { channel in
                    if channel != nil {
                        self.channel = channel
                        self.channelField.text = channel?.name
                    }
                })
            }
            
            self.contentHolder.addSubview(self.inviteGuestsButton)
            self.contentHolder.addSubview(self.inviteGuestsComment)
            self.contentHolder.addSubview(self.channelField)
            
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
            self.navigationItem.leftBarButtonItems = []
            self.navigationItem.hidesBackButton = true
        }
        else {
            let closeButton = UIBarButtonItem(image: UIImage(named: "imgCancelLight"), style: .plain, target: self, action: #selector(doneAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
            self.navigationItem.leftBarButtonItems = []
            self.navigationItem.hidesBackButton = true
        }
		
		self.contentHolder.addSubview(self.message)
		self.contentHolder.addSubview(self.inviteMembersButton)
        self.contentHolder.addSubview(self.inviteMembersComment)
	}
    
    func inviteMembers() {
        
        let groupId = StateController.instance.group?.id ?? self.inputGroupId!
        let groupTitle = StateController.instance.group?.title ?? self.inputGroupTitle!
        let username = StateController.instance.group?.username ?? self.inputUsername!
        
        BranchProvider.inviteMember(groupId: groupId, groupTitle: groupTitle, username: username, completion: { response, error in
            
            if let error = ServerError(error) {
                UIViewController.topMostViewController()!.handleError(error)
            }
            else {
                let invite = response as! InviteItem
                let inviteUrl = invite.url
                
                let subject = "\(self.userTitle!) invited you to \(groupTitle) on Patchr"
                let htmlFile = Bundle.main.path(forResource: "invite_member", ofType: "html")
                let templateString = try? String(contentsOfFile: htmlFile!, encoding: .utf8)
                
                var htmlString = templateString?.replacingOccurrences(of: "[[group.name]]", with: groupTitle)
                htmlString = htmlString?.replacingOccurrences(of: "[[user.fullName]]", with: self.userTitle!)
                htmlString = htmlString?.replacingOccurrences(of: "[[user.email]]", with: self.userEmail!)
                htmlString = htmlString?.replacingOccurrences(of: "[[link]]", with: inviteUrl)
                
                if MFMailComposeViewController.canSendMail() {
                    MailComposer!.mailComposeDelegate = self
                    MailComposer!.setSubject(subject)
                    MailComposer!.setMessageBody(htmlString!, isHTML: true)
                    self.present(MailComposer!, animated: true, completion: nil)
                }
            }
        })
    }
    
    func inviteGuests() {
        
        BranchProvider.inviteGuest(group: StateController.instance.group, channel: self.channel, completion: { response, error in
            
            if let error = ServerError(error) {
                UIViewController.topMostViewController()!.handleError(error)
            }
            else {
                let invite = response as! InviteItem
                let inviteUrl = invite.url
                
                let group = StateController.instance.group!
                let channel = self.channel!
                
                let groupTitle = group.title!
                let channelName = channel.name!
                
                let subject = "\(self.userTitle!) invited you to \(channelName) on Patchr"
                let htmlFile = Bundle.main.path(forResource: "invite_guest", ofType: "html")
                let templateString = try? String(contentsOfFile: htmlFile!, encoding: .utf8)
                
                var htmlString = templateString?.replacingOccurrences(of: "[[group.name]]", with: groupTitle)
                htmlString = htmlString?.replacingOccurrences(of: "[[user.fullName]]", with: self.userTitle!)
                htmlString = htmlString?.replacingOccurrences(of: "[[channel.name]]", with: channelName)
                htmlString = htmlString?.replacingOccurrences(of: "[[user.email]]", with: self.userEmail!)
                htmlString = htmlString?.replacingOccurrences(of: "[[link]]", with: inviteUrl)
                
                if MFMailComposeViewController.canSendMail() {
                    MailComposer!.mailComposeDelegate = self
                    MailComposer!.setSubject(subject)
                    MailComposer!.setMessageBody(htmlString!, isHTML: true)
                    self.present(MailComposer!, animated: true, completion: nil)
                }
            }
        })
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
