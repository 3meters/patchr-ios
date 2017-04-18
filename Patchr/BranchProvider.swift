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
    
    static func inviteMember(groupId: String, groupTitle: String, username: String?, email: String, inviteId: String, completion: @escaping CompletionBlock) {
        
        let group = StateController.instance.group
        let inviter = UserController.instance.user
        let inviterId = UserController.instance.userId!
        let inviterName = inviter!.profile?.fullName ?? username
        let path = "group/\(groupId)"
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        
        applink.metadata?["created_at"] = DateUtils.now()
        applink.metadata?["email"] = email
        applink.metadata?["group_id"] = groupId
        applink.metadata?["groupTitle"] = groupTitle
        applink.metadata?["invite_id"] = inviteId
        applink.metadata?["invited_by"] = inviterId
        applink.metadata?["inviterName"] = inviterName
        
        if let photo = inviter!.profile?.photo {
            let photoUrl = Cloudinary.url(prefix: photo.filename!, category: SizeCategory.profile)
            applink.metadata?["inviterPhotoUrl"] = photoUrl
        }
        
        applink.metadata?["role"] = "member"
        
        /* $og_title */
        applink.title = "Invite by \(inviterName!) to the \(groupTitle) group"
        
        /* $og_image */
        if let photo = group?.photo {
            let photoUrl = Cloudinary.url(prefix: photo.filename!, params: "w_250,q_auto,c_fill")
            applink.imageUrl = photoUrl.absoluteString
        }
        
        /* $og_description */
        applink.contentDescription = "Group messaging for control freaks."
        
        let linkProperties = BranchLinkProperties()
        linkProperties.channel = "patchr-ios"
        linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
        
        applink.getShortUrl(with: linkProperties, andCallback: { url, error in
            if error != nil {
                completion(nil, error as NSError?)
            }
            else {
                Log.d("Branch member invite link created: \(url!)", breadcrumb: true)
                let invite: InviteItem = InviteItem(group: nil, url: url!)
                completion(invite, nil)
            }
        })
    }
    
    static func inviteGuest(group: FireGroup, channels: [String: Any], email: String, inviteId: String, completion: @escaping CompletionBlock) {
        
        let inviter = UserController.instance.user
        let inviterId = UserController.instance.userId!
        let inviterName = inviter!.profile?.fullName ?? UserController.instance.user?.username
        let path = "group/\(group.id!)"
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        
        applink.metadata?["channels"] = channels
        applink.metadata?["created_at"] = DateUtils.now()
        applink.metadata?["email"] = email
        applink.metadata?["group_id"] = group.id!
        applink.metadata?["groupTitle"] = group.title!
        applink.metadata?["invite_id"] = inviteId
        applink.metadata?["invited_by"] = inviterId
        applink.metadata?["inviterName"] = inviterName
        
        if let photo = inviter!.profile?.photo {
            let photoUrl = Cloudinary.url(prefix: photo.filename!, category: SizeCategory.profile)
            applink.metadata?["inviterPhotoUrl"] = photoUrl
        }
        
        applink.metadata?["role"] = "guest"
        
        /* $og_title */
        let channelName = channels.first?.value as! String
        if channels.count == 1 {
            applink.title = "Invite by \(inviterName!) to the \(channelName) channel"
        }
        else {
            applink.title = "Invite by \(inviterName!) to the \(channelName) channel plus more"
        }
        
        /* $og_description */
        applink.contentDescription = "Group messaging for control freaks."
        
        let linkProperties = BranchLinkProperties()
        linkProperties.channel = "patchr-ios"
        linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
        
        applink.getShortUrl(with: linkProperties, andCallback: { url, error in
            if error != nil {
                completion(nil, error as NSError?)
            }
            else {
                Log.d("Branch guest invite link created: \(url)", breadcrumb: true)
                let invite: InviteItem = InviteItem(group: nil, url: url!)
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

