//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import THContactPicker
import MBProgressHUD

enum MessageType: Int {
    case Content
    case Share
}

class MessageEditViewController: BaseEditViewController, UITableViewDelegate, UITableViewDataSource {

    var inputState			: State? = State.Editing
    var inputMessageType	: MessageType = .Content
    var inputEntity			: Entity?
    var inputToString		: String?     // name of patch this message links to
    var inputPatchId		: String?     // id of patch this message links to

    var inputShareId		: String?
    var inputShareSchema	: String = Schema.PHOTO
    var inputShareEntity	: Entity?

    var processing			: Bool = false
    var progressStartLabel	: String?
    var progressFinishLabel	: String?
    var cancelledLabel		: String?
    var schema				= Schema.ENTITY_MESSAGE
    var progress			: AirProgress?
    var insertedEntity		: Entity?
    var firstAppearance		= true

    var imageUploadRequest	: AWSS3TransferManagerUploadRequest?
    var entityPostRequest	: URLSessionTask?

    var descriptionDefault	: String!

    let contactsSelected	: NSMutableArray = NSMutableArray()
    var contactModels		: NSMutableArray = NSMutableArray()
    var contactList			: UITableView?

    var searchInProgress    = false
    var searchTimer			: Timer?
    var searchEditing       = false
    var searchText			: String = ""

    var addressGroup		= AirRuleView()
    var addressField		= AirContactPicker()
    var addressLabel		= AirLabelDisplay()

    var userPhoto			= PhotoView()
    var userName			= AirLabelDisplay()
    var descriptionField	= AirTextView()
    var photoView			= PhotoEditView()

