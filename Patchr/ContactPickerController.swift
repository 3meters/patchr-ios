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
 * - Group create flow: password->groupcreate->contactpicker (.onboardCreate)
 * - Group create flow (authorized): groupswitcher->groupcreate->contactpicker (.internalCreate)
 * - Group create flow (not authorized): groupswitcher->groupcreate->invite->contactpicker (.internalCreate)
 * - Invite group member flow: memberlist->contactpicker (.internalInvite)
 * - Invite group member flow: sidemenu->contactpicker (.internalInvite)
 *
 * - Channel create flow: channelswitcher->channeledit->channelinvite->contactpicker (.internalCreate)
 * - Invite channel member flow: channelview->channelinvite->contactpicker (.none)
 */
class ContactPickerController: BaseTableController, CLTokenInputViewDelegate {

    var inputGroupId: String!
    var inputGroupTitle: String!
    var inputChannelId: String?
    var inputChannelName: String?
    var inputRole: String!

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
    
    var invitedEmails = [AnyHashable: [[String: Any]]]()    // From existing invites
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
        
        guard self.inputGroupId != nil,
            self.inputGroupTitle != nil,
            self.inputRole != nil else {
            assertionFailure("inputGroupId, inputGroupTitle, inputRole must be set")
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
        else if self.flow == .onboardCreate {
            self.navigateToGroup()
        }
        else if self.flow == .internalCreate {
            if self.inputChannelId != nil {
                self.navigateToChannel()
            } else {
                self.navigateToGroup()
            }
        }
    }
    
    func beginEditingAction(sender: AnyObject?) {
        if !self.tokenView.isEditing {
            self.tokenView.beginEditing()
        }
    }
    
