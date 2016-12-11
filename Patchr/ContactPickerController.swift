//
//  NavigationController.swift
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

class ContactPickerController: BaseTableController, UITableViewDelegate, UITableViewDataSource, CLTokenInputViewDelegate {

    var contactsView: AirContactView!
    var tableView: AirTableView!
    var inviteButton: UIBarButtonItem!
    
    var sectionTitles: [String]?
    
    var contactsAll = [CNContact]()
    var contactsMapped = [String: [CNContact]]()
    var contactsFiltered = [CNContact]()
    
    var invites: [AnyHashable: Any] = [:]
    var emails: [AnyHashable: Any] = [:]
    
    var role = "members"
    var channel: FireChannel!
    var inputGroupId: String?
    var inputGroupTitle: String?
    
    var filterText: String?
    var filterActive = false
    
    var flow: BaseEditViewController.Flow = .none
    
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
        initialize()
        bind()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let navHeight = self.navigationController?.navigationBar.height() ?? 0
        let statusHeight = UIApplication.shared.statusBarFrame.size.height
        self.contactsView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: contactsView.height())
        self.tableView.alignUnder(self.contactsView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func inviteAction(sender: AnyObject?) {
        invite()
    }
    
    func onboardAction(sender: AnyObject?) {
        let groupId = self.inputGroupId!
        FireController.instance.findFirstChannel(groupId: groupId) { firstChannelId in
            if firstChannelId != nil {
                StateController.instance.setGroupId(groupId: groupId, channelId: firstChannelId)
                MainController.instance.showChannel(groupId: groupId, channelId: firstChannelId!)
                let _ = self.navigationController?.popToRootViewController(animated: false)
                self.close()
            }
        }
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
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        
        self.view.backgroundColor = Colors.gray95pcntColor
        
        self.contactsView = AirContactView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.contactsView.placeholder.text = "Search"
        self.contactsView.placeholder.textColor = Theme.colorTextPlaceholder
        self.contactsView.placeholder.font = Theme.fontComment
        self.contactsView.backgroundColor = Colors.white
        self.contactsView.delegate = self
        self.contactsView.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleWidth]
        
        self.tableView = AirTableView(frame: CGRect.zero, style: .plain)
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "contact-cell")
        self.tableView.backgroundColor = Colors.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        
        self.view.addSubview(self.contactsView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.activity)
        
        self.navigationItem.title = self.role == "members" ? "Invite Members from Contacts" : "Invite Guests from Contacts"
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.inviteButton = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(inviteAction(sender:)))
        self.inviteButton.isEnabled = false
        self.navigationItem.rightBarButtonItems = [inviteButton]
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
            Alert(title: "Access to contacts has been denied. Check your privacy settings to allow access.")
        }
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
                    self.contactsAll.append(contact)
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
        
        self.contactsMapped.removeAll()
        self.contactsFiltered.removeAll()
        self.sectionTitles = nil
        self.emails.removeAll()
        
        if !self.filterActive {
            
            for contact in self.contactsAll {
                let email = contact.emailAddresses.first?.value as? String
                
                if self.emails[email!] == nil {
                    let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                    let title = fullName ?? email
                    let sectionTitle = String(title!.characters.prefix(1)).uppercased()
                    
                    if self.contactsMapped[sectionTitle] == nil {
                        self.contactsMapped[sectionTitle] = [contact]
                    }
                    else {
                        self.contactsMapped[sectionTitle]!.append(contact)
                    }
                    self.emails[email!] = true
                }
            }
            self.sectionTitles = self.contactsMapped.keys.sorted()
        }
        else {
            
            for contact in self.contactsAll {
                let email = contact.emailAddresses.first?.value as? String
                if self.emails[email!] == nil {
                    let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                    let title = fullName ?? email
                    
                    let match = (title?.lowercased().contains(self.filterText!.lowercased()))!
                        || (email?.lowercased().contains(self.filterText!.lowercased()))!
                    
                    if match {
                        self.contactsFiltered.append(contact)
                        self.emails[email!] = true
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func invite() {
        
        if self.role == "members" {
            
            let groupId = StateController.instance.group?.id ?? self.inputGroupId!
            let groupTitle = StateController.instance.group?.title ?? self.inputGroupTitle!
            let username = UserController.instance.user!.username!
            
            BranchProvider.inviteMember(groupId: groupId, groupTitle: groupTitle, username: username, completion: { response, error in
                
                if error == nil {
                    
                    let invite = response as! InviteItem
                    let inviteUrl = invite.url
                    let userTitle = UserController.instance.userTitle
                    let userEmail = UserController.instance.userEmail
                    
                    var recipients = [String]()
                    
                    for key in self.invites.keys {
                        let contact = self.invites[key] as! CNContact
                        let email = contact.emailAddresses.first?.value as? String
                        recipients.append(email!)
                    }
                    
                    var emailMap: [String: Any] = [:]
                    emailMap["recipients"] = recipients
                    emailMap["type"] = "invite-members"
                    emailMap["group"] = ["title": groupTitle]
                    emailMap["user"] = ["title": userTitle, "email": userEmail]
                    emailMap["link"] = inviteUrl
                    
                    let queueRef = FireController.db.child("email-queue").childByAutoId()
                    queueRef.setValue(emailMap)
                    if self.flow == .onboardCreate {
                        self.onboardAction(sender: nil)
                    }
                    else {
                        self.close()
                    }
                    UIShared.Toast(message: "Invites sent")
                }
            })
        }
        else if self.role == "guests" {
            
            BranchProvider.inviteGuest(group: StateController.instance.group, channel: self.channel, completion: { response, error in
                
                if error == nil {
                    let invite = response as! InviteItem
                    let inviteUrl = invite.url
                    let userTitle = UserController.instance.userTitle
                    let userEmail = UserController.instance.userEmail
                    
                    let group = StateController.instance.group!
                    let groupTitle = group.title!
                    let channel = self.channel!
                    let channelName = channel.name!
                    
                    var recipients = [String]()
                    
                    for key in self.invites.keys {
                        let contact = self.invites[key] as! CNContact
                        let email = contact.emailAddresses.first?.value as? String
                        recipients.append(email!)
                    }
                    
                    var emailMap: [String: Any] = [:]
                    emailMap["recipients"] = recipients
                    emailMap["type"] = "invite-guests"
                    emailMap["group"] = ["title": groupTitle]
                    emailMap["channel"] = ["name": channelName]
                    emailMap["user"] = ["title": userTitle, "email": userEmail]
                    emailMap["link"] = inviteUrl
                    
                    let queueRef = FireController.db.child("email-queue").childByAutoId()
                    queueRef.setValue(emailMap)
                    self.close()
                    UIShared.Toast(message: "Invites sent")
                }
            })
        }
    }
}

extension ContactPickerController {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            if cell.allowSelection {
                let contact = cell.contact!
                let fullName = CNContactFormatter.string(from: contact, style: .fullName)
                let title = fullName ?? contact.emailAddresses.first!.value as String
                
                let hasInvite = (self.invites[contact.identifier] != nil)
                
                if hasInvite {
                    self.invites.removeValue(forKey: contact.identifier)
                    self.contactsView.remove(CLToken(displayText: title, context: cell))
                    cell.checkBox?.setOn(false, animated: true)
                }
                else {
                    cell.checkBox?.setOn(hasInvite, animated: true)
                    self.contactsView.add(CLToken(displayText: title, context: cell))
                    self.invites[contact.identifier] = contact
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
        return self.contactsView.isEditing ? nil : self.sectionTitles
    }
    
    func numberOfSections(in: UITableView) -> Int {
        if self.sectionTitles != nil {
            return self.sectionTitles!.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sectionTitles != nil {
            let sectionTitle = self.sectionTitles?[section]
            return self.contactsMapped[sectionTitle!]!.count
        }
        else {
            return self.contactsFiltered.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contact-cell", for: indexPath) as! UserListCell
        cell.selectionStyle = .none
        
        if self.sectionTitles != nil {
            let sectionTitle = self.sectionTitles?[indexPath.section]
            let contact = self.contactsMapped[sectionTitle!]?[indexPath.row]
            cell.bind(contact: contact!)
        }
        else {
            let contact = self.contactsFiltered[indexPath.row]
            cell.bind(contact: contact)
        }
        
        cell.checkBox?.on = false
        if let contact = cell.contact {
            let invited = (self.invites[contact.identifier] != nil)
            cell.checkBox?.on = invited
        }
        
        return cell
    }
}

extension ContactPickerController {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        self.filterActive = (text != nil && !text!.trimmingCharacters(in: .whitespaces).isEmpty)
        self.filterText = (text != nil) ? text!.trimmingCharacters(in: .whitespaces) : nil
        filterContacts()
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        self.inviteButton.isEnabled = (self.contactsView.allTokens.count > 0)
        self.contactsView.searchImage.fadeOut(duration: 0.0)
        self.contactsView.placeholder.fadeOut(duration: 0.0)
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        self.inviteButton.isEnabled = (self.contactsView.allTokens.count > 0)
        if self.contactsView.allTokens.count == 0 {
            self.contactsView.searchImage.fadeIn(duration: 0.2)
            self.contactsView.placeholder.fadeIn(duration: 0.2)
        }
        if let cell = token.context as? UserListCell, let contact = cell.contact {
            cell.setSelected(false, animated: true)
            cell.checkBox?.setOn(false, animated: true)
            self.invites.removeValue(forKey: contact.identifier)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        self.contactsView.frame.size.height = height
        self.view.setNeedsLayout()
    }
    
    func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        Log.d("tokenForText")
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? UserListCell {
            let contact = cell.contact!
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            let title = fullName ?? contact.emailAddresses.first!.value as String
            cell.checkBox?.setOn(true, animated: true)
            self.invites[contact.identifier] = contact
            return CLToken(displayText: title, context: cell)
        }

        return nil
    }
    
    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        if self.contactsView.allTokens.count == 0 {
            self.contactsView.searchImage.fadeIn(duration: 0.2)
            self.contactsView.placeholder.fadeIn(duration: 0.2)
        }
        self.tableView.reloadData()
    }
    
    func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        self.contactsView.searchImage.fadeOut(duration: 0.2)
        self.contactsView.placeholder.fadeOut(duration: 0.2)
        self.tableView.reloadData()
    }
    
    func tokenInputViewShouldReturn(_ view: CLTokenInputView) -> Bool {
        Log.d("tokenInputViewShouldReturn")
        return true
    }
}
