//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Keys
import Branch
import Localize_Swift

class BranchProvider: NSObject {
	
	static func logout() {
		Branch.getInstance().logout()
	}
	
	static func setIdentity(identity: String) {
		Branch.getInstance().setIdentity(identity)
	}
    
    typealias CompletionBlock = (_ response: Any?, _ error: Error?) -> Void
    
    static func invite(channel: [String: String], code: String, email: String, role: String, message: String?, then: @escaping CompletionBlock) {
        
        let inviter = UserController.instance.user
        let inviterId = UserController.instance.userId!
        let inviterName = inviter!.profile?.fullName ?? UserController.instance.user?.username
        let path = "channel/\(channel["id"]!)"
        let applink = BranchUniversalObject(canonicalIdentifier: path)
        
        applink.metadata?["channel_id"] = channel["id"]
        applink.metadata?["channel_title"] = channel["title"]
        applink.metadata?["created_at"] = DateUtils.now()
        applink.metadata?["code"] = code
        applink.metadata?["language"] = Localize.currentLanguage()
        applink.metadata?["role"] = role
        applink.metadata?["email"] = email
        applink.metadata?["invited_by"] = inviterId
        applink.metadata?["inviter_name"] = inviterName
        
        if message != nil {
            applink.metadata?["message"] = message!
        }
        
        if let photo = inviter!.profile?.photo {
            let photoUrl = ImageProxy.url(photo: photo, category: SizeCategory.profile)
            applink.metadata?["inviter_photo_url"] = photoUrl
        }
        
        /* $og_title */
        applink.title = "deepview_title".localizedFormat(inviterName!, channel["title"]!)
        
        let linkProperties = BranchLinkProperties()
        linkProperties.channel = "teeny-ios"
        linkProperties.feature = BRANCH_FEATURE_TAG_INVITE
        
        /* Select deepview based on language */
        let language = Localize.currentLanguage()
        let deepViewId = language == "en" ? "patchr_deepview_wskd" : "patchr_deepview_ru"
        linkProperties.addControlParam("$ios_deepview", withValue: deepViewId)
        
        applink.getShortUrl(with: linkProperties, andCallback: { url, error in
            if error != nil {
                Log.d("Error creating invite link", breadcrumb: true)
                then(nil, error)
            }
            else {
                Log.d("Branch invite link created: \(url!)", breadcrumb: true)
                let invite = InviteItem(channel: nil, url: url!)
                then(invite, nil)
            }
        })
    }
}

class InviteItem: NSObject, UIActivityItemSource {
    
    var channel: FireChannel?
    var url: String
    
    init(channel: FireChannel?, url: String) {
        self.channel = channel
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
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        let userTitle = (UserController.instance.user?.title)!
        let channelTitle = (self.channel?.title!)!
        let text = "share_description".localizedFormat(userTitle, channelTitle)
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
            let channelTitle = (self.channel?.title!)!
            return "share_subject".localizedFormat(channelTitle)
        }
        return ""
    }
}

