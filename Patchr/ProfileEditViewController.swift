//
//  RegistrationTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AWSS3
import PBWebViewController
import MBProgressHUD
import FirebaseRemoteConfig
import Firebase

class ProfileEditViewController: BaseEditViewController {

    var processing: Bool = false
    var progressStartLabel: String?
    var progressFinishLabel: String?
    var cancelledLabel: String?

    var schema: String?

    var imageUploadRequest	: AWSS3TransferManagerUploadRequest?
    var entityPostRequest	: URLSessionTask?

    var inputRouteToMain	: Bool = true
    var inputProvider		: String? = AuthProvider.PROXIBASE
    var inputState			: State? = State.Editing
    var inputUser			: User?
    var inputFirstName		: String?
    var inputLastName		: String?
    var inputEmail			: String?
    var inputPassword		: String?
    var inputUserId			: String?
    var inputPhotoUrl		: NSURL?
    var source				= "Lobby"

    var photoView            = PhotoEditView()
    var firstNameField       = AirTextField()
    var lastNameField        = AirTextField()
    var emailField           = AirTextField()
    var changePasswordButton = AirButton()
    var joinButton           = AirFeaturedButton()
    var termsButton          = AirLinkButton()
    var message				 = AirLabelTitle()

    var progress			 : AirProgress?

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
        draw()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let messageSize = self.message.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        self.message.anchorTopCenter(withTopPadding: 0, width: 288, height: messageSize.height)
        self.photoView.alignUnder(self.message, matchingCenterWithTopPadding: 16, width: 150, height: 150)
        self.firstNameField.alignUnder(self.photoView, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        self.lastNameField.alignUnder(self.firstNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)

        if self.inputState == State.Onboarding {
            self.emailField.alignUnder(self.lastNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.joinButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.termsButton.alignUnder(self.joinButton, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }
        else {
            self.emailField.alignUnder(self.lastNameField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
            self.changePasswordButton.alignUnder(self.emailField, matchingCenterWithTopPadding: 8, width: 288, height: 48)
        }

        self.contentHolder.resizeToFitSubviews()
        self.scrollView.contentSize = CGSize(width:self.contentHolder.frame.size.width, height:self.contentHolder.frame.size.height + CGFloat(32))
        self.contentHolder.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 24, height: self.contentHolder.frame.size.height)
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/

    func doneAction(sender: AnyObject){
        if !isValid() { return }
        post()
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

    func changePasswordAction(sender: AnyObject) {
        let controller = PasswordEditViewController()
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func termsAction(sender: AnyObject) {
        let webViewController = PBWebViewController()
        webViewController.url = NSURL(string: "http://patchr.com/terms")! as URL
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }

    func deleteAction(sender: AnyObject) {

        DeleteConfirmationAlert(
            title: "Confirm account delete",
            message: "Deleting your user account will erase all patches and messages you have created and cannot be undone. Enter YES to confirm.",
            actionTitle: "Delete",
            cancelTitle: "Cancel",
            destructConfirmation: true,
            delegate: self) {
                doIt in
                if doIt {
                    self.delete()
                }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/

    override func initialize() {
        super.initialize()

        self.schema = Schema.ENTITY_USER

        if self.inputState == State.Onboarding {
            self.message.text = "Make your profile more personal"
        }
        else {
            self.message.text = "Profile"
        }

        self.message.textColor = Theme.colorTextTitle
        self.message.numberOfLines = 0
        self.message.textAlignment = .center
        self.contentHolder.addSubview(self.message)

        self.photoView.photoSchema = Schema.ENTITY_USER
        self.photoView.setHostController(controller: self)
        self.contentHolder.addSubview(self.photoView)

        self.firstNameField.placeholder = "First name"
        self.firstNameField.delegate = self
        self.firstNameField.autocapitalizationType = .words
        self.firstNameField.autocorrectionType = .no
        self.firstNameField.keyboardType = UIKeyboardType.default
        self.firstNameField.returnKeyType = UIReturnKeyType.next
        self.contentHolder.addSubview(self.firstNameField)

        self.lastNameField.placeholder = "Last name"
        self.lastNameField.delegate = self
        self.lastNameField.autocapitalizationType = .words
        self.lastNameField.autocorrectionType = .no
        self.lastNameField.keyboardType = UIKeyboardType.default
        self.lastNameField.returnKeyType = UIReturnKeyType.next
        self.contentHolder.addSubview(self.lastNameField)
        
        self.emailField.placeholder = "Email"
        self.emailField.delegate = self
        self.emailField.autocapitalizationType = .none
        self.emailField.autocorrectionType = .no
        self.emailField.keyboardType = UIKeyboardType.emailAddress
        self.lastNameField.returnKeyType = UIReturnKeyType.done
        self.contentHolder.addSubview(self.emailField)

        if self.inputState == State.Onboarding {

            Reporting.screen("ProfileSignup")

            navigationItem.title = "Profile"
            self.progressStartLabel = "Signing up..."
            self.progressFinishLabel = "Joined"
            self.cancelledLabel = "Sign up cancelled"

            self.photoView.configureTo(photoMode: self.inputPhotoUrl != nil ? .Photo : .Placeholder)

            self.emailField.isEnabled = false
            self.emailField.textColor = Theme.colorTextSecondary

            self.joinButton.setTitle("JOIN", for: .normal)
            self.contentHolder.addSubview(self.joinButton)

            self.termsButton.setTitle("By joining, you agree to the Terms of Service", for: .normal)
            self.termsButton.titleLabel!.numberOfLines = 2
            self.termsButton.titleLabel!.textAlignment = NSTextAlignment.center
            self.contentHolder.addSubview(self.termsButton)

            /* Navigation bar buttons */
            let doneButton   = UIBarButtonItem(title: "Join", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ProfileEditViewController.doneAction(sender:)))

            self.navigationItem.rightBarButtonItems = [doneButton]
            self.navigationItem.leftBarButtonItems = nil

            self.joinButton.addTarget(self, action: #selector(ProfileEditViewController.doneAction(sender:)), for: .touchUpInside)
            self.termsButton.addTarget(self, action: #selector(ProfileEditViewController.termsAction(sender:)), for: .touchUpInside)
        }
        else {

            Reporting.screen("ProfileEdit")

            navigationItem.title = "Edit profile"
            self.progressStartLabel = "Updating"
            self.progressFinishLabel = "Updated"
            self.cancelledLabel = "Update cancelled"

            self.photoView.configureTo(photoMode: self.inputUser?.photo != nil ? .Photo : .Placeholder)

            self.changePasswordButton.setTitle("CHANGE PASSWORD", for: .normal)
            self.contentHolder.addSubview(self.changePasswordButton)

            /* Navigation bar buttons */
            let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ProfileEditViewController.cancelAction(sender:)))
            let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(ProfileEditViewController.deleteAction(sender:)))
            let doneButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(ProfileEditViewController.doneAction(sender:)))

            self.navigationItem.leftBarButtonItems = [cancelButton]
            self.navigationItem.rightBarButtonItems = [doneButton, Utils.spacer, deleteButton]

            self.changePasswordButton.addTarget(self, action: #selector(ProfileEditViewController.changePasswordAction(sender:)), for: .touchUpInside)
        }
    }

    func draw() {}

    func bind() {

        if self.inputState == State.Onboarding {
            self.emailField.text = self.inputEmail
            self.firstNameField.text = self.inputFirstName
            self.lastNameField.text = self.inputLastName

            /* Photo */
            if self.inputPhotoUrl != nil {		// We have a facebook profile photo
                let imageResult = ImageResult()
                imageResult.contentUrl = self.inputPhotoUrl?.absoluteString
                imageResult.width = 200
                imageResult.height = 200
                /*
                 * Request image via resizer so size is capped. We don't use imgix because it only uses
                 * known image sources that we setup like our buckets on s3.
                 */
                let dimension = imageResult.width! >= imageResult.height! ? ResizeDimension.width : ResizeDimension.height
                let url = URL(string: GooglePlusProxy.convert(uri: imageResult.contentUrl!, size: Int(IMAGE_DIMENSION_MAX), dimension: dimension))

                self.photoView.imageButton.setImageWithUrl(url: url!)
                self.photoView.configureTo(photoMode: .Photo)
            }
        }
        else {
            self.firstNameField.text = self.inputUser?.name
            self.lastNameField.text = self.inputUser?.name
            self.emailField.text = self.inputUser?.email
            self.photoView.bindPhoto(photo: self.inputUser?.photo)
        }
    }

    func post() {

        if self.processing { return }

        processing = true

        let progress = AirProgress.showAdded(to: self.view.window!, animated: true)
        progress?.mode = MBProgressHUDMode.indeterminate
        progress?.styleAs(progressStyle: .ActivityWithText)
        progress?.labelText = self.progressStartLabel!
        progress?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileEditViewController.progressWasCancelled(sender:))))
        progress?.removeFromSuperViewOnHide = true
        progress?.show(true)

        var parameters = self.gather()
        var cancelled = false

        let queue = TaskQueue()

        Utils.delay(5.0) {
            progress?.detailsLabelText = "Tap to cancel"
        }

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

        /* Upload user */

        queue.tasks +=~ { _, next in

            if self.inputState == .Onboarding {
                let secret = FIRRemoteConfig.remoteConfig().configValue(forKey: "proxibase_secret").stringValue!
                var createParameters: [String: Any] = [
                    "data": parameters,
                    "secret": secret
                ]
                
                if let installId = NotificationController.instance.installId {
                    createParameters["installId"] = installId   // Adding because this leads to login
                }

                self.entityPostRequest = DataController.proxibase.postEntity(path: "user/create", parameters: createParameters) {
                    response, error in
                    if error != nil && error!.code == NSURLErrorCancelled {
                        cancelled = true
                    }
                    if error == nil {
                        /* Remember email address for easy data entry */
                        UserDefaults.standard.set(self.emailField.text, forKey: PatchrUserDefaultKey(subKey: "userEmail"))
                    }
                    next(Result(response: response as AnyObject?, error: error))
                }
            }
            else {
                let endpoint = "data/users/\(self.inputUser!.id_)"
                self.entityPostRequest = DataController.proxibase.postEntity(path: endpoint, parameters: parameters) {
                    response, error in
                    if error == nil {
                        progress?.progress = 1.0
                    }
                    else if error!.code == NSURLErrorCancelled {
                        cancelled = true
                    }
                    next(Result(response: response as AnyObject?, error: error))
                }
            }
        }

        /* Update Ui */

        queue.tasks +=! {
            self.processing = false

            if cancelled {
                UIShared.Toast(message: self.cancelledLabel)
                return
            }

            progress?.hide(true)

            if let result: Result = queue.lastResult as? Result {
                if var error = ServerError(result.error) {
                    if error.code == .FORBIDDEN_DUPLICATE {
                        error.message = Utils.LocalizedString(str: "Email address already in use.")
                        self.handleError(error, errorActionType: .ALERT)
                    }
                    else {
                        self.handleError(error)
                    }
                    return
                }
                if self.inputState == .Onboarding {
                    /*
                    * After creating a user, the user is left in a logged-in state, so process the response
                    * to extract the credentials.
                    */
                    if let response: AnyObject = result.response as AnyObject? {

                        UserController.instance.handleSuccessfulLoginResponse(response: response)

                        /* Navigate to main interface */
                        if self.inputRouteToMain {
                            self.navigateToMain() // Replaces any current navigation stack
                        }
                        else {
                            if self.isModal {
                                self.dismiss(animated: true, completion: nil)
                            }
                            else {
                                let _ = self.navigationController?.popViewController(animated: true)
                            }
                        }
                        Reporting.track("Created User and Logged In", properties: ["source":self.source as AnyObject])
                        return
                    }
                }
                else {
                    Reporting.track("Updated User")
                }
            }

            self.performBack(animated: true)
            UIShared.Toast(message: self.progressFinishLabel)
        }

        /* Start tasks */

        queue.run()
    }

    func delete() {

        if self.processing {
            return
        }
        self.processing = true

        if self.inputUser != nil {

            let entityPath = "user/\((self.inputUser!.id_)!)?erase=true"
            let userName: String = self.inputUser!.name

            DataController.proxibase.deleteObject(path: entityPath) {
                response, error in

                OperationQueue.main.addOperation {

                    self.processing = false
                    if let error = ServerError(error) {
                        self.handleError(error)
                    }
                    else {
                        Log.i("User deleted: \(userName)")
                    }

                    /* Return to the lobby even if there was an error since we signed out */
                    UserController.instance.discardCredentials()
                    Reporting.updateUser(user: nil)
                    BranchProvider.logout()
                    UserController.instance.clearStore()
                    UserDefaults.standard.set(nil, forKey: PatchrUserDefaultKey(subKey: "userEmail"))

                    LocationController.instance.clearLastLocationAccepted()

                    let navController = AirNavigationController()
                    navController.viewControllers = [LobbyViewController()]
                    MainController.instance.window!.setRootViewController(rootViewController: navController, animated: true)
                    Reporting.track("Deleted User", properties: ["id": self.inputUser!.id_, "name": userName, "email": self.inputUser!.email])
                    UIShared.Toast(message: "User \(userName) erased", controller: navController)
                }
            }
        }
    }

    func gather() -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["name"] = nilToNull(value: self.firstNameField.text as AnyObject?)
        parameters["photo"] = nilToNull(value: self.photoView.imageButton.image(for: .normal))
        parameters["email"] = nilToNull(value: self.emailField.text as AnyObject?)
        if self.inputState == .Onboarding && self.inputProvider == AuthProvider.PROXIBASE {
            parameters["password"] = nilToNull(value: self.inputPassword as AnyObject?)
        }
        return parameters
    }

    func navigateToMain() {

        if CLLocationManager.authorizationStatus() == .notDetermined
            || !UIApplication.shared.isRegisteredForRemoteNotifications {
                let controller = PermissionsViewController()
                self.navigationController?.pushViewController(controller, animated: true)
                if UserController.instance.userName != nil {
                    UIShared.Toast(message: "Logged in as \(UserController.instance.userName!)", controller: controller, addToWindow: false)
                }
        }
        else {
            MainController.instance.route()
            if UserController.instance.userName != nil {
                UIShared.Toast(message: "Logged in as \(UserController.instance.userName!)")
            }
        }
    }

    func isDirty() -> Bool {

        if self.inputState == .Onboarding {
            if self.firstNameField.text != self.inputFirstName {
                return true
            }
            if self.emailField.text != self.inputEmail {
                return true
            }
        }
        else {
            if self.inputUser != nil {
                if !stringsAreEqual(string1: self.firstNameField.text, string2: self.inputUser!.name) {
                    return true
                }
                if !stringsAreEqual(string1: self.emailField.text, string2: self.inputUser!.email) {
                    return true
                }                
            }
        }

        if photoView.photoDirty {
            return true
        }

        return false
    }

    func isValid() -> Bool {

        if firstNameField.isEmpty {
            Alert(title: "Enter a name.", message: nil, cancelButtonTitle: "OK")
            return false
        }

        if emailField.isEmpty {
            Alert(title: "Enter an email address.", message: nil, cancelButtonTitle: "OK")
            return false
        }

        if !emailField.text!.isEmail() {
            Alert(title: "Enter a valid email address.")
            return false
        }

        return true
    }

    func progressWasCancelled(sender: AnyObject) {
        if let gesture = sender as? UIGestureRecognizer, let hud = gesture.view as? MBProgressHUD {
            hud.animationType = MBProgressHUDAnimation.zoomIn
            hud.hide(true)
            let _ = self.imageUploadRequest?.cancel() // Should do nothing if upload already complete or isn't any
            self.entityPostRequest?.cancel()
        }
    }

    override func textFieldShouldReturn(textField: UITextField) -> Bool {

        if self.inputState == .Onboarding {
            if textField == self.firstNameField {
                self.doneAction(sender: textField)
                textField.resignFirstResponder()
                return false
            }
        }
        else {
            if textField == self.firstNameField {
                self.emailField.becomeFirstResponder()
                return false
            }
            else if textField == self.emailField {
                self.doneAction(sender: textField)
                textField.resignFirstResponder()
                return false
            }
        }
        return true
    }
}
