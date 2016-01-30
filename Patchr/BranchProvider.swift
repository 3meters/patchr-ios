//
//  UserController.swift
//  Patchr
//
//  Created by Jay Massena on 5/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import FBSDKLoginKit
import FBSDKShareKit
import Keys
import Branch

class BranchProvider: NSObject {
	
	static func logout() {
		Branch.getInstance().logout()
	}
	
	static func setIdentity(identity: String) {
		Branch.getInstance().setIdentity(identity)
	}
	
	static func invite(entity: Patch, referrer: User, completion: CompletionBlock) {
		
		let referrerName = referrer.name!
		let ownerName = entity.creator.name!
		let patchName = entity.name!
		
		var parameters = [
			"entityId":entity.id_!,
			"entitySchema":"patch",
			"referrerName":referrerName,
			"ownerName": ownerName,
			"patchName": patchName,
			"feature": BRANCH_FEATURE_TAG_INVITE,
			"$og_title": "Invite by \(referrerName) to the \(patchName) patch",
		]
		
		if entity.photo != nil {
			let photo = entity.getPhotoManaged()
			let settings = "h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)"
			parameters["$og_image_url"] = photoUrl
		}
		
		if entity.description_ != nil && !entity.description_.isEmpty {
			parameters["$og_description"] = entity.description_
		}
		
		Branch.getInstance().getShortURLWithParams(parameters,
			andChannel: "patchr-ios",	// not the same as url scheme
			andFeature: BRANCH_FEATURE_TAG_INVITE,
			andCallback: { url, error in
				
			if error != nil {
				completion(response: nil, error: error)
			}
			else {
				Log.d("Branch link created: \(url!)")
				let patch: PatchItem = PatchItem(entity: entity, shareUrl: url!)
				completion(response: patch, error: nil)
			}
		})
	}
	
	static func share(entity: Message, referrer: User, completion: CompletionBlock) {
		
		let referrerName = referrer.name!
		let ownerName = entity.creator.name!
		let patchName = entity.patch?.name!
		
		var parameters = [
			"entityId": entity.id_!,
			"entitySchema": "message",
			"feature": BRANCH_FEATURE_TAG_SHARE,
			"referrerName": referrerName,
			"ownerName": ownerName
		]
		
		if patchName != nil {
			parameters["patchName"] = patchName
		}
		
		if entity.photo != nil {
			let photo = entity.getPhotoManaged()
			let settings = "h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)"
			parameters["$og_image_url"] = photoUrl
		}
		else if entity.patch != nil {
			let photo = entity.patch.getPhotoManaged()
			let settings = "h=250&crop&fit=crop&q=50"
			let photoUrl = "https://3meters-images.imgix.net/\(photo.prefix)?\(settings)"
			parameters["$og_image_url"] = photoUrl
		}
		
		var description = "\(ownerName) posted a photo to the \(entity.patch!.name) patch using Patchr"
		if entity.description_ != nil && !entity.description_.isEmpty {
			description = "\(ownerName) posted: \"\(entity.description_)\""
		}
		
		parameters["$og_title"] = "Shared by \(referrerName)"
		parameters["$og_description"] = description
		
		Branch.getInstance().getShortURLWithParams(parameters,
			andChannel: "patchr-ios",	// not the same as url scheme
			andFeature: BRANCH_FEATURE_TAG_SHARE,
			andCallback: { url, error in
				
				if error != nil {
					completion(response: nil, error: error)
				}
				else {
					Log.d("Branch link created: \(url!)")
					let message: MessageItem = MessageItem(entity: entity, shareUrl: url!)
					completion(response: message, error: nil)
				}
		})
	}
}