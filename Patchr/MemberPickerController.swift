//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import CLTokenInputView

/* Routes
 * - Channel create flow: channelswitcher->channeledit->channelinvite->memberpicker (.internalCreate)
 * - Invite/add channel member flow: memberlist->channelinvite->memberpicker (.none)
 * - Invite/add channel member flow: channelview->channelinvite->memberpicker (.none)
 */
class MemberPickerController: BaseTableController, CLTokenInputViewDelegate {
    
    var inputChannelId: String!
    var inputChannelName: String!
    var inputAsOwner = false
    
    var tokenView: AirTokenView!
    var doneButton: UIBarButtonItem!

    var flow: Flow = .none
    var picks: [String: Any] = [:]
    
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
        
        self.tokenView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: tokenView.height())
        self.tableView.alignUnder(self.tokenView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func inviteMembersAction(sender: AnyObject?) {
        inviteMembers()
    }

    func closeAction(sender: AnyObject?) {
        if self.flow == .internalCreate {
            let groupId = StateController.instance.groupId!
            let channelId = self.inputChannelId!
            StateController.instance.setChannelId(channelId: channelId, groupId: groupId) // We know it's good
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
        }
        self.close(animated: true)
    }
    
    func inviteListAction(sender: AnyObject?) {
        inviteList()
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
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.navigationItem.title = "Group members"
        
        self.tokenView = AirTokenView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.tokenView.placeholder.text = "Search"
        self.tokenView.placeholder.textColor = Theme.colorTextPlaceholder
        self.tokenView.placeholder.font = Theme.fontComment
        self.tokenView.backgroundColor = Colors.white
        self.tokenView.tokenizationCharacters = [",", " ", ";"]
        self.tokenView.delegate = self
        self.tokenView.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleWidth]
        
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 64
        self.tableView.allowsMultipleSelection = true
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        self.tableView.tableFooterView = UIView()
        
        self.view.addSubview(self.tokenView)
        self.view.addSubview(self.tableView)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
        let doneTitle = (self.flow == .internalCreate) ? "Done" : "Invite"
        self.doneButton = UIBarButtonItem(title: doneTitle, style: .plain, target: self, action: #selector(inviteMembersAction(sender:)))
        self.doneButton.isEnabled = (self.flow == .internalCreate) ? true : false
        self.navigationItem.rightBarButtonItems = [self.doneButton]
        
        if self.presented {
            self.navigationItem.leftBarButtonItems = [closeButton]
        }
        
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
    }

    func bind() {

        let groupId = StateController.instance.groupId!
        let query = FireController.db.child("group-members/\(groupId)")
            .queryOrdered(byChild: "index_priority_joined_at_desc")
        
        self.queryController = DataSourceController(name: "member_picker")
        self.queryController.mapperActive = true
        self.queryController.mapper = { (snap, then) in
            let userId = snap.key
            UserQuery(userId: userId, groupId: nil).once(with: { error, user in
                if error != nil {
                    Log.w("Permission denied")
                    return
                }
                if user != nil {
                    user!.membershipFrom(dict: snap.value as! [String : Any])
                    then(user)
                }
            })
        }
        
        self.queryController.matcher = { searchText, data in
            let user = data as! FireUser
            if user.username!.lowercased().contains(searchText.lowercased()) {
                return true
            }
            else if let profile = user.profile, let fullName = profile.fullName {
                if fullName.lowercased().contains(searchText.lowercased()) {
                    return true
                }
            }
            return false
        }

        self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserListCell
            
            func bindCell(user: FireUser) {
                
                let userId = user.id!
                let channelId = self!.inputChannelId!
                
                cell.selectionStyle = .none
                cell.accessoryType = .none
                cell.roleLabel?.isHidden = true
                
                FireController.instance.isChannelMember(userId: userId, channelId: channelId, groupId: groupId, next: { result in
                    cell.bind(user: user)
                    if result == nil { return }
                    if result! {
                        cell.roleLabel?.isHidden = false
                        cell.roleLabel?.text = "channel member"
                        cell.roleLabel?.textColor = MaterialColor.lightGreen.base
                        cell.checkBox?.isHidden = true
                        cell.allowSelection = false
                    }
                    else {
                        if user.email != nil {
                            cell.roleLabel?.isHidden = true
                            cell.checkBox?.isHidden = false
                            cell.checkBox?.on = cell.isSelected
                        }
                        else if !(self?.inputAsOwner)! {
                            cell.roleLabel?.isHidden = false
                            cell.roleLabel?.text = "email unavailable"
                            cell.roleLabel?.textColor = MaterialColor.lightGreen.base
                            cell.checkBox?.isHidden = true
                            cell.allowSelection = false
                        }
                    }
                })
            }
            
            if self != nil {
                cell.reset()
                if let user = data as? FireUser {
                    bindCell(user: user)
                }
                else {
                    let snap = data as! FIRDataSnapshot
                    let userId = snap.key
                    UserQuery(userId: userId, groupId: nil).once(with: { error, user in
                        if error != nil {
                            Log.w("Permission denied")
                            return
                        }
                        if user != nil {
                            user!.membershipFrom(dict: snap.value as! [String : Any])
                            bindCell(user: user!)
                        }
                    })
                }
            }
            
            return cell
        }
    }
    
    func inviteList() {
        let controller = InviteListController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func inviteMembers() {
        
        if self.inputAsOwner {
            
            let groupId = StateController.instance.groupId!
            let channelId = self.inputChannelId!
            let channelName = self.inputChannelName!
            
            if self.flow == .internalCreate {
                for userId in self.picks.keys {
                    FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
                }
                StateController.instance.setChannelId(channelId: channelId, groupId: groupId) // We know it's good
                MainController.instance.showChannel(groupId: groupId, channelId: channelId)
                self.close(animated: true)
            }
            else {
                var message = "The following group members will be added to the \(channelName) channel:\n\n"
                for userId in self.picks.keys {
                    if let username = (self.picks[userId] as! FireUser).username {
                        message += "\(username)\n"
                    }
                }
                UpdateConfirmationAlert(title: "Add to channel", message: message, actionTitle: "Add", cancelTitle: "Cancel", delegate: nil, onDismiss: { doit in
                    if doit {
                        for userId in self.picks.keys {
                            FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
                        }
                        self.close(animated: true)
                    }
                })
            }
        }
        else {
            
            let channels = [self.inputChannelId!: self.inputChannelName!]
            
            for key in self.picks.keys {
                
                let inviteId = "in-\(Utils.genRandomId())"
                let email = self.picks[key] as! String
                
                BranchProvider.inviteGuest(group: StateController.instance.group, channels: channels, email: email, inviteId: inviteId, completion: { response, error in
                    
                    if error == nil {
                        
                        let invite = response as! InviteItem
                        let inviteUrl = invite.url
                        let userTitle = UserController.instance.userTitle
                        let userEmail = UserController.instance.userEmail
                        let userId = UserController.instance.userId!
                        let username = UserController.instance.user?.username
                        
                        let group = StateController.instance.group!
                        let groupTitle = group.title!
                        let groupId = StateController.instance.groupId!
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
                            self.close(root: (self.flow != .internalInvite))
                        }
                    }
                })
            }
        }
    }
}