    var messageView			: MessageView?
    var patchView			: PatchView?
    var doneButton			= AirFeaturedButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)
        let contentWidth = CGFloat(viewWidth - 32)
        self.view.bounds.size.width = viewWidth
        self.contentHolder.bounds.size.width = viewWidth

        let descriptionSize = self.descriptionField.sizeThatFits(CGSize(width:contentWidth, height:CGFloat.greatestFiniteMagnitude))
        let navHeight = self.navigationController?.navigationBar.height() ?? 0
        let statusHeight = UIApplication.shared.statusBarFrame.size.height

        if self.inputState == .Sharing {

            self.userPhoto.anchorTopLeft(withLeftPadding: 16, topPadding: 8, width: 48, height: 48)
            self.addressField.setNeedsLayout()
            self.addressField.layoutIfNeeded()
            self.addressField.anchorTopLeft(withLeftPadding: 72, topPadding: 12, width: contentWidth - 56, height: self.addressField.height())
            self.contactList!.alignUnder(self.addressField, matchingLeftAndRightWithTopPadding: 0, height: CGFloat(self.contactModels.count * 52))
            self.addressGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: CGFloat(statusHeight + navHeight), height: self.contactList!.height() + self.addressField.height() + 24)
            self.descriptionField.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: contentWidth, height: max(96, descriptionSize.height))

            if self.inputShareSchema == Schema.ENTITY_PATCH {
                self.patchView!.alignUnder(self.descriptionField, matchingLeftAndRightWithTopPadding: 8, height: 128)
            }
            else {
                self.messageView!.alignUnder(self.descriptionField, matchingRightAndFillingWidthWithLeftPadding: 0, topPadding: 16, height: 400)
            }
        }
        else {
            self.addressGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: CGFloat(statusHeight + navHeight), height: 64)
            self.userPhoto.anchorCenterLeft(withLeftPadding: 16, width: 48, height: 48)
            self.addressLabel.fillSuperview(withLeftPadding: 72, rightPadding: 8, topPadding: 0, bottomPadding: 0)
            self.descriptionField.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: contentWidth, height: max(96, descriptionSize.height))
            self.photoView.alignUnder(self.descriptionField, matchingLeftAndRightWithTopPadding: 8, height: self.photoView.photoMode == .Empty ? 48 : contentWidth * 0.75)
        }

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.width(), height: self.contentHolder.height() + CGFloat(32))
        self.scrollView.alignUnder(self.addressGroup, centeredFillingWidthAndHeightWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 8, height: self.contentHolder.height() + 32)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.inputState == State.Sharing {
            self.addressField.becomeFirstResponder()
        }
        else if self.inputState == State.Creating && self.firstAppearance  {
            self.descriptionField.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.firstAppearance = false
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject){

        guard isValid() else { return }
        guard !self.processing else { return }

        self.progress = AirProgress.showAdded(to: self.view.window!, animated: true)
        self.progress!.mode = MBProgressHUDMode.indeterminate
        self.progress!.styleAs(progressStyle: .ActivityWithText)
        self.progress!.labelText = self.progressStartLabel!
        self.progress!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MessageEditViewController.userCancelTaskAction(sender:))))
        self.progress!.removeFromSuperViewOnHide = true
        self.progress!.show(true)

        Utils.delay(5.0) {
            self.progress?.detailsLabelText = "Tap to cancel"
        }

        let parameters = self.gather()
        post(parameters: parameters)
    }

    func cancelAction(sender: AnyObject){

        if !isDirty() {
            self.performBack(animated: true)
            return
        }

        DeleteConfirmationAlert(
            title: "Do you want to discard your editing changes?",
            actionTitle: "Discard", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.performBack(animated: true)
                }
        }
    }

    func deleteAction(sender: AnyObject) {

        guard !self.processing else { return }

        DeleteConfirmationAlert(
            title: "Confirm Delete",
            message: "Are you sure you want to delete this?",
            actionTitle: "Delete", cancelTitle: "Cancel", delegate: self) {
                doIt in
                if doIt {
                    self.delete()
                }
        }
    }

    func userCancelTaskAction(sender: AnyObject) {
        if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
            hud.animationType = MBProgressHUDAnimation.zoomIn
            hud.hide(true)
            let _ = self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
            self.entityPostRequest?.cancel()
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {

        self.view.backgroundColor = Theme.colorBackgroundForm

        let viewWidth = min(CONTENT_WIDTH_MAX, self.view.bounds.size.width)

        let fullScreenRect = UIScreen.main.applicationFrame
        self.scrollView.frame = fullScreenRect
        self.scrollView.backgroundColor = Theme.colorBackgroundForm
        self.scrollView.bounces = true
        self.scrollView.alwaysBounceVertical = true

        self.photoView.photoSchema = Schema.ENTITY_MESSAGE
        self.photoView.setHostController(controller: self)
        self.photoView.configureTo(photoMode: self.inputEntity?.photo != nil ? .Photo : .Empty)

        self.descriptionField = AirTextView()
        self.descriptionField.placeholderLabel.text = "What\'s happening?"
        self.descriptionField.placeholderLabel.insets = UIEdgeInsetsMake(0, 0, 0, 0)
        self.descriptionField.initialize()
        self.descriptionField.delegate = self

        self.userPhoto.contentMode = UIViewContentMode.scaleAspectFill
        self.userPhoto.clipsToBounds = true
        self.userPhoto.layer.cornerRadius = 24

        self.addressGroup.backgroundColor = UIColor(red: CGFloat(0.98), green: CGFloat(0.98), blue: CGFloat(0.98), alpha: CGFloat(1))
        self.addressGroup.thickness = 0.5

        self.addressGroup.addSubview(self.addressLabel)
        self.addressGroup.addSubview(self.addressField)
        self.addressGroup.addSubview(self.userPhoto)

        self.contentHolder.addSubview(self.descriptionField)
        self.contentHolder.addSubview(self.photoView)
        self.scrollView.addSubview(self.contentHolder)

        self.view.addSubview(self.addressGroup)
        self.view.addSubview(self.scrollView)

        if self.inputState == State.Sharing {

            self.photoView.isHidden = true
            self.addressLabel.isHidden = true

            self.addressField.setPlaceholderLabelText("Who would you like to invite?")
            self.addressField.setPromptLabelText("To: ")
            self.addressField.delegate = self

            self.contactList = UITableView(frame: CGRect.zero, style: .plain)
            self.contactList!.delegate = self;
            self.contactList!.dataSource = self;
            self.contactList!.rowHeight = 52

            self.addressGroup.addSubview(self.contactList!)

            if self.inputShareSchema == Schema.ENTITY_PATCH {

                Reporting.screen("PatchInvite")

                self.progressStartLabel = "Inviting"
                self.progressFinishLabel = "Invites sent"
                self.cancelledLabel = "Invites cancelled"

                self.patchView = PatchView(frame: CGRect(x:0, y:0, width:viewWidth, height:136))
                self.patchView!.borderColor = Theme.colorButtonBorder
                self.patchView!.borderWidth = Theme.dimenButtonBorderWidth
                self.patchView!.cornerRadius = 6
                self.patchView!.shadow.backgroundColor = Colors.clear

                self.contentHolder.addSubview(self.patchView!)

                self.descriptionField.placeholderLabel.text = "Add a message to your invite..."
                self.navigationItem.title = "Invite to patch"
                self.descriptionDefault = "\(UserController.instance.currentUser.name) invited you to the \'\(self.inputShareEntity!.name!)\' patch."
            }

            else if self.inputShareSchema == Schema.ENTITY_MESSAGE {

                Reporting.screen("MessageShare")

                self.progressStartLabel = "Sharing"
                self.progressFinishLabel = "Shared"
                self.cancelledLabel = "Sharing cancelled"

                self.messageView = MessageView()
                self.contentHolder.addSubview(self.messageView!)

                self.descriptionField.placeholderLabel.text = "Add a message..."
                self.navigationItem.title = Utils.LocalizedString(str: "Share posted message")
                if let message = self.inputShareEntity as? Message {
                    if message.patch != nil {
                        self.descriptionDefault = "\(UserController.instance.currentUser.name) shared \(message.creator.name!)\'s message posted to the \'\(message.patch.name)\' patch."
                    }
                    else {
                        self.descriptionDefault = "\(UserController.instance.currentUser.name) shared \(message.creator.name!)\'s message posted to a patch."
                    }
                }
            }

            /* Navigation bar buttons */
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(MessageEditViewController.cancelAction(sender:)))
            let doneButton = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {

            self.addressField.isHidden = true

            self.descriptionField.placeholderLabel.text = "What\'s happening?"

            if self.inputState == State.Creating {
                Reporting.screen("MessageNew")
                self.progressStartLabel = "Posting"
                self.progressFinishLabel = "Posted"
                self.cancelledLabel = "Post cancelled"

                /* Navigation bar buttons */
                let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(MessageEditViewController.cancelAction(sender:)))
                let doneButton = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
                self.navigationItem.leftBarButtonItems = [cancelButton]
                self.navigationItem.rightBarButtonItems = [doneButton]
            }
            else {
                Reporting.screen("MessageEdit")
                self.progressStartLabel = "Updating"
                self.progressFinishLabel = "Updated"
                self.cancelledLabel = "Update cancelled"

                self.doneButton.isHidden = true

                /* Navigation bar buttons */
                self.navigationItem.title = "Edit message"
                let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(MessageEditViewController.cancelAction(sender:)))
                let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(MessageEditViewController.deleteAction(sender:)))
                let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(MessageEditViewController.doneAction(sender:)))
                self.navigationItem.leftBarButtonItems = [cancelButton]
                self.navigationItem.rightBarButtonItems = [doneButton, Utils.spacer, deleteButton]
            }
        }
    }

    func bind() {

        if let message = self.inputEntity as? Message {
            self.userPhoto.bindToEntity(entity: message.creator)
            self.userName.text = message.creator.name
        }
        else if let user = UserController.instance.currentUser {
            self.userPhoto.bindToEntity(entity: user)
            self.userName.text = user.name
        }

        if self.inputState == .Editing {
            self.addressLabel.text = (self.inputEntity as! Message).patch?.name
            self.descriptionField.text = self.inputEntity!.description_
            self.photoView.bindPhoto(photo: self.inputEntity!.photo)
            textViewDidChange(self.descriptionField)
        }
        else if self.inputState == .Creating {
            self.addressLabel.text = self.inputToString! + " Patch"
        }
        else if self.inputState == .Sharing {
            if self.inputShareSchema == Schema.ENTITY_PATCH {
                self.patchView!.bindToEntity(entity: self.inputShareEntity!, location: nil)
            }
            else {
                self.messageView!.bindToEntity(entity: self.inputShareEntity!, location: nil)
                self.messageView!.setNeedsLayout()
                self.messageView!.layoutIfNeeded()
            }
        }
    }

    @discardableResult func post(parameters: [String: Any]) -> TaskQueue {
        /*
         * Has external dependencies: progress, tasks, processing flag.
         */
        self.processing = true
        var cancelled = false
        let queue = TaskQueue()
        var parameters = parameters
        
        /* Process image if any */

        if var image = parameters["photo"] as? UIImage {
            queue.tasks +=~ { _, next in

                /* Ensure image is resized/rotated before upload */
                image = Utils.prepareImage(image: image)

                /* Generate image key */
                let imageKey = "\(Utils.genImageKey()).jpg"

                /* Upload */
                self.imageUploadRequest = S3.sharedService.uploadImageToS3(image: image, imageKey: imageKey) {
                    task in

                    if let err = task.error {
                        if task.isCancelled {
                            cancelled = true
                        }
                        queue.skip()
                        next(Result(response: nil, error: err as NSError?))
                    }
                    else {
                        let photo = [
                            "width": Int(image.size.width), // width/height are in points...should be pixels?
                            "height": Int(image.size.height),
                            "source": S3.sharedService.imageSource,
                            "prefix": imageKey
                        ] as [String : Any]
                        parameters["photo"] = photo
                        next(nil)
                    }
                }
            }
        }

        /* Upload entity */

        queue.tasks +=~ { _, next in
            let endpoint = self.inputEntity == nil ? "data/messages" : "data/messages/\(self.inputEntity!.id_!)"
            self.entityPostRequest = DataController.proxibase.postEntity(path: endpoint, parameters: parameters) {
                response, error in
                if error == nil {
                    self.progress!.progress = 1.0
                }
                else if error!.code == NSURLErrorCancelled {
                    cancelled = true
                }
                next(Result(response: response as AnyObject?, error: error))
            }
        }

        /* Update Ui */

        queue.tasks +=! {
            self.processing = false

            if cancelled {
                UIShared.Toast(message: self.cancelledLabel)
                return
            }

            self.progress?.hide(true)

            if let result: Result = queue.lastResult as? Result {
                if let error = ServerError(result.error) {
                    self.handleError(error)
                    return
                }
                else {
                    if self.inputState == .Creating || self.inputState == .Sharing {

                        /* Update recent patch list when a user sends a message */
                        if self.inputState == .Creating {
                            if let patch = DataController.instance.currentPatch {
                                var recent: [String:AnyObject] = [
                                    "id_":patch.id_ as AnyObject,
                                    "name":patch.name as AnyObject,
                                    "recentDate": NSNumber(value: Utils.now()) // Only way to store Int64 as AnyObject
                                ]
                                if patch.photo != nil {
                                    recent["photo"] = patch.photo.asMap() as AnyObject?
                                }
                                Utils.updateRecents(recent: recent)
                            }
                        }

                        let serverResponse = ServerResponse(result.response)
                        if serverResponse.resultCount == 1 {
                            Log.d("Inserted message \(serverResponse.resultID)")
                            DataController.instance.activityDateInsertDeleteMessage = Utils.now()
                        }

                        if self.inputState == .Creating {
                            /* Used to trigger call to action UI */
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.DidInsertMessage), object: self)
                            Reporting.track("Created Message", properties: ["target": "Patch" as AnyObject])
                        }
                        else {
                            if self.inputShareSchema == Schema.ENTITY_PATCH {
                                Reporting.track("Sent Patch Invitation", properties: ["network": "Patchr" as AnyObject])
                            }
                            else if self.inputShareSchema == Schema.ENTITY_MESSAGE {
                                Reporting.track("Shared Message", properties: ["network": "Patchr" as AnyObject])
                            }
                        }
                    }
                    else {
                        Log.d("Updated message \(self.inputEntity!.id_)")
                        Reporting.track("Updated Message")
                    }
                }
            }

            self.performBack(animated: true)
            UIShared.Toast(message: self.progressFinishLabel)
        }

        /* Start tasks */

        queue.run()
        return queue
    }

    func delete() {

        self.processing = true

        let entityPath = "data/messages/\((self.inputEntity!.id_)!)"

        DataController.proxibase.deleteObject(path: entityPath) {
            response, error in

            OperationQueue.main.addOperation {
                self.processing = false

                if let error = ServerError(error) {
                    self.handleError(error)
                }
                else {
                    DataController.instance.mainContext.delete(self.inputEntity!)
                    DataController.instance.saveContext(wait: BLOCKING)
                    DataController.instance.activityDateInsertDeleteMessage = Utils.now()
                    Reporting.track("Deleted Message")
                    self.performBack()
                }
            }
        }
    }

    func suggest() {

        guard !self.searchInProgress else {
            return
        }

        self.searchInProgress = true
        let searchString = self.searchText

        Log.d("Suggest call: \(searchString)")

        let endpoint: String = "\(DataController.proxibase.serviceUri)suggest"
        let request = NSMutableURLRequest(url: NSURL(string: endpoint)! as URL)
        let session = URLSession.shared
        request.httpMethod = "POST"

        let body = [
            "users": true,
            "input": searchString.lowercased(),
            "limit":10] as [String:Any]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                data, response, error -> Void in

                self.searchInProgress = false
                self.contactModels.removeAllObjects()

                if error == nil {
                    let json:JSON = JSON(data: data!)
                    let results = json["data"]

                    for (index: _, subJson) in results {
                        let model = SuggestionModel()
                        model.contactTitle = subJson["name"].string
                        model.entityId = (subJson["_id"] != JSON.null) ? subJson["_id"].string : subJson["id_"].string

                        if subJson["photo"] != JSON.null {

                            let prefix = subJson["photo"]["prefix"].string
                            let source = subJson["photo"]["source"].string
                            let photoUrl = PhotoUtils.url(prefix: prefix!, source: source!, category: SizeCategory.profile)
                            model.contactImageUrl = photoUrl
                        }
                        self.contactModels.add(model)
                    }

                    DispatchQueue.main.async(execute: {
                        self.viewWillLayoutSubviews()
                        self.contactList?.reloadData()
                    })
                }
            })

            task.resume()
        }
        catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
    }

    func gather() -> [String: Any] {

        var parameters: [String: Any] = [:]
        
        if self.inputState == State.Creating {

            parameters["description"] = nilToNull(value: self.descriptionField.text as AnyObject?)
            parameters["photo"] = nilToNull(value: self.photoView.imageButton.image(for: .normal))
            parameters["links"] = [["type": "content", "_to": self.inputPatchId!]]
        }
        else if self.inputState == State.Editing {

            if self.descriptionField.text != self.inputEntity!.description_  {
                parameters["description"] = nilToNull(value: self.descriptionField.text as AnyObject?)
            }
            if self.photoView.photoDirty {
                parameters["photo"] = nilToNull(value: self.photoView.imageButton.image(for: .normal))
            }
        }
        else if self.inputState == .Sharing {

            let links = NSMutableArray()
            links.add(["type": "share", "_to": self.inputShareEntity!.id_!])
            for contact in self.contactsSelected {
                if let contact = contact as? SuggestionModel {
                    links.add(["type": "share", "_to": contact.entityId])
                }
            }
            parameters["links"] = links
            parameters["type"] = "share"

            if self.descriptionField.text == nil || self.descriptionField.text.isEmpty {
                parameters["description"] = self.descriptionDefault
            }
            else {
                parameters["description"] = self.descriptionField.text
            }
        }

        return parameters
    }

    func isDirty() -> Bool {

        if self.inputState == .Creating {
            if !self.descriptionField.text!.isEmpty {
                return true
            }
            if self.photoView.photoDirty {
                return true
            }
        }
        else if self.inputState == .Sharing {
            if !self.descriptionField.text!.isEmpty {
                return true
            }
        }
        else if self.inputState == .Editing {
            if !stringsAreEqual(string1: self.descriptionField.text, string2: self.inputEntity?.description_) {
                return true
            }
            if self.photoView.photoDirty {
                return true
            }
        }
        return false
    }

    func isValid() -> Bool {

        /* Share */
        if self.inputState == .Sharing {
            if self.contactsSelected.count == 0 {
                Alert(title: "Please add recipient(s)", message: nil, cancelButtonTitle: "OK")
                return false
            }
        }
        else {
            if ((self.descriptionField.text == nil || self.descriptionField.text!.isEmpty)
                && self.photoView.imageButton.image(for: .normal) == nil) {
                    Alert(title: "Add message or photo", message: nil, cancelButtonTitle: "OK")
                    return false
            }
        }
        return true
    }
}

