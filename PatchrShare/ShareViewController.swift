//
//  ShareViewController.swift
//  share
//
//  Created by Jay Massena on 7/11/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Lockbox

class ShareViewController: SLComposeServiceViewController {

    var userId: String?
    var sessionKey: String?
    var image: UIImage?
    var patch: [String:AnyObject]?
    var patchId: String!
    var url: NSURL?
    
    lazy var patchConfigurationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()
        item.title = "Patch"
        item.value = PatchTargetViewController.defaultPatch()
        item.tapHandler = self.showPatchPicker
        return item
    }()
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let groupDefaults = NSUserDefaults(suiteName: "group.com.3meters.patchr.ios") {
			let lockbox = Lockbox(keyPrefix: KEYCHAIN_GROUP)
            self.userId = groupDefaults.stringForKey(PatchrUserDefaultKey("userId"))
			self.sessionKey = lockbox.unarchiveObjectForKey("sessionKey") as? String
        }
        /*
        * ISSUE: User info won't be there if the user uses is not currently signed into Patchr.
        * So we alert and bail when this case is detected.
        */
        if self.userId == nil {
            let alert = UIAlertController(title: "Patchr sign in",
                message: "To share messages and photos to Patchr, you need to be signed in.",
                preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Cancel) { _ in
                self.cancel()
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        
        Log.d("Presenting patchr extension")
        placeholder = "Your comments"
        
        for item: AnyObject in self.extensionContext!.inputItems {
            
            let inputItem = item as! NSExtensionItem
            for provider in inputItem.attachments as! [NSItemProvider] {
                
                Log.d("Provider type: \(provider.registeredTypeIdentifiers)")
                
                /* Check for image */
                
                var hasImage: Bool = false
                if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String)
                    || provider.hasItemConformingToTypeIdentifier("public.image") {
                    
                    hasImage = true
                    let dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                    dispatch_async(dispatchQueue, {[weak self] in
                        
                        let strongSelf = self!
                        
                        var identifier = "public.image"
                        if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                            identifier = kUTTypeImage as String
                        }
                        
                        provider.loadItemForTypeIdentifier(identifier, options: nil) {
                            content, error in
                            Log.d("Processing image")
                            Log.d("Content: \(content)")
                            
                            if error == nil {
                                if let url = content as? NSURL {
                                    Log.d("As NSURL...")
                                    if let data = NSData(contentsOfURL: url) {
                                        dispatch_async(dispatch_get_main_queue(), {
                                            strongSelf.image = UIImage(data: data)
                                            strongSelf.validateContent()
                                        })
                                    }
                                }
                                else if let data = content as? NSData {
                                    Log.d("As NSData...")
                                    dispatch_async(dispatch_get_main_queue(), {
                                        strongSelf.image = UIImage(data: data)
                                        strongSelf.validateContent()
                                    })
                                }
                                else if let image = content as? UIImage {
                                    Log.d("As UIImage...")
                                    dispatch_async(dispatch_get_main_queue(), {
                                        strongSelf.image = image
                                        strongSelf.validateContent()
                                    })
                                }
                            }
                            else {
                                let alert = UIAlertController(title: "Error", message: "Error loading image", preferredStyle: .Alert)
                                let action = UIAlertAction(title: "Error", style: .Cancel) { _ in
                                    strongSelf.dismissViewControllerAnimated(true, completion: nil)
                                }
                                
                                alert.addAction(action)
                                strongSelf.presentViewController(alert, animated: true, completion: nil)
                            }
                        }
                    })
                }
                
                /* Check for url. We ignore it if we already have an image */
                
                if !hasImage {
                    if provider.hasItemConformingToTypeIdentifier("public.url") {
                        let dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                        dispatch_async(dispatchQueue, {[weak self] in
                            
                            let strongSelf = self!
                            
                            provider.loadItemForTypeIdentifier("public.url", options: nil) {
                                content, error in
                                Log.d("Processing url")
                                
                                if error == nil {
                                    if let url = content as? NSURL {
                                        Log.d("Found url!: \(url.absoluteString)")
                                        /*
                                         * When sharing url from chrome, the textView is set to the page
                                         * title so is not empty.
                                         */
                                        dispatch_async(dispatch_get_main_queue()) {
                                            strongSelf.placeholder = nil
                                            strongSelf.url = url
                                            if strongSelf.textView.text.isEmpty {
                                                strongSelf.textView.text = "Shared link:\n\(url.absoluteString)"
                                            }
                                            else {
                                                strongSelf.textView.text = "\(strongSelf.textView.text)\nShared link:\n\(url.absoluteString)"
                                            }
                                        }
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func didSelectPost() {
        let imageKey = "\(Utils.genImageKey()).jpg"
        let message = buildMessage(imageKey)
        Proxibase.sharedService.postMessage(message, patch: self.patch!)
        if self.image != nil {
            S3.sharedService.uploadImage(image: self.image!, key: imageKey, bucket: S3.sharedService.imageBucket, shared: true)
        }
        self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func isContentValid() -> Bool {
        if !self.contentText.isEmpty && self.patch != nil {
            return true
        }
        return false
    }
    
    func showPatchPicker(){
        
        let storyboard = UIStoryboard(name: "PatchrShare", bundle: NSBundle.mainBundle())
        if let controller = storyboard.instantiateViewControllerWithIdentifier("PatchTargetViewController") as? PatchTargetViewController {
            controller.patch = patchConfigurationItem.value
            controller.delegate = self
            controller.preferredContentSize = CGSizeMake(300, 300)
            pushConfigurationViewController(controller)
        }
    }
    
    func buildMessage(imageKey: String) -> [String:AnyObject] {
        
        let links = Array(arrayLiteral: [
            "type": "content",
            "_to": self.patchId
            ]) as [[String:AnyObject]]
        
        let description = self.contentText
        
        var message = [
            "description": description,
            "links": links
            ] as [String:AnyObject]
        
        if self.image != nil {
            let photo = [
                "width": Int(self.image!.size.width), // width/height are in points...should be pixels?
                "height": Int(self.image!.size.height),
                "source": "aircandi.images",
                "prefix": imageKey]
            message["photo"] = photo
        }
        
        let body = [
            "user": self.userId!,
            "session": self.sessionKey!,
            "data": message
            ] as [String:AnyObject]
        
        return body
    }
    
    override func configurationItems() -> [AnyObject]! {
        return [patchConfigurationItem]
    }
}

extension ShareViewController: PatchTargetViewControllerDelegate {
    
    func patchPickerViewController(sender: PatchTargetViewController, selectedValue: AnyObject) {
        /*
         * Patch has been selected
         */
        if let patch = selectedValue as? [String:AnyObject] {
            patchConfigurationItem.value = patch["name"] as! String
            self.patch = patch
            if patch["id_"] != nil {
                self.patchId = patch["id_"] as! String
            }
            else if patch["_id"] != nil {
                self.patchId = patch["_id"] as! String
            }
            validateContent()
        }
        popConfigurationViewController()
    }
}