extension MemberPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            if cell.allowSelection {
                let user = cell.user!
                cell.checkBox?.setOn(true, animated: true)
                self.picks[user.id!] = user
                self.tokenView.add(CLToken(displayText: user.fullName!, context: cell))
                if self.picks.count == 0 {
                    if self.flow == .internalCreate {
                        self.doneButton.title = "Done"
                    } else {
                        self.doneButton.isEnabled = false
                    }
                }
                else {
                    if self.flow == .internalCreate {
                        self.doneButton.title = "Add"
                    } else {
                        self.doneButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            let user = cell.user!
            cell.checkBox?.setOn(false, animated: true)
            self.picks.removeValue(forKey: user.id!)
            self.tokenView.remove(CLToken(displayText: user.fullName!, context: cell))
            if self.picks.count == 0 {
                if self.flow == .internalCreate {
                    self.doneButton.title = "Done"
                } else {
                    self.doneButton.isEnabled = false
                }
            }
            else {
                if self.flow == .internalCreate {
                    self.doneButton.title = "Add"
                } else {
                    self.doneButton.isEnabled = true
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

extension MemberPickerController {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        if text != nil && !text!.trimmingCharacters(in: .whitespaces).isEmpty {
            let searchText = text!.trimmingCharacters(in: .whitespaces)
            self.queryController.filter(searchText: searchText)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        self.doneButton.isEnabled = (self.tokenView.allTokens.count > 0)
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        self.doneButton.isEnabled = (self.tokenView.allTokens.count > 0)
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.tokenView.frame.size.height = height
            let navHeight = self.navigationController?.navigationBar.height() ?? 0
            let statusHeight = UIApplication.shared.statusBarFrame.size.height
            self.tokenView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: (navHeight + statusHeight), height: self.tokenView.height())
            self.tableView.alignUnder(self.tokenView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
        })
    }
    
    func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        Log.d("tokenForText")
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? UserListCell {
            let user = cell.user!
            return CLToken(displayText: user.username!, context: cell)
        }
        
        return nil
    }
    
    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        self.tokenView.editingEnd()
        self.tableView.reloadData()
    }
    
    func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        self.tokenView.editingBegin()
        self.tableView.reloadData()
    }
    
    func tokenInputViewShouldReturn(_ view: CLTokenInputView) -> Bool {
        Log.d("tokenInputViewShouldReturn")
        return true
    }
}