extension MessageEditViewController: UITextViewDelegate {

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

    func textViewDidChange(_ textView: UITextView) {
        if let textView = textView as? AirTextView {
            textView.placeholderLabel.isHidden = !self.descriptionField.text.isEmpty
            self.viewWillLayoutSubviews()
        }
    }
}

extension MessageEditViewController {
    /*
    * UITableViewDelegate
    */
    @objc(tableView:cellForRowAtIndexPath:) func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER) as? UserSearchViewCell

        if cell == nil {
            cell = UserSearchViewCell(style: .default, reuseIdentifier: CELL_IDENTIFIER)
        }

        if let model = self.contactModels[indexPath.row] as? SuggestionModel {
            cell!.title.text = model.contactTitle
            cell!.photo.bindPhoto(photoUrl: model.contactImageUrl, name: model.contactTitle)
        }
        return cell!
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contactModels.count
    }

    @objc(tableView:didSelectRowAtIndexPath:) func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let model = self.contactModels[indexPath.row] as? SuggestionModel {
            if !self.contactsSelected.contains(model) {
                let style = THContactViewStyle(textColor: Theme.colorTextTitle, backgroundColor: Colors.white, cornerRadiusFactor: 6)
                let styleSelected = THContactViewStyle(textColor: Colors.white, backgroundColor: Theme.colorBackgroundContactSelected, cornerRadiusFactor: 6)
                self.contactsSelected.add(model)
                self.addressField.addContact(model, withName: model.contactTitle, with: style, andSelectedStyle: styleSelected )
            }
        }
        self.contactModels.removeAllObjects()
        self.viewWillLayoutSubviews()
        self.contactList?.reloadData()
        self.addressField.becomeFirstResponder()
    }
}

