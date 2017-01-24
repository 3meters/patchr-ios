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
        , asset: PHAsset?
        , progress: AWSS3TransferUtilityProgressBlock? = nil
        , next: ((Any?) -> Void)? = nil) -> [String: Any] {
        
        /* Ensure image is resized/rotated before upload */
        let preparedImage = Utils.prepareImage(image: image)
        
        /* Generate image key */
        let imageKey = "\(Utils.genImageKey()).jpg"
        
        var photoMap = [
            "width": Int(preparedImage.size.width), // width/height are in points...should be pixels?
            "height": Int(preparedImage.size.height),
            "source": S3.instance.imageSource,
            "filename": imageKey,
            "uploading": true ] as [String: Any]
        
        if asset != nil {
            if let takenDate = asset!.creationDate {
                photoMap["taken_at"] = Int64(takenDate.timeIntervalSince1970 * 1000)
                Log.d("Photo taken: \(takenDate)")
            }
            if let coordinate = asset!.location?.coordinate {
                photoMap["location"] = ["lat": coordinate.latitude, "lng": coordinate.longitude]
                Log.d("Photo lat/lng: \(coordinate)")
            }
        }
        
        /* Prime the cache so offline has something to work with */
        ImageUtils.addImageToCache(image: image, url: URL(string: "https://\(imageKey)")!)
        
        /* Upload */
        DispatchQueue.global().async {
            S3.instance.upload(image: preparedImage, imageKey: imageKey, progress: progress) { task, error in
                if error != nil {
                    Log.w("*** S3 image upload stopped with error: \(error!.localizedDescription)")
                }
                else {
                    Log.w("*** S3 image upload complete: \(imageKey)")
                }
                next?(error)
            }
        }
        
        return photoMap
    }
    
    func showError(_ textField: TextFieldView, error: String) {
        textField.setErrorText(text: error)
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded(animated: true)
    }
    
    func clearErrorIfNeeded(_ textField: TextFieldView) {
        if textField.errorLabel.text != nil {
            textField.setErrorText(text: nil)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded(animated: true)
        }
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
    
    enum Flow: Int {
        case onboardLogin
        case onboardCreate
        case onboardInvite
        case internalCreate
        case none
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
