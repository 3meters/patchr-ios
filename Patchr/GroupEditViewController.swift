//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import MBProgressHUD
import Facade
import Firebase

class GroupEditViewController: BaseEditViewController {

    var group: FireGroup!

    var banner = AirLabelTitle()
    var message = AirLabelDisplay()
    var photoEditView = PhotoEditView()
    var titleField = FloatTextField(frame: CGRect.zero)
    var usersButton = AirButton()
    var doneButton: UIBarButtonItem!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        self.group = StateController.instance.group
        self.bind()
    }

    override func viewWillLayoutSubviews() {
        /*
         * Triggers
         * - addSubview called on self.view
         * - setting frame on self.view if size is different
         * - scrolling when self.view is a scrollview
         */
        let bannerSize = self.banner.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))

        self.banner.anchorTopCenter(withTopPadding: 0, width: 288, height: bannerSize.height)
        self.message.alignUnder(self.banner, matchingCenterWithTopPadding: 8, width: 288, height: messageSize.height)
        self.photoEditView.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 150, height: 150)
        self.titleField.alignUnder(self.photoEditView, matchingCenterWithTopPadding: 16, width: 288, height: 48)
        self.usersButton.alignUnder(self.titleField, matchingCenterWithTopPadding: 16, width: 288, height: 48)

        super.viewWillLayoutSubviews()
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func closeAction(sender: AnyObject) {
        if !isDirty() {
            self.close(animated: true)
            return
        }
        
        DeleteConfirmationAlert(
            title: "Do you want to discard your editing changes?",
            actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.close(animated: true)
                }
        }
    }
    
    func doneAction(sender: AnyObject) {
        guard !self.processing else { return }
        
        self.activeTextField?.resignFirstResponder()
        isValid() { valid in
            if valid {
                self.post()
            }
        }
    }
    
    func deleteAction(sender: AnyObject) {

        guard !self.processing else { return }
        
        FireController.instance.isConnected() { connected in
            if connected == nil || !connected! {
                let message = "Deleting a group requires a network connection."
                self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
            }
            else {
                self.DeleteConfirmationAlert(
                    title: "Confirm group delete",
                    message: "Deleting the group will erase all channels and messages for the group and cannot be undone. Enter YES to confirm.",
                    actionTitle: "Delete",
                    cancelTitle: "Cancel",
                    destructConfirmation: true,
                    delegate: self) { doIt in
                        if doIt {
                            self.delete()
                        }
                }
            }
        }
    }
    
    func manageUsersAction(sender: AnyObject?) {
        let controller = MemberListController()
        controller.scope = .group
        controller.manage = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        self.doneButton.isEnabled = isDirty()
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        self.doneButton.isEnabled = isDirty()
    }

    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    override func photoDidChange(sender: NSNotification) {
        super.photoDidChange(sender: sender)
        self.doneButton.isEnabled = isDirty()
    }
    
    override func photoRemoved(sender: NSNotification) {
        super.photoRemoved(sender: sender)
        self.doneButton.isEnabled = isDirty()
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.banner.textColor = Theme.colorTextTitle
        self.banner.numberOfLines = 0
        self.banner.textAlignment = .center

        self.message.numberOfLines = 0
        self.message.textAlignment = .center

        self.photoEditView.photoSchema = Schema.ENTITY_PATCH
        self.photoEditView.setHost(controller: self, view: self.photoEditView)
        self.photoEditView.configureTo(photoMode: .Placeholder)

        self.titleField.placeholder = "Group Name"
        self.titleField.delegate = self
        self.titleField.autocapitalizationType = .none
        self.titleField.autocorrectionType = .no
        self.titleField.keyboardType = .default
        self.titleField.returnKeyType = .next
        
        self.usersButton.setTitle("Manage Group Members".uppercased(), for: .normal)
        self.usersButton.imageRight = UIImageView(image: UIImage(named: "imgArrowRightLight"))
        self.usersButton.imageRight?.bounds.size = CGSize(width: 10, height: 14)
        self.usersButton.addTarget(self, action: #selector(manageUsersAction(sender:)), for: .touchUpInside)
        
        self.contentHolder.addSubview(self.banner)
        self.contentHolder.addSubview(self.message)
        self.contentHolder.addSubview(self.photoEditView)
        self.contentHolder.addSubview(self.titleField)
        self.contentHolder.addSubview(self.usersButton)

        Reporting.screen("GroupEdit")
        self.banner.text = "Group Settings"
        
        /* Delete */
        self.navigationController?.setToolbarHidden(false, animated: true)
        let deleteIconButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(deleteAction(sender:)))
        let deleteTitleButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteAction(sender:)))
        deleteIconButton.tintColor = Colors.brandColor
        deleteTitleButton.tintColor = Colors.brandColor
        self.toolbarItems = [spacerFlex, deleteIconButton, deleteTitleButton]

        /* Navigation bar buttons */
        if self.presented {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.doneButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
            self.doneButton.isEnabled = false
            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        self.titleField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        self.titleField.text = self.group.title
        
        if let photo = self.group.photo {
            self.photoEditView.configureTo(photoMode: .Photo)
            if photo.uploading != nil {
                self.photoEditView.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, uploading: true)
            }
            else if let photoUrl = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.bind(url: photoUrl, fallbackUrl: ImageUtils.fallbackUrl(prefix: photo.filename!))
            }
        }
    }
    
    func post() {
        self.processing = true
        
        var updates = [String: Any]()
        if emptyToNil(self.titleField.text) != self.group!.title {
            updates["title"] = emptyToNull(self.titleField.text)
        }
        if self.photoEditView.photoDirty {
            if self.photoEditView.photoActive {
                let image = self.photoEditView.imageButton.image
                let asset = self.photoEditView.imageButton.asset
                let path = self.group.path
                var photoMap: [String: Any]?
                photoMap = postPhoto(image: image!, asset: asset, progress: self.photoEditView.progressBlock, next: { error in
                    if error == nil {
                        photoMap!["uploading"] = NSNull()
                        FireController.db.child(path).updateChildValues(["photo": photoMap!])
                    }
                })
                updates["photo"] = photoMap!
            }
            else {
                updates["photo"] = NSNull()
            }
        }
        
        if updates.keys.count > 0 {
            updates["modified_at"] = FIRServerValue.timestamp()
            FireController.db.child(self.group.path).updateChildValues(updates)
        }
        self.close(animated: true)
    }

    func delete() {
        FireController.instance.deleteGroup(groupId: self.group.id!, then: { updates in
            if updates != nil {
                StateController.instance.clearGroup()   // Both group and channel are unset
                self.close(animated: true)
            }
        })
    }
    
    func isDirty() -> Bool {
        if !stringsAreEqual(string1: self.titleField.text, string2: self.group.title) {
            return true
        }
        if self.photoEditView.photoDirty {
            return true
        }
        return false
    }

    func isValid(then: @escaping (Bool) -> Void) {
        if self.titleField.isEmpty {
            self.titleField.errorMessage = "Enter a title for the group."
            then(false)
            return
        }
        then(true)
    }
}