extension MessageEditViewController: THContactPickerDelegate {

    func contactPickerDidRemoveContact(_ contact: Any!) {
        self.contactsSelected.remove(contact)
    }

    func contactPickerDidResize(_ contactPickerView: THContactPickerView!) {
        self.viewWillLayoutSubviews()
    }

    func contactPickerTextFieldShouldReturn(_ textField: UITextField!) -> Bool {
        return true
    }

    func contactPickerTextViewDidChange(_ textViewText: String!) {
        let text = textViewText.trimmingCharacters(in: NSCharacterSet.whitespaces)
        Log.d("contactPicker: entry text did change: \(text)")
        self.searchEditing = (text.length > 0)

        if text.length >= 2 {
            self.searchText = text
            /* To limit network activity, reload half a second after last key press. */
            if let timer = self.searchTimer {
                timer.invalidate()
            }
            self.searchTimer = Timer(timeInterval:0.2, target:self, selector:#selector(MessageEditViewController.suggest), userInfo:nil, repeats:false)
            RunLoop.current.add(self.searchTimer!, forMode: RunLoopMode(rawValue: "NSDefaultRunLoopMode"))
        }
        else {
            if self.contactModels.count > 0 {
                self.contactModels.removeAllObjects()
                self.viewWillLayoutSubviews()
                self.contactList?.reloadData()
            }
        }
    }
}

class SuggestionModel {
    var entityId: String!
    var contactTitle: String?
    var contactSubtitle: String?
    var contactImageUrl: URL?
}
