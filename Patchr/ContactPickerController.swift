//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import pop
import CLTokenInputView
import Contacts

/* Routes
 * - Channel create flow: channelswitcher->channeledit->channelinvite->contactpicker (.internalCreate)
 * - Invite channel member flow: channelview->channelinvite->contactpicker (.none)
 */
class ContactPickerController: BaseTableController, CLTokenInputViewDelegate {

    var inputChannelId: String?
    var inputChannelTitle: String?
    var inputRole: String! // reader || editor
    var inputCode: String!

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
    * Lifecycle
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
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let navHeight = self.navigationController?.navigationBar.height() ?? 0
        let statusHeight = UIApplication.shared.statusBarFrame.size.height
        self.tokenView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: tokenView.height())
        self.tableView.alignUnder(self.tokenView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func doneAction(sender: AnyObject?) {
        if self.tokenView.text != nil && !self.tokenView.text!.isEmpty {
            let token = self.tokenView.tokenizeTextfieldText()
            if token == nil {
                return
            }
        }
        if self.picks.count > 0 {
            invite()
        }
        else if self.flow == .internalCreate {
            self.navigateToChannel()
        }
    }
    
    func beginEditingAction(sender: AnyObject?) {
        if !self.tokenView.isEditing {
            self.tokenView.beginEditing()
        }
    }
    
    func closeAction(sender: AnyObject?) {
        self.close()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func keyboardWillShow(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let value = info.value(forKey: UIKeyboardFrameBeginUserInfoKey) as! NSValue
        let keyboardSize = value.cgRectValue.size
        
        let contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, keyboardSize.height, 0)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    func keyboardWillHide(notification: Notification) {
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0, 0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
    }
    
    func dismissKeyboard(sender: NSNotification) {
        self.view.endEditing(true)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        var tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(sender:)));
        tap.cancelsTouchesInView = false
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.navigationItem.title = "Invite Contacts"

        self.tokenView = AirTokenView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.tokenView.placeholder.text = "Search"
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
        
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = Colors.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 64
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        self.tableView.tableFooterView = UIView()
        
        self.view.addSubview(self.tokenView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.activity)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let doneTitle = (self.flow == .internalCreate) ? "Done" : "Invite"
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
            CNContactStore().requestAccess(for: .contacts) { authorized, error in
                if authorized {
                    DispatchQueue.global().async {
                        self.loadContacts()
                    }
                }
            }
        }
        else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            DispatchQueue.global().async {
                self.loadContacts()
            }
        }
        else {
            self.alert(title: "Access to contacts has been denied. Check your privacy settings to allow access.")
        }
    }
    
    func navigateToChannel() {
        let channelId = self.inputChannelId!
        StateController.instance.setChannelId(channelId: channelId)
        MainController.instance.showChannel(channelId: channelId)
        self.navigationController?.close()
    }

    func loadContacts() {
        DispatchQueue.main.async {
            self.activity.startAnimating()
        }
        do {
            let fetchRequest = CNContactFetchRequest(keysToFetch: self.keysToFetch as! [CNKeyDescriptor])
            fetchRequest.sortOrder = .givenName
            fetchRequest.unifyResults = true
            try CNContactStore().enumerateContacts(with: fetchRequest) { contact, stop in
                if !contact.emailAddresses.isEmpty
                    , let email = contact.emailAddresses.first?.value as? String
                    , email != "[No email address found]" {
                    self.contactsSource.append(contact)
                }
            }
            filterContacts()
            DispatchQueue.main.async {
                self.activity.stopAnimating()
            }
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
                    let email = contact.emailAddresses.first?.value as? String
                    
                    if emails[email!] == nil {
                        let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                        let title = fullName ?? email
                        let sectionTitle = String(title!.characters.prefix(1)).uppercased()
                        
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
                let email = contact.emailAddresses.first?.value as? String
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
    
    func invite() {
        
        Reporting.track("invite_channel_readers")
        
        let channel = [
            "id": self.inputChannelId!,
            "title": self.inputChannelTitle!,
            "code": self.inputCode]
        
        for key in self.picks.keys {
            var email: String!
            if let contact = self.picks[key] as? CNContact {
                email = contact.emailAddresses.first?.value as? String
            }
            else if let contact = self.picks[key] as? String {
                email = contact
            }
            
            BranchProvider.invite(channel: channel
                , email: email!
                , role: self.inputRole
                , message: nil)
        }
        
        UIShared.toast(message: "Invites sent")
        if self.flow == .internalCreate {
            self.navigateToChannel()
        }
        else {
            self.close()
        }
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
            let invited = (self.picks[contact.identifier] != nil)
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
                
                let hasInvite = (self.picks[contact.identifier] != nil)
                
                if hasInvite {
                    self.picks.removeValue(forKey: contact.identifier)
                    self.tokenView.remove(CLToken(displayText: title, context: cell))
                    cell.checkBox?.setOn(false, animated: true)
                }
                else {
                    cell.checkBox?.setOn(hasInvite, animated: true)
                    self.tokenView.add(CLToken(displayText: title, context: cell))
                    self.picks[contact.identifier] = contact
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
        filterContacts()
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        if self.tokenView.allTokens.count == 0 {
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "Done"
            }
            else {
                self.doneButton.isEnabled = false
            }
        }
        else {
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "Invite"
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
            self.tokenView.searchImage.fadeIn(duration: 0.1)
            self.tokenView.placeholder.fadeIn(duration: 0.1)
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "Done"
            }
            else {
                self.doneButton.isEnabled = false
            }
        }
        else {
            if self.flow == .internalCreate || self.flow == .onboardSignup {
                self.doneButton.title = "Invite"
            }
            else {
                self.doneButton.isEnabled = true
            }
        }
        
        if let cell = token.context as? UserListCell, let contact = cell.contact {
            cell.setSelected(false, animated: true)
            cell.checkBox?.setOn(false, animated: true)
            self.picks.removeValue(forKey: contact.identifier)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        self.tokenView.frame.size.height = height
        self.view.setNeedsLayout()
    }
    
    func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        Log.d("tokenForText")
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? UserListCell {
            let contact = cell.contact!
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            let title = fullName ?? contact.emailAddresses.first!.value as String
            cell.checkBox?.setOn(true, animated: true)
            self.picks[contact.identifier] = contact
            return CLToken(displayText: title, context: cell)
        }
        else {
            if !text.isEmail() {
                UIShared.toast(message: "\(text) is not a valid email address")
                return nil
            }
            else {
                self.picks[text] = text
                return CLToken(displayText: text, context: nil)
            }
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

