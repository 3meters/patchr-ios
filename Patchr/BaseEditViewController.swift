//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import Firebase
import Photos
import FirebaseStorage

class BaseEditViewController: BaseViewController, UITextFieldDelegate, UITextViewDelegate {
	
	var activeTextField: UIView?
    
    var processing: Bool = false
    var progressStartLabel: String?
    var progressFinishLabel: String?
    var cancelledLabel: String?
    var progress: AirProgress?
    var firstAppearance	= true

    var mode: Mode = .none
    var flow: Flow = .none
    var branch: Branch = .none
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.firstAppearance = false
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
    
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	func photoViewHasFocus(sender: NSNotification) {
		self.view.endEditing(true)
	}
	
	func photoDidChange(sender: NSNotification) {
		viewWillLayoutSubviews()
	}
    
    func photoRemoved(sender: NSNotification) {
        viewWillLayoutSubviews()
    }

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	override func initialize() {
		super.initialize()
	}
    
    func postPhoto(image: UIImage
        , asset: Any?
        , progress: AWSS3TransferUtilityProgressBlock? = nil
        , next: ((Any?) -> Void)? = nil) -> [String: Any] {
        
        /* Ensure image is resized/rotated before upload */
        let preparedImage = ImageUtils.prepareImage(image: image)
        
        /* Generate image key */
        let imageKey = "\(Utils.genImageKey()).jpg"
        
        var photoMap = [
            "width": Int(preparedImage.size.width), // width/height are in points...should be pixels?
            "height": Int(preparedImage.size.height),
            "source": GoogleStorage.imageSource,
            "filename": imageKey,
            "uploading": true ] as [String: Any]
        
        if let asset = asset as? PHAsset {
            if let takenDate = asset.creationDate {
                photoMap["taken_at"] = takenDate.milliseconds
                Log.d("Photo taken: \(takenDate)")
            }
            if let coordinate = asset.location?.coordinate {
                photoMap["location"] = ["lat": coordinate.latitude, "lng": coordinate.longitude]
                Log.d("Photo lat/lng: \(coordinate)")
            }
        }
        else if let asset = asset as? [String: Any] {
            if let takenDate = asset["taken_at"] as? Int {
                photoMap["taken_at"] = takenDate
                Log.d("Photo taken: \(takenDate)")
            }
        }
        
        let imageData = UIImageJPEGRepresentation(image, /*compressionQuality*/ 0.70)!
        
        /* Prime the cache so offline has something to work with */
//        let photoUrlStandard = ImageProxy.url(prefix: imageKey, category: SizeCategory.standard)
//        let photoUrlProfile = ImageProxy.url(prefix: imageKey, category: SizeCategory.profile)
//        ImageUtils.storeImageDataToCache(imageData: imageData, key: photoUrlProfile.absoluteString)
//        ImageUtils.storeImageDataToCache(imageData: imageData, key: photoUrlStandard.absoluteString)
        
        /* Upload */
        DispatchQueue.global(qos: .userInitiated).async {
            
            GoogleStorage.instance.upload(imageData: imageData, imageKey: imageKey) { snapshot in
                if snapshot.status == .failure {
                    next?(snapshot.error)
                }
                else if snapshot.status == .success {
                    Log.d("*** Google storage image upload complete: \(imageKey)")
                    next?(nil)
                }
            }

//            S3.instance.upload(imageData: imageData, imageKey: imageKey, progress: progress) { task, error in
//                Log.w(error != nil
//                    ? "*** S3 image upload stopped with error: \(error!.localizedDescription)"
//                    : "*** S3 image upload complete: \(imageKey)")
//                next?(error)
//            }
        }
        
        return photoMap
    }
    
	func keyboardWillBeShown(sender: NSNotification) {
		/*
		* Called when the UIKeyboardDidShowNotification is sent.
		*/
		let info: NSDictionary = sender.userInfo! as NSDictionary
		let value = info.value(forKey: UIKeyboardFrameBeginUserInfoKey) as! NSValue
		let keyboardSize = value.cgRectValue.size
		
		self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, keyboardSize.height, 0)
		self.scrollView.scrollIndicatorInsets = scrollView.contentInset
		
		/*
		* If active text field is hidden by keyboard, scroll it so it's visible
		*/
		if self.activeTextField != nil {
			var visibleRect = self.view.frame
			visibleRect.size.height -= keyboardSize.height
			
			let activeTextFieldRect = self.activeTextField?.frame
			let activeTextFieldOrigin = activeTextFieldRect?.origin
			
			if (!visibleRect.contains(activeTextFieldOrigin!)) {
				self.scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
			}
		}
	}
 
	func keyboardWillBeHidden(sender: NSNotification) {
		/*
		* Called when the UIKeyboardWillHideNotification is sent.
		*/
		self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, 0, 0)
		self.scrollView.scrollIndicatorInsets = scrollView.contentInset
	}
    
    enum Branch: Int {
        case login
        case signup
        case none
    }

    enum Mode: Int {
        case insert
        case update
        case reauth
        case none
    }
}

extension BaseEditViewController {
    
	/* UITextFieldDelegate */
    
	func textFieldDidBeginEditing(_ textField: UITextField) {
		self.activeTextField = textField
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if self.activeTextField == textField {
			self.activeTextField = nil
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return true
	}
    
    /* UITextViewDelegate */
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let textView = textView as? AirTextView {
            self.activeTextField = textView
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if self.activeTextField == textView {
            self.activeTextField = nil
        }
    }
}