    func inviteListAction(sender: AnyObject?) {
        inviteList()
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
        
        let doneTitle = (self.flow == .internalCreate || self.flow == .onboardCreate) ? "Done" : "Invite"
        self.doneButton = UIBarButtonItem(title: doneTitle, style: .plain, target: self, action: #selector(doneAction(sender:)))
        self.doneButton.isEnabled = (self.flow == .internalCreate || self.flow == .onboardCreate) ? true : false
        
        if self.flow == .none {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x:0, y:0, width:36, height:36)
            button.addTarget(self, action: #selector(inviteListAction(sender:)), for: .touchUpInside)
            button.showsTouchWhenHighlighted = true
            button.setImage(UIImage(named: "imgEnvelopeLight"), for: .normal)
            button.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)

            let invitesButton = UIBarButtonItem(title: "Pending invites", style: .plain, target: self, action: #selector(inviteListAction(sender:)))
            let invitesIconButton = UIBarButtonItem(customView: button)
            invitesButton.tintColor = Colors.brandColor
            self.toolbarItems = [Ui.spacerFlex, invitesIconButton, invitesButton,  Ui.spacerFlex]
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            self.navigationItem.rightBarButtonItems = [doneButton]
        }
        
        if self.flow == .none {
            if self.presented {
                let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
                self.navigationItem.leftBarButtonItems = [closeButton]
            }
        }
    }
    
    func bind() {
        
        let groupId = StateController.instance.group?.id ?? self.inputGroupId!
        let userId = UserController.instance.userId!
        
        self.invitedEmails.removeAll()
        FireController.db.child("invites/\(groupId)/\(userId)").observeSingleEvent(of: .value, with: { snap in
            if !(snap.value is NSNull) && snap.hasChildren() {
                for item in snap.children  {
                    let snapInvite = item as! DataSnapshot
                    let map = snapInvite.value as! [String: Any]
                    if let role = map["role"] as? String {
                        if (self.inputRole == "members" && role == "member") ||
                            (self.inputRole == "guests" && role == "guest") {
                            let email = map["email"] as! String
                            if self.invitedEmails[email] == nil {
                                self.invitedEmails[email] = []
                            }
                            self.invitedEmails[email]?.append(map)
                        }
                    }
                }
            }
            
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
        })
    }
    
    func navigateToGroup() {
        let groupId = self.inputGroupId!
        FireController.instance.findGeneralChannel(groupId: groupId) { channelId in
            if channelId != nil {
                StateController.instance.setChannelId(channelId: channelId!, groupId: groupId)
                MainController.instance.showChannel(channelId: channelId!, groupId: groupId)
                self.navigationController?.close()
            }
        }
    }

    func navigateToChannel() {
        let groupId = self.inputGroupId!
        let channelId = self.inputChannelId!
        StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
        MainController.instance.showChannel(channelId: channelId, groupId: groupId)
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
    
    func inviteList() {
        let controller = InviteListController()
        self.navigationController?.pushViewController(controller, animated: true)
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
        
        if self.inputRole == "members" {
            
            Reporting.track("invite_group_members")
            
            let groupId = self.inputGroupId ?? StateController.instance.groupId!
            let groupTitle = self.inputGroupTitle ?? StateController.instance.group!.title!
            let username = UserController.instance.user!.username!
            
            for key in self.picks.keys {
                var email: String!
                if let contact = self.picks[key] as? CNContact {
                    email = contact.emailAddresses.first?.value as? String
                } else if let contact = self.picks[key] as? String {
                    email = contact
                }
                let inviteId = "in-\(Utils.genRandomId())"
                
                BranchProvider.inviteMember(groupId: groupId, groupTitle: groupTitle, username: username, email: email!, inviteId: inviteId, completion: { response, error in
                    
                    if error == nil {
                        
                        let invite = response as! InviteItem
                        let inviteUrl = invite.url
                        let userTitle = UserController.instance.userTitle
                        let userEmail = UserController.instance.userEmail
                        let userId = UserController.instance.userId!
                        let username = UserController.instance.user?.username
                        let ref = FireController.db.child("queue/invites").childByAutoId()
                        let timestamp = FireController.instance.getServerTimestamp()
                        
                        var task: [String: Any] = [:]
                        task["created_at"] = timestamp
                        task["created_by"] = userId
                        task["group"] = ["id": groupId, "title": groupTitle]
                        task["id"] = ref.key
                        task["inviter"] = ["id": userId, "title": userTitle, "username": username, "email": userEmail]
                        task["invite_id"] = inviteId
                        task["link"] = inviteUrl
                        task["recipient"] = email
                        task["state"] = "waiting"
                        task["type"] = "invite-members"
                        
                        ref.setValue(task) { error, ref in
                            if error != nil {
                                Log.w("Error queueing invite task: \(error!)")
                            }
                            else {
                                UIShared.toast(message: "Invites sent")
                            }
                            if self.flow == .onboardCreate || self.flow == .internalCreate {
                                self.navigateToGroup()
                            }
                            else {
                                self.close()
                            }
                        }
                    }
                })
            }
        }
        else if self.inputRole == "guests" {
            
            Reporting.track("invite_channel_guests")
            
            let channels = [self.inputChannelId!: self.inputChannelName!]
            
            for key in self.picks.keys {
                
                let inviteId = "in-\(Utils.genRandomId())"
                var email: String!
                
                if let contact = self.picks[key] as? CNContact {
                    email = contact.emailAddresses.first?.value as? String
                }
                else if let contact = self.picks[key] as? String {
                    email = contact
                }
                
                BranchProvider.inviteGuest(group: StateController.instance.group, channels: channels, email: email!, inviteId: inviteId, completion: { response, error in
                    
                    if error == nil {
                        
                        let invite = response as! InviteItem
                        let inviteUrl = invite.url
                        let userTitle = UserController.instance.userTitle
                        let userEmail = UserController.instance.userEmail
                        let userId = UserController.instance.userId!
                        let username = UserController.instance.user?.username
                        
                        let group = StateController.instance.group!
                        let groupTitle = group.title!
                        let groupId = StateController.instance.group?.id ?? self.inputGroupId!
                        let timestamp = FireController.instance.getServerTimestamp()
                        let ref = FireController.db.child("queue/invites").childByAutoId()
                        
                        var task: [String: Any] = [:]
                        task["channels"] = channels
                        task["created_at"] = timestamp
                        task["created_by"] = userId
                        task["group"] = ["id": groupId, "title": groupTitle]
                        task["id"] = ref.key
                        task["inviter"] = ["id": userId, "title": userTitle, "username": username, "email": userEmail]
                        task["invite_id"] = inviteId
                        task["link"] = inviteUrl
                        task["recipient"] = email
                        task["state"] = "waiting"
                        task["type"] = "invite-guests"
                        
                        ref.setValue(task) { error, ref in
                            if error != nil {
                                Log.w("Error queueing invite task: \(error!)")
                            }
                            else {
                                UIShared.toast(message: "Invites sent")
                            }
                            if self.flow == .internalCreate {
                                self.navigateToChannel()
                            }
                            else {
                                self.close()
                            }
                        }
                    }
                })
            }
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
        
        let email = contact.emailAddresses.first?.value as String!
        let invites: [[String: Any]]? = self.invitedEmails[email!]
        let status = statusFromInvites(invites: invites)
        cell.bind(contact: contact, status: status)
        
        cell.checkBox?.on = false
        if let contact = cell.contact {
            let invited = (self.picks[contact.identifier] != nil)
            cell.checkBox?.on = invited
        }
        
        return cell
    }
    
    func statusFromInvites(invites: [[String: Any]]?) -> String {
        
        guard invites != nil && invites!.count > 0 else {
            return "none"
        }
        
        if self.inputRole == "members" {
            for invite in invites! {
                let inviteStatus = (invite["status"] as? String) ?? "none"
                if inviteStatus == "accepted" {
                    return "accepted"
                }
            }
            return "pending"
        }
        else if self.inputRole == "guests" {
            /* Do current invites cover all the targeted channels */
            var status = "accepted"
            let channelId = self.inputChannelId!
            var hit = false
            for invite in invites! {
                let inviteStatus = invite["status"] as! String
                if let inviteChannels = invite["channels"] as? [String: String] {
                    for inviteChannelId in inviteChannels.keys {
                        if inviteChannelId == channelId {
                            hit = true
                            if inviteStatus == "pending" {
                                status = "pending"
                            }
                        }
                    }
                }
            }
            if !hit {
                return "none"
            }
            return status
        }
        return "none"
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
            if self.flow == .internalCreate || self.flow == .onboardCreate {
                self.doneButton.title = "Done"
            }
            else {
                self.doneButton.isEnabled = false
            }
        }
        else {
            if self.flow == .internalCreate || self.flow == .onboardCreate {
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
            if self.flow == .internalCreate || self.flow == .onboardCreate {
                self.doneButton.title = "Done"
            }
            else {
                self.doneButton.isEnabled = false
            }
        }
        else {
            if self.flow == .internalCreate || self.flow == .onboardCreate {
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

