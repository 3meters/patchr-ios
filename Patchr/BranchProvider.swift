//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Keys
import Branch

class BranchProvider: NSObject {
	
	static func logout() {
		Branch.getInstance().logout()
	}
	
	static func setIdentity(identity: String) {
		Branch.getInstance().setIdentity(identity)
	}
    
    typealias CompletionBlock = (_ response: AnyObject?, _ error: NSError?) -> Void
    
    static func inviteMember(group: FireGroup, completion: @escaping CompletionBlock) {
        let username = UserController.instance.user?.username
        BranchProvider.inviteMember(groupId: group.id!, groupTitle: group.title!, username: username, completion: completion)
    }
    
    static func inviteMember(groupId: String, groupTitle: String, username: String?, completion: @escaping CompletionBlock) {
        
        let group = StateController.instance.group
        let referrer = UserController.instance.user
        let referrerId = UserController.instance.userId
        let referrerName = referrer!.profile?.fullName ?? username
        let photoUrl = PhotoUtils.url(prefix: referrer?.profile?.photo?.filename, source: referrer?.profile?.photo?.source, category: SizeCategory.profile)
        let path = "group/\(groupId)"
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        
        applink.metadata?["referrerId"] = referrerId
        applink.metadata?["referrerName"] = referrerName
        
        if photoUrl != nil {
            applink.metadata?["referrerPhotoUrl"] = photoUrl
        }
        
        applink.metadata?["role"] = "member"
        applink.metadata?["groupId"] = groupId
        applink.metadata?["groupTitle"] = groupTitle
        
        /* $og_title */
        applink.title = "Invite by \(referrerName!) to the \(groupTitle) group"
        
        /* $og_image */
        if let photo = group?.photo {
            let settings = "h=250&crop&fit=crop&q=50"
            let photoUrl = "https://3meters-images.imgix.net/\(photo.filename!)?\(settings)"
            applink.imageUrl = photoUrl
        }
        
        /* $og_description */
        if let desc = group?.desc, !desc.isEmpty {
            applink.contentDescription = desc
        }
        
        let linkProperties = BranchLinkProperties()
        linkProperties.channel = "patchr-ios"
        linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
        
        applink.getShortUrl(with: linkProperties, andCallback: { url, error in
            if error != nil {
                completion(nil, error as NSError?)
            }
            else {
                Log.d("Branch member invite link created: \(url)", breadcrumb: true)
                let invite: InviteItem = InviteItem(group: nil, url: url)
                completion(invite, nil)
            }
        })
    }
    
    static func inviteGuest(group: FireGroup, channel: FireChannel, completion: @escaping CompletionBlock) {
        
        let referrer = UserController.instance.user
        let referrerId = UserController.instance.userId
        let referrerName = referrer!.profile?.fullName ?? UserController.instance.user?.username
        let photoUrl = PhotoUtils.url(prefix: referrer?.profile?.photo?.filename, source: referrer?.profile?.photo?.source, category: SizeCategory.profile)
        let path = "group/\(group.id!)"
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        
        applink.metadata?["referrerId"] = referrerId
        applink.metadata?["referrerName"] = referrerName
        
        if photoUrl != nil {
            applink.metadata?["referrerPhotoUrl"] = photoUrl
        }
        
        applink.metadata?["role"] = "guest"
        applink.metadata?["groupId"] = group.id!
        applink.metadata?["groupTitle"] = group.title!
        applink.metadata?["channelId"] = channel.id!
        applink.metadata?["channelName"] = channel.name!
        
        /* $og_title */
        applink.title = "Invite by \(referrerName!) to the \(channel.name!) channel"
        
        /* $og_image */
        if let photo = channel.photo {
            let settings = "h=250&crop&fit=crop&q=50"
            let photoUrl = "https://3meters-images.imgix.net/\(photo.filename!)?\(settings)"
            applink.imageUrl = photoUrl
        }
        
        /* $og_description */
        if channel.purpose != nil && !channel.purpose!.isEmpty {
            applink.contentDescription = channel.purpose!
        }
        
        let linkProperties = BranchLinkProperties()
        linkProperties.channel = "patchr-ios"
        linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
        
        applink.getShortUrl(with: linkProperties, andCallback: { url, error in
            if error != nil {
                completion(nil, error as NSError?)
            }
            else {
                Log.d("Branch guest invite link created: \(url)", breadcrumb: true)
                let invite: InviteItem = InviteItem(group: nil, url: url)
                completion(invite, nil)
            }
        })
    }
}

class InviteItem: NSObject, UIActivityItemSource {
    
    var group: FireGroup?
    var url: String
    
    init(group: FireGroup?, url: String) {
        self.group = group
        self.url = url
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        /* Called before the share actions are displayed */
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
        /* Not currently called by any of the share extensions I could test. */
        return nil
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        let text = "\(UserController.instance.user?.profile?.fullName) has invited you to the \(self.group?.title!) group!"
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        /*
         * Outlook: Doesn't call this.
         * Gmail constructs their own using the value from itemForActivityType
         * Apple email calls this.
         * Apple message calls this (I believe as an alternative if nothing provided via itemForActivityType).
         */
        if activityType == UIActivityType.mail {
            return "Invitation to the \(self.group!.title!) group"
        }
        return ""
    }
}

