//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import CLTokenInputView

/* Routes
 * - Channel create flow: channeledit->memberpicker (.internalCreate)
 * - From member list: memberlist->memberpicker (.none)
 */

class MemberPickerController: BaseTableController, CLTokenInputViewDelegate {
    
    var inputChannelId: String?
    
    var heading	= AirLabelTitle()
    var tokenView: AirTokenView!
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var doneButton: UIBarButtonItem!

    var items: [String: Any] = [:]
    var itemsFiltered = [FireUser]()
    var itemsSource = [FireUser]()

    var filterText: String?
    var filterActive = false
    var flow: Flow = .none

    var invites: [String: Any] = [:]
    var channel: FireChannel!
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        let groupId = StateController.instance.groupId!
        let channelId = self.inputChannelId ?? StateController.instance.channelId!
        let userId = UserController.instance.userId!
        let channelQuery = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)
        
        channelQuery.once(with: { error, channel in
            if channel != nil {
                self.channel = channel
                let channelName = self.channel.name!
                self.heading.text = "Add group members to #\(channelName)"
                self.view.setNeedsLayout()
                self.bind()
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let headingSize = self.heading.sizeThatFits(CGSize(width:288, height:CGFloat.greatestFiniteMagnitude))
        let navHeight = self.navigationController?.navigationBar.height() ?? 0
        let statusHeight = UIApplication.shared.statusBarFrame.size.height
        
        self.heading.anchorTopCenter(withTopPadding: (navHeight + statusHeight + 24), width: 288, height: headingSize.height)
        self.tokenView.alignUnder(self.heading, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 16, height: tokenView.height())
        self.tableView.alignUnder(self.tokenView, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    func addMembersAction(sender: AnyObject?) {
        addMembers()
    }

    func closeAction(sender: AnyObject?) {
        if self.flow == .internalCreate {
            let groupId = StateController.instance.groupId!
            let channelId = self.inputChannelId ?? StateController.instance.channelId!
            StateController.instance.setChannelId(channelId: channelId, groupId: groupId) // We know it's good
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
        }
        self.close(animated: true)
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
        
        self.heading.text = "Add group members"
        self.heading.textAlignment = NSTextAlignment.center
        self.heading.numberOfLines = 0
        
        self.tokenView = AirTokenView(frame: CGRect(x: 0, y: 0, width: self.view.width(), height: 44))
        self.tokenView.placeholder.text = "Search"
        self.tokenView.placeholder.textColor = Theme.colorTextPlaceholder
        self.tokenView.placeholder.font = Theme.fontComment
        self.tokenView.backgroundColor = Colors.white
        self.tokenView.tokenizationCharacters = [",", " ", ";"]
        self.tokenView.delegate = self
        self.tokenView.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin, UIViewAutoresizing.flexibleWidth]
        
        self.tableView.register(UINib(nibName: "UserListCell", bundle: nil), forCellReuseIdentifier: "user-cell")
        self.tableView.backgroundColor = Theme.colorBackgroundTable
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 64
        self.tableView.separatorInset = UIEdgeInsets.zero
        
        self.view.addSubview(self.heading)
        self.view.addSubview(self.tokenView)
        self.view.addSubview(self.tableView)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
        let doneTitle = self.flow == .internalCreate ? "Done" : "Add"
        self.doneButton = UIBarButtonItem(title: doneTitle, style: .plain, target: self, action: #selector(addMembersAction(sender:)))
        self.doneButton.isEnabled = self.flow == .internalCreate ? true : false
        self.navigationItem.rightBarButtonItems = [self.doneButton]
        self.navigationItem.leftBarButtonItems = [closeButton]
    }

    func bind() {

        self.itemsSource.removeAll()
        self.itemsFiltered.removeAll()

        let groupId = StateController.instance.groupId!
        let query = FireController.db.child("group-members/\(groupId)")
            .queryOrdered(byChild: "index_priority_joined_at_desc")
        
        query.observe(.value, with: { [weak self] snap in
            self?.itemsSource.removeAll()
            if !(snap.value is NSNull) && snap.hasChildren() {
                for item in snap.children {
                    let member = item as! FIRDataSnapshot
                    let userId = member.key
                    UserQuery(userId: userId, groupId: nil).once(with: { error, user in
                        if error != nil {
                            Log.w("Permission denied")
                            return
                        }
                        if user != nil {
                            user!.membershipFrom(dict: member.value as! [String : Any])
                            self?.itemsSource.append(user!)
                        }
                    })
                }
            }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }, withCancel: { error in
            Log.w("Permission denied")
        })

        self.tableView.dataSource = self.tableViewDataSource
    }

    func filter() {
        self.itemsFiltered.removeAll()
        for user in self.itemsSource {
            if user.username!.lowercased().contains(self.filterText!.lowercased()) {
                self.itemsFiltered.append(user)
            }
            else if let profile = user.profile, let fullName = profile.fullName {
                if fullName.lowercased().contains(self.filterText!.lowercased()) {
                    self.itemsFiltered.append(user)
                }
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func addMembers() {
        
        if self.flow == .internalCreate {
            let groupId = self.channel.groupId!
            let channelId = self.channel.id!
            let channelName = self.channel.name!
            for userId in self.invites.keys {
                FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
            }
            StateController.instance.setChannelId(channelId: channelId, groupId: groupId) // We know it's good
            MainController.instance.showChannel(groupId: groupId, channelId: channelId)
            self.close(animated: true)
        }
        else {
            let channelName = self.channel.name!
            var message = "The following group members will be added to the \(channelName) channel:\n\n"
            for userId in self.invites.keys {
                if let username = (self.invites[userId] as! FireUser).username {
                    message += "\(username)\n"
                }
            }
            UpdateConfirmationAlert(title: "Add to channel", message: message, actionTitle: "Add", cancelTitle: "Cancel", delegate: nil, onDismiss: { doit in
                if doit {
                    let groupId = self.channel.groupId!
                    let channelId = self.channel.id!
                    for userId in self.invites.keys {
                        FireController.instance.addUserToChannel(userId: userId, groupId: groupId, channelId: channelId, channelName: channelName)
                    }
                    self.close(animated: true)
                }
            })
        }
    }
}

extension MemberPickerController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? UserListCell {
            if cell.allowSelection {
                cell.checkBox?.setOn(true, animated: true)
                let user = cell.user!
                self.invites[user.id!] = user
                if self.invites.count == 0 {
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
            cell.checkBox?.setOn(false, animated: true)
            let user = cell.user!
            self.invites.removeValue(forKey: user.id!)
            if self.invites.count == 0 {
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

extension MemberPickerController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "user-cell", for: indexPath) as! UserListCell
        let user = self.filterActive ? self.itemsFiltered[indexPath.row] : self.itemsSource[indexPath.row]
        let userId = user.id!
        let groupId = StateController.instance.groupId!
        let channelId = self.channel.id!
        
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.roleLabel?.isHidden = true
        cell.reset()
        
        FireController.instance.isChannelMember(userId: userId, channelId: channelId, groupId: groupId, next: { result in
            cell.bind(user: user)
            if result == nil { return }
            if result! {
                cell.roleLabel?.isHidden = false
                cell.roleLabel?.text = "already a member"
                cell.roleLabel?.textColor = MaterialColor.lightGreen.base
                cell.checkBox?.isHidden = true
                cell.allowSelection = false
            }
            else {
                cell.roleLabel?.isHidden = true
                cell.checkBox?.isHidden = false
                cell.checkBox?.on = cell.isSelected
            }
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterActive ? self.itemsFiltered.count : self.itemsSource.count
    }
    
    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
}

extension MemberPickerController {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        self.filterActive = (text != nil && !text!.trimmingCharacters(in: .whitespaces).isEmpty)
        self.filterText = (text != nil) ? text!.trimmingCharacters(in: .whitespaces) : nil
        if filterActive {
            filter()
        }
        else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        self.doneButton.isEnabled = (self.tokenView.allTokens.count > 0)
        if let itemId = token.context as? String {
            self.items[itemId] = token.displayText
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        self.doneButton.isEnabled = (self.tokenView.allTokens.count > 0)
        if let itemId = token.context as? String {
            self.items.removeValue(forKey: itemId)
        }
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
            self.items[user.id!] = channel
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

