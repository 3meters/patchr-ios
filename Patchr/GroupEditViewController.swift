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

    func doneAction(sender: AnyObject) {
        /* We are updating in realtime */
        closeAction(sender: sender)
    }

    func closeAction(sender: AnyObject) {
        if isValid() {
            close()
        }
    }
    
    func manageUsersAction(sender: AnyObject?) {
        let controller = MemberListController()
        controller.scope = .group
        controller.manage = true
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func deleteAction(sender: AnyObject) {

        guard !self.processing else { return }
        
        DeleteConfirmationAlert(
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
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if textField == self.titleField {
            if isValid() {
                FireController.db.child(self.group.path).updateChildValues([
                    "modified_at": FIRServerValue.timestamp(),
                    "title": emptyToNull(self.titleField.text)
                    ])
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Notifications
     *--------------------------------------------------------------------------------------------*/
    
    override func photoDidChange(sender: NSNotification) {
        super.photoDidChange(sender: sender)
        
        let image = self.photoEditView.imageButton.image
        let path = self.group.path
        var photoMap: [String: Any]?
        photoMap = postPhoto(image: image!, progress: self.photoEditView.progressBlock, next: { error in
            if error == nil {
                photoMap!["uploading"] = NSNull()
                FireController.db.child(path).updateChildValues(["photo": photoMap!])
            }
        })
        
        FireController.db.child(path).updateChildValues([
            "modified_at": FIRServerValue.timestamp(),
            "photo": photoMap!
        ])
    }
    
    override func photoRemoved(sender: NSNotification) {
        super.photoRemoved(sender: sender)
        
        FireController.db.child(self.group.path).updateChildValues([
            "modified_at": FIRServerValue.timestamp(),
            "photo": NSNull()
        ])
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
        self.photoEditView.setHostController(controller: self)
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

        /* Navigation bar buttons */
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction(sender:)))
        let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(deleteAction(sender:)))
        self.navigationItem.rightBarButtonItems = [doneButton, deleteButton]
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(photoDidChange(sender:)), name: NSNotification.Name(rawValue: Events.PhotoDidChange), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photoRemoved(sender:)), name: NSNotification.Name(rawValue: Events.PhotoRemoved), object: nil)
    }

    func bind() {
        self.titleField.text = self.group.title
        
        if let photo = self.group.photo, photo.uploading == nil {
            if let photoUrl = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                self.photoEditView.configureTo(photoMode: .Photo)
                self.photoEditView.bind(url: photoUrl, fallbackUrl: ImageUtils.fallbackUrl(prefix: photo.filename!))
            }
        }
    }

    func delete() {
        FireController.instance.delete(groupId: self.group.id!, then: { updates in
            if updates != nil {
                StateController.instance.clearGroup()   // Make sure group and channel are both unset
                self.close(animated: true)
            }
        })
    }

    func isValid() -> Bool {

        if self.titleField.isEmpty {
            self.titleField.errorMessage = "Enter a name for the group."
            return false
        }

        return true
    }
}
