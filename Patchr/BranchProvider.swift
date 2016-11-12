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
    
    static func invite(group: FireGroup!, channel: FireChannel?, guest: Bool = false, completion: @escaping CompletionBlock) {
        
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
        
        applink.metadata?["guest"] = guest
        applink.metadata?["groupId"] = group.id!
        applink.metadata?["groupName"] = group.name!
        
        if channel != nil {   // Guest invite to channel
            
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
        }
        else {
            
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
        }
        
        let linkProperties = BranchLinkProperties()
        linkProperties.channel = "patchr-ios"
        linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
        
        applink.getShortUrl(with: linkProperties, andCallback: { url, error in
            if error != nil {
                completion(nil, error as NSError?)
            }
            else {
                Log.d("Branch invite link created: \(url)", breadcrumb: true)
                let invite: InviteItem = InviteItem(group: group, url: url)
                completion(invite, nil)
            }
        })
    }
	
	static func invite(entity: Patch, referrer: User, completion: @escaping CompletionBlock) {
		
		let patchName = entity.name!
		let referrerName = referrer.name!
		let referrerId = referrer.id_!
		let ownerName = entity.creator.name!
		let path = "patch/\(entity.id_!)"
		
		let applink = BranchUniversalObject(canonicalIdentifier: path)
		applink.metadata?["entityId"] = entity.id_!
		applink.metadata?["entitySchema"] = "patch"
		applink.metadata?["referrerName"] = referrerName
		applink.metadata?["referrerId"] = referrerId
		applink.metadata?["ownerName"] = ownerName
		applink.metadata?["patchName"] = patchName
		
		if let photo = ZUserController.instance.currentUser.photo {
			let photoUrl = PhotoUtils.url(prefix: photo.prefix!, source: photo.source!, category: SizeCategory.profile)
			applink.metadata?["referrerPhotoUrl"] = photoUrl
		}
		
		/* $og_title */
		applink.title = "Invite by \(referrerName) to the \(patchName) patch"
		
		/* $og_image */
		if entity.photo != nil {
			let settings = "h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(entity.photo!.prefix)?\(settings)"
			applink.imageUrl = photoUrl
		}
		
		/* $og_description */
		if entity.description_ != nil && !entity.description_.isEmpty {
			applink.contentDescription = entity.description_!
		}
		
		let linkProperties = BranchLinkProperties()
		linkProperties.channel = "patchr-ios"
		linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
		
		applink.getShortUrl(with: linkProperties, andCallback: { url, error in
			if error != nil {
				completion(nil, error as NSError?)
			}
			else {
				Log.d("Branch invite link created: \(url)", breadcrumb: true)
				let patch: PatchItem = PatchItem(entity: entity, shareUrl: url)
				completion(patch, nil)
			}
		})
	}
	
	static func share(entity: Message, referrer: User, completion: @escaping CompletionBlock) {
		
		let patchName = entity.patch?.name!
		let referrerName = referrer.name!
		let referrerId = referrer.id_!
		let ownerName = entity.creator.name!
		let path = "message/\(entity.id_!)"
		
		let applink = BranchUniversalObject(canonicalIdentifier: path)
		applink.metadata?["entityId"] = entity.id_!
		applink.metadata?["entitySchema"] = "message"
		applink.metadata?["referrerName"] = referrerName
		applink.metadata?["referrerId"] = referrerId
		applink.metadata?["ownerName"] = ownerName
		
		if patchName != nil {
			applink.metadata?["patchName"] = patchName
		}
		
		if let photo = ZUserController.instance.currentUser.photo {
			let photoUrl = PhotoUtils.url(prefix: photo.prefix!, source: photo.source!, category: SizeCategory.profile)
			applink.metadata?["referrerPhotoUrl"] = photoUrl
		}
		
		/* $og_title */
		applink.title = "Shared by \(referrerName)"
		
		/* $og_image */
		if entity.photo != nil {
			let settings = "h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(entity.photo!.prefix)?\(settings)"
			applink.imageUrl = photoUrl
		}
		else if entity.patch?.photo != nil {
			let settings = "h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(entity.patch!.photo!.prefix!)?\(settings)"
			applink.imageUrl = photoUrl
		}
		
		/* $og_description */
		var description = "\(ownerName) posted a photo to the \(entity.patch!.name) patch using Patchr"
		if entity.description_ != nil && !entity.description_.isEmpty {
			description = "\(ownerName) posted: \"\(entity.description_)\""
		}
		applink.contentDescription = description
		
		let linkProperties = BranchLinkProperties()
		linkProperties.channel = "patchr-ios"
		linkProperties.feature = BRANCH_FEATURE_TAG_SHARE
		
		applink.getShortUrl(with: linkProperties, andCallback: { url, error in
			if error != nil {
				completion(nil, error as NSError?)
			}
			else {
				Log.d("Branch share link created: \(url)", breadcrumb: true)
				let message: MessageItem = MessageItem(entity: entity, shareUrl: url)
				completion(message, nil)
			}
		})
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

