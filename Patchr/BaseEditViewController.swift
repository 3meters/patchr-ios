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

class BaseEditViewController: BaseViewController, UITextFieldDelegate, UITextViewDelegate {
	
	var activeTextField: UIView?
    
    var processing: Bool = false
    var progressStartLabel: String?
    var progressFinishLabel: String?
    var cancelledLabel: String?
    var progress: AirProgress?
    var firstAppearance	= true

    var mode: Mode = .insert
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
        NotificationCenter.default.addObserver(self, selector: #selector(photoViewHasFocus(sender:)), name: NSNotification.Name(rawValue: Events.PhotoViewHasFocus), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeShown(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.firstAppearance = false
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Events.PhotoViewHasFocus), object: nil)
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
        , progress: AWSS3TransferUtilityProgressBlock? = nil
        , next: ((Any?) -> Void)? = nil) -> [String: Any] {
        
        /* Ensure image is resized/rotated before upload */
        let preparedImage = Utils.prepareImage(image: image)
        
        /* Generate image key */
        let imageKey = "\(Utils.genImageKey()).jpg"
        
        let photoMap = [
            "width": Int(preparedImage.size.width), // width/height are in points...should be pixels?
            "height": Int(preparedImage.size.height),
            "source": S3.sharedService.imageSource,
            "filename": imageKey,
            "uploading": true
            ] as [String: Any]
        
        /* Upload */
        DispatchQueue.global().async {
            S3.sharedService.upload(
                image: preparedImage,
                imageKey: imageKey,
                progress: progress,
                completionHandler: { task, error in
                    if error != nil {
                        Log.w("Image upload error: \(error!.localizedDescription)")
                    }
                    next?(error)
            })
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
    
    enum Mode: Int {
        case insert
        case update
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
