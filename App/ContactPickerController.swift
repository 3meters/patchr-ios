//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import Localize_Swift
import pop
import CLTokenInputView
import Contacts
import PopupDialog
import UserNotifications

/* Routes
 * - Channel create flow: channelswitcher->channeledit->channelinvite->contactpicker (.internalCreate)
 * - Invite channel member flow: channelview->channelinvite->contactpicker (.none)
 */
class ContactPickerController: BaseTableController, CLTokenInputViewDelegate {

    var inputCode: String!
    var inputChannelId: String?
    var inputChannelTitle: String?
    var inputRole: String! // reader || editor

    var tokenView: AirTokenView!
    var doneButton: UIBarButtonItem!

    var contactsBySection = [String: [CNContact]]()
    var contactsFiltered = [CNContact]()
    var contactsSource = [CNContact]()
    var showContactsBySection = false

    var filterText: String?
    var filterActive = false
    
    var flow: Flow = .none

    var picks = [AnyHashable: Any]()
    
    var sectionTitles: [String]?

    let keysToFetch = [
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactEmailAddressesKey,
        CNContactPhoneNumbersKey,
        CNContactImageDataAvailableKey,
        CNContactImageDataKey,
        CNContactThumbnailImageDataKey] as [Any]

    /*--------------------------------------------------------------------------------------------
    * MARK: - Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard self.inputChannelId != nil,
            self.inputChannelTitle != nil,
            self.inputRole != nil else {
            assertionFailure("inputChannelId, inputChannelTitle, inputRole must be set")
            return
        }
        initialize()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.setNeedsLayout()
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(self.tableView, delay: 50.0, followers: [self.tokenView])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(Config.contentWidthMax, self.view.width())
        self.tokenView.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: tokenView.height())
        self.tableView.alignUnder(self.tokenView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
    *--------------------------------------------------------------------------------------------*/
    
    @objc func doneAction(sender: AnyObject?) {
        if self.tokenView.text != nil && !self.tokenView.text!.isEmpty {
            let token = self.tokenView.tokenizeTextfieldText()
            if token == nil {
                return
            }
        }
        if self.picks.count > 0 {
            let controller = InviteMessageController()
            let popup = PopupDialog(viewController: controller, gestureDismissal: false)
            let cancelButton = DefaultButton(title: "back".localized().uppercased(), height: 48, action: nil)
            let inviteButton = DefaultButton(title: "invite".localized().uppercased(), height: 48) {
                let message = controller.textView.text
                self.view.endEditing(true)
                self.invite(message: message)
            }
            popup.buttonAlignment = .horizontal
            popup.addButtons([cancelButton, inviteButton])
            present(popup, animated: true)
        }
        else if self.flow == .internalCreate {
            self.navigateToChannel()
        }
    }
    
    @objc func beginEditingAction(sender: AnyObject?) {
        if !self.tokenView.isEditing {
            self.tokenView.beginEditing()
        }
    }
    
