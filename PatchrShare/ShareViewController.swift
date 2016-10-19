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
        item?.title = "Patch"
        item?.value = PatchTargetViewController.defaultPatch()
        item?.tapHandler = self.showPatchPicker
        return item!
    }()
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let groupDefaults = UserDefaults(suiteName: "group.com.3meters.patchr.ios") {
			let lockbox = Lockbox(keyPrefix: KEYCHAIN_GROUP)
            self.userId = groupDefaults.string(forKey: PatchrUserDefaultKey(subKey: "userId"))
			self.sessionKey = lockbox?.unarchiveObject(forKey: "sessionKey") as? String
        }
        /*
        * ISSUE: User info won't be there if the user uses is not currently signed into Patchr.
        * So we alert and bail when this case is detected.
        */
        if self.userId == nil {
            let alert = UIAlertController(title: "Patchr sign in",
                message: "To share messages and photos to Patchr, you need to be signed in.",
                preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel) { _ in
                self.cancel()
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        
        Log.d("Presenting patchr extension")
        placeholder = "Your comments"
        
        for item: Any in self.extensionContext!.inputItems {
            
            let inputItem = item as! NSExtensionItem
            for provider in inputItem.attachments as! [NSItemProvider] {
                
                Log.d("Provider type: \(provider.registeredTypeIdentifiers)")
                
                /* Check for image */
                
                var hasImage: Bool = false
                if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String)
                    || provider.hasItemConformingToTypeIdentifier("public.image") {
                    
                    hasImage = true
                    let dispatchQueue = DispatchQueue.global()
                    dispatchQueue.async(execute: {[weak self] in
                        
                        let strongSelf = self!
                        
                        var identifier = "public.image"
                        if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                            identifier = kUTTypeImage as String
                        }
                        
                        provider.loadItem(forTypeIdentifier: identifier, options: nil) {
                            content, error in
                            Log.d("Processing image")
                            Log.d("Content: \(content)")
                            
                            if error == nil {
                                if let url = content as? NSURL {
                                    Log.d("As NSURL...")
                                    if let data = NSData(contentsOf: url as URL) {
                                        DispatchQueue.main.async(execute: {
                                            strongSelf.image = UIImage(data: data as Data)
                                            strongSelf.validateContent()
                                        })
                                    }
                                }
                                else if let data = content as? NSData {
                                    Log.d("As NSData...")
                                    DispatchQueue.main.async(execute: {
                                        strongSelf.image = UIImage(data: data as Data)
                                        strongSelf.validateContent()
                                    })
                                }
                                else if let image = content as? UIImage {
                                    Log.d("As UIImage...")
                                    DispatchQueue.main.async(execute: {
                                        strongSelf.image = image
                                        strongSelf.validateContent()
                                    })
                                }
                            }
                            else {
                                let alert = UIAlertController(title: "Error", message: "Error loading image", preferredStyle: .alert)
                                let action = UIAlertAction(title: "Error", style: .cancel) { _ in
                                    strongSelf.dismiss(animated: true, completion: nil)
                                }
                                
                                alert.addAction(action)
                                strongSelf.present(alert, animated: true, completion: nil)
                            }
                        }
                    })
                }
                
                /* Check for url. We ignore it if we already have an image */
                
                if !hasImage {
                    if provider.hasItemConformingToTypeIdentifier("public.url") {
                        let dispatchQueue = DispatchQueue.global()
                        dispatchQueue.async(execute: {[weak self] in
                            
                            let strongSelf = self!
                            
                            provider.loadItem(forTypeIdentifier: "public.url", options: nil) {
                                content, error in
                                Log.d("Processing url")
                                
                                if error == nil {
                                    if let url = content as? NSURL {
                                        Log.d("Found url!: \(url.absoluteString)")
                                        /*
                                         * When sharing url from chrome, the textView is set to the page
                                         * title so is not empty.
                                         */
                                        DispatchQueue.main.async() {
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
        let message = buildMessage(imageKey: imageKey)
        Proxibase.sharedService.postMessage(message: message, patch: self.patch!)
        if self.image != nil {
            S3.sharedService.uploadImage(image: self.image!, key: imageKey, bucket: S3.sharedService.imageBucket, shared: true)
        }
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
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
        
        let storyboard = UIStoryboard(name: "PatchrShare", bundle: Bundle.main)
        if let controller = storyboard.instantiateViewController(withIdentifier: "PatchTargetViewController") as? PatchTargetViewController {
            controller.patch = patchConfigurationItem.value
            controller.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            pushConfigurationViewController(controller)
        }
    }
    
    func buildMessage(imageKey: String) -> [String:AnyObject] {
        
        let links = [[
            "type": "content" as AnyObject,
            "_to": self.patchId as AnyObject
            ]] as [[String:AnyObject]]
        
        let description = self.contentText
        
        var message: [String:AnyObject] = [
            "description": description as AnyObject,
            "links": links as AnyObject
            ]
        
        if self.image != nil {
            let photo = [
                "width": Int(self.image!.size.width), // width/height are in points...should be pixels?
                "height": Int(self.image!.size.height),
                "source": "aircandi.images",
                "prefix": imageKey] as [String : Any]
            message["photo"] = photo as AnyObject?
        }
        
        let body = [
            "user": self.userId! as AnyObject,
            "session": self.sessionKey! as AnyObject,
            "data": message as AnyObject
            ] as [String:AnyObject]
        
        return body
    }
    
    override func configurationItems() -> [Any]! {
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
