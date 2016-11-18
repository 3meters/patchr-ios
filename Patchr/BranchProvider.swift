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
    
    static func inviteMember(group: FireGroup!, completion: @escaping CompletionBlock) {
        
        guard group != nil else {
            assertionFailure("Member invite requires group")
            return
        }
        
        let referrer = UserController.instance.user
        let referrerName = referrer!.profile?.fullName ?? referrer!.username!
        let referrerId = UserController.instance.userId
        let photoUrl = PhotoUtils.url(prefix: referrer?.profile?.photo?.filename, source: referrer?.profile?.photo?.source, category: SizeCategory.profile)

        let path = "group/\(group.id!)"
        
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        applink.metadata?["referrerName"] = referrerName
        applink.metadata?["referrerId"] = referrerId
        if photoUrl != nil {
            applink.metadata?["referrerPhotoUrl"] = photoUrl
        }
        
        applink.metadata?["role"] = "member"
        applink.metadata?["groupId"] = group.id!
        applink.metadata?["groupName"] = group.name!
        
        /* $og_title */
        applink.title = "Invite by \(referrerName) to the \(group.name!) group"
        
        /* $og_image */
        if group.photo != nil {
            let settings = "h=250&crop&fit=crop&q=50"
            let photoUrl = "https://3meters-images.imgix.net/\(group.photo!.filename)?\(settings)"
            applink.imageUrl = photoUrl
        }
        
        /* $og_description */
        if group.desc != nil && !group.desc!.isEmpty {
            applink.contentDescription = group.desc!
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
                let invite: InviteItem = InviteItem(group: group, url: url)
                completion(invite, nil)
            }
        })
    }
    
    static func inviteGuest(group: FireGroup!, channel: FireChannel!, completion: @escaping CompletionBlock) {
        
        guard group != nil && channel != nil else {
            assertionFailure("Guest invite requires group and channel")
            return
        }
        
        let referrer = UserController.instance.user
        let referrerName = referrer!.profile?.fullName ?? referrer!.username!
        let referrerId = UserController.instance.userId
        let photoUrl = PhotoUtils.url(prefix: referrer?.profile?.photo?.filename, source: referrer?.profile?.photo?.source, category: SizeCategory.profile)
        
        let path = "group/\(group.id!)"
        
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        applink.metadata?["referrerName"] = referrerName
        applink.metadata?["referrerId"] = referrerId
        if photoUrl != nil {
            applink.metadata?["referrerPhotoUrl"] = photoUrl
        }
        
        applink.metadata?["role"] = "guest"
        applink.metadata?["groupId"] = group.id!
        applink.metadata?["groupName"] = group.name!
        
        applink.metadata?["channelId"] = channel!.id!
        applink.metadata?["channelName"] = channel!.name!
        
        /* $og_title */
        applink.title = "Invite by \(referrerName) to the \(channel!.name!) channel"
        
        /* $og_image */
        if channel!.photo != nil {
            let settings = "h=250&crop&fit=crop&q=50"
            let photoUrl = "https://3meters-images.imgix.net/\(channel!.photo!.filename)?\(settings)"
            applink.imageUrl = photoUrl
        }
        
        /* $og_description */
        if channel!.purpose != nil && !channel!.purpose!.isEmpty {
            applink.contentDescription = channel!.purpose!
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
                let invite: InviteItem = InviteItem(group: group, url: url)
                completion(invite, nil)
            }
        })
    }
	
	static func invite(entity: Patch, referrer: User, completion: @escaping CompletionBlock) {
        /* Zombie */
	}
	
	static func share(entity: Message, referrer: User, completion: @escaping CompletionBlock) {
        /* Zombie */
	}
}

class InviteItem: NSObject, UIActivityItemSource {
    
    var group: FireGroup
    var url: String
    
    init(group: FireGroup, url: String) {
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
        let text = "\(UserController.instance.user?.profile?.fullName) has invited you to the \(self.group.name!) group!"
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
            return "Invitation to the \(self.group.name!) group"
        }
        return ""
    }
}