    @objc func closeAction(sender: AnyObject?) {
        self.close()
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Notifications
    *--------------------------------------------------------------------------------------------*/

    @objc func keyboardWillShow(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let value = info.value(forKey: UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize = value.cgRectValue.size
        
        let contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, keyboardSize.height, 0)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0, 0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
    }
    
    @objc func dismissKeyboard(sender: NSNotification) {
        self.view.endEditing(true)
    }
    
    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        var tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:)));
        tap.cancelsTouchesInView = false
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        }
        else {
            self.automaticallyAdjustsScrollViewInsets = false
        }

        self.navigationItem.title = (self.inputRole == "reader")
            ? "contact_picker_title_readers".localized()
            : "contact_picker_title_contributors".localized()

        self.tokenView = AirTokenView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.tokenView.placeholder.text = "search".localized()
        self.tokenView.placeholder.textColor = Theme.colorTextPlaceholder
        self.tokenView.placeholder.font = Theme.fontComment
        self.tokenView.backgroundColor = Colors.white
        self.tokenView.tokenizationCharacters = [",", " ", ";"]
        self.tokenView.delegate = self
        self.tokenView.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleWidth]
        
        tap = UITapGestureRecognizer(target: self, action: #selector(beginEditingAction(sender:)));
        tap.cancelsTouchesInView = false
        tap.delegate = self
        self.tokenView.addGestureRecognizer(tap)
        
        self.tableView.backgroundColor = Colors.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 64
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        self.view.addSubview(self.tokenView)
        self.view.addSubview(self.tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let doneTitle = (self.flow == .internalCreate) ? "done".localized() : "invite".localized()
        self.doneButton = UIBarButtonItem(title: doneTitle, style: .plain, target: self, action: #selector(doneAction(sender:)))
        self.doneButton.isEnabled = (self.flow == .internalCreate) ? true : false
        self.navigationItem.rightBarButtonItems = [doneButton]

        if self.flow == .none {
            if self.presented {
                let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
                self.navigationItem.leftBarButtonItems = [closeButton]
            }
        }
    }
    
    func bind() {
        
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            let popup = PopupDialog(title: "permission_contacts_title".localized(),
                                    message: "permission_contacts_message".localized())
            let allowButton = DefaultButton(title: "allow".localized().uppercased(), height: 48) {
                CNContactStore().requestAccess(for: .contacts) { authorized, error in
                    if authorized {
                        DispatchQueue.global().async {
                            self.loadContacts()
                        }
                    }
                    else {
                        Log.w("Denied contacts permission")
                        Reporting.track("denied_contacts_permission")
                        self.close()
                    }
                }
                Log.d("Granted contacts permission")
                Reporting.track("granted_contacts_permission")
            }
            let laterButton = DefaultButton(title: "later".localized().uppercased(), height: 48) {
                Log.d("Postponed contacts permission")
                Reporting.track("postponed_contacts_permission")
                self.close()
            }
            popup.buttonAlignment = .horizontal
            popup.addButtons([laterButton, allowButton])
            self.present(popup, animated: true)
        }
        else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            DispatchQueue.global().async {
                self.loadContacts()
            }
        }
        else {
            self.alert(title: "permission_contacts_denied".localized())
            self.close()
        }
    }
    
    func navigateToChannel() {
        let channelId = self.inputChannelId!
        StateController.instance.setChannelId(channelId: channelId)
        MainController.instance.showChannel(channelId: channelId)
        self.navigationController?.close()
    }

    func loadContacts() {
        do {
            let fetchRequest = CNContactFetchRequest(keysToFetch: self.keysToFetch as! [CNKeyDescriptor])
            fetchRequest.sortOrder = .givenName
            fetchRequest.unifyResults = true
            try CNContactStore().enumerateContacts(with: fetchRequest) { contact, stop in
                if !contact.emailAddresses.isEmpty
                    , let email = contact.emailAddresses.first?.value as String?
                    , email != "[No email address found]" {
                    self.contactsSource.append(contact)
                }
            }
            filterContacts()
        }
        catch {
            Log.w("Error enumerating contacts: \(error.localizedDescription)")
        }
    }
    
    func filterContacts() {
        
        Reporting.track("filter_contacts")
        
        self.contactsBySection.removeAll()
        self.contactsFiltered.removeAll()
        self.sectionTitles = nil
        var emails = [AnyHashable: Any]()
        
        if !self.filterActive {
            
            if self.showContactsBySection {
                for contact in self.contactsSource {
                    let email = contact.emailAddresses.first?.value as String?
                    
                    if emails[email!] == nil {
                        let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                        let title = fullName ?? email
                        let sectionTitle = String(title!.prefix(1)).uppercased()
                        
                        if self.contactsBySection[sectionTitle] == nil {
                            self.contactsBySection[sectionTitle] = [contact]
                        }
                        else {
                            self.contactsBySection[sectionTitle]!.append(contact)
                        }
                        emails[email!] = true
                    }
                }
                self.sectionTitles = self.contactsBySection.keys.sorted()
            }
        }
        else {
            
            for contact in self.contactsSource {
                let email = contact.emailAddresses.first?.value as String?
                if emails[email!] == nil {
                    let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                    let title = fullName ?? email
                    
                    let match = (title?.lowercased().contains(self.filterText!.lowercased()))!
                        || (email?.lowercased().contains(self.filterText!.lowercased()))!
                    
                    if match {
                        self.contactsFiltered.append(contact)
                        emails[email!] = true
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func invite(message: String? = nil) {
        
        Reporting.track("invite_channel_members")
        
        let userTitle = UserController.instance.userTitle!
        let userEmail = UserController.instance.userEmail!
        let userId = UserController.instance.userId!
        let username = UserController.instance.user!.username!
        
        let channel = [
            "id": self.inputChannelId!,
            "title": self.inputChannelTitle!]
        
        let inviter = [
            "id": userId,
            "title": userTitle,
            "username": username,
            "email": userEmail]
        
        let timestamp = FireController.instance.getServerTimestamp()
        
        for key in self.picks.keys {
            let inviteId = "in-\(Utils.genRandomId(digits: 9))"
            let email = self.picks[key] as? String
            
            BranchProvider.invite(channel: channel
                , code: self.inputCode!
                , email: email!
                , role: self.inputRole!
                , message: message) { response, error in
                
                if error == nil {
                    let inviteItem = response as! InviteItem
                    let inviteUrl = inviteItem.url
                    let language = Localize.currentLanguage()
                    var invite: [String: Any] = [
                        "channel": channel,
                        "created_at": timestamp,
                        "created_by": userId,
                        "email": email!,
                        "inviter": inviter,
                        "language": language,
                        "link": inviteUrl,
                        "role": self.inputRole!]
                    if message != nil {
                        invite["message"] = message!
                    }
                    FireController.db.child("invites/\(inviteId)").setValue(invite)
                }
            }
        }
        
        Utils.incrementUserActions()
        
        if UIApplication.shared.currentUserNotificationSettings!.types == [] {
            if #available(iOS 10.0, *) {
                
                let popup = PopupDialog(title: "permission_notifications_title".localized(),
                                        message: "permission_notifications_message".localized())
                let allowButton = DefaultButton(title: "allow".localized().uppercased(), height: 48) {
                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                        if granted {
                            DispatchQueue.main.async {
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                UNUserNotificationCenter.current().delegate = appDelegate // For iOS 10 display notification (sent via APNS)
                                Messaging.messaging().delegate = appDelegate // For iOS 10 data message (sent via FCM with only data)
                                Log.d("Granted notifications permission")
                                Reporting.track("granted_notifications_permission")
                            }
                        }
                        else {
                            Log.w("Denied notifications permission")
                            Reporting.track("denied_notifications_permission")
                        }
                        self.inviteContinue()
                    }
                }
                let laterButton = DefaultButton(title: "later".localized().uppercased(), height: 48) {
                    Log.d("Postponed notifications permission")
                    Reporting.track("postponed_notifications_permission")
                    self.inviteContinue()
                }
                popup.buttonAlignment = .horizontal
                popup.addButtons([laterButton, allowButton])
                self.present(popup, animated: true)
            }
            else {
                /* Triggers permission UI if needed */
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
                inviteContinue()
            }
        }
        else {
            inviteContinue()
        }
    }
    
    func inviteContinue() {
        if let controller = self.navigationController?.presentingViewController {
            UIShared.toast(message: "invites_sent".localized(), duration: 3.0, controller: controller, addToWindow: false)
        }
        if self.flow == .internalCreate {
            self.navigateToChannel()
        }
        else {
            self.navigationController?.close()
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
        return true
    }
}

extension ContactPickerController: UITableViewDataSource {
    
    func numberOfSections(in: UITableView) -> Int {
        if self.showContactsBySection && self.sectionTitles != nil {
            return self.sectionTitles!.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.showContactsBySection && self.sectionTitles != nil {
            let sectionTitle = self.sectionTitles?[section]
            return self.contactsBySection[sectionTitle!]!.count
        }
        else {
            if self.filterActive {
                return self.contactsFiltered.count
            }
            else {
                return self.contactsSource.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserListCell
        var contact: CNContact!
        cell.selectionStyle = .none
        
        if self.showContactsBySection && self.sectionTitles != nil {
            let sectionTitle = self.sectionTitles?[indexPath.section]
            contact = self.contactsBySection[sectionTitle!]?[indexPath.row]
        }
        else {
            if self.filterActive {
                contact = self.contactsFiltered[indexPath.row]
            }
            else {
                contact = self.contactsSource[indexPath.row]
            }
        }
        
        cell.bind(contact: contact)
        
        cell.checkBox?.on = false
        if let contact = cell.contact {
            let email = contact.emailAddresses.first!.value as String
            let invited = (self.picks[email] != nil)
            cell.checkBox?.on = invited
        }
        
        return cell
    }
}

extension ContactPickerController: UITableViewDelegate  {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            if cell.allowSelection {
                let contact = cell.contact!
                let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                let title = fullName ?? contact.emailAddresses.first!.value as String
                let email = contact.emailAddresses.first!.value as String
                
                let hasInvite = (self.picks[email] != nil)
                
                if hasInvite {
                    self.picks.removeValue(forKey: email)
                    self.tokenView.remove(CLToken(displayText: title, context: cell))
                    cell.checkBox?.setOn(false, animated: true)
                }
                else {
                    cell.checkBox?.setOn(hasInvite, animated: true)
                    self.tokenView.add(CLToken(displayText: title, context: cell))
                    self.picks[email] = email
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles?[section] ?? nil
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.tokenView.isEditing ? nil : self.sectionTitles
    }
}

extension ContactPickerController {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        self.filterActive = (text != nil && !text!.trimmingCharacters(in: .whitespaces).isEmpty)
        self.filterText = (text != nil) ? text!.trimmingCharacters(in: .whitespaces) : nil
        self.doneButton.isEnabled = (text != nil && text!.isEmail()) || self.tokenView.allTokens.count > 0
        filterContacts()
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        if self.tokenView.allTokens.count == 0 {
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "done".localized()
            }
            else {
                self.doneButton.isEnabled = false
            }
        }
        else {
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "invite".localized()
            }
            else {
                self.doneButton.isEnabled = true
            }
        }
        self.tokenView.searchImage.fadeOut(duration: 0.0)
        self.tokenView.placeholder.fadeOut(duration: 0.0)
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        if self.tokenView.allTokens.count == 0 {
            if !self.tokenView.isEditing {
                self.tokenView.searchImage.fadeIn(duration: 0.1)
                self.tokenView.placeholder.fadeIn(duration: 0.1)
            }
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "done".localized()
            }
            else {
                self.doneButton.isEnabled = false
            }
        }
        else {
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "invite".localized()
            }
            else {
                self.doneButton.isEnabled = true
            }
        }
        
        if let cell = token.context as? UserListCell, let contact = cell.contact {
            let email = contact.emailAddresses.first!.value as String
            cell.setSelected(false, animated: true)
            cell.checkBox?.setOn(false, animated: true)
            self.picks.removeValue(forKey: email)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        self.tokenView.frame.size.height = height
        self.view.setNeedsLayout()
    }
    
    func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        
        /* Only called when trying to use entered text as an email address */
        Log.d("tokenForText")
        if !text.isEmail() {
            UIShared.toast(message: "email_invalid_alert".localizedFormat(text))
            return nil
        }
        else {
            self.picks[text] = text
            return CLToken(displayText: text, context: nil)
        }
    }
    
    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        if self.tokenView.allTokens.count == 0 {
            self.tokenView.searchImage.fadeIn(duration: 0.1)
            self.tokenView.placeholder.fadeIn(duration: 0.1)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        self.tokenView.searchImage.fadeOut(duration: 0.1)
        self.tokenView.placeholder.fadeOut(duration: 0.1)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tokenInputViewShouldReturn(_ view: CLTokenInputView) -> Bool {
        Log.d("tokenInputViewShouldReturn")
        return true
    }
}

extension ContactPickerController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view is UITableViewCell) {
            return false
        }
        if (touch.view?.superview is UITableViewCell) {
            return false
        }
        if (touch.view?.superview?.superview is UITableViewCell) {
            return false
        }
        if (touch.view?.superview?.superview?.superview is UITableViewCell) {
            return false
        }
        return true
    }
}

