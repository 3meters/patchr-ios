//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import SlideMenuControllerSwift
import pop

class ChannelSwitcherController: BaseTableController {

	var unreadsTotalQuery: UnreadQuery?
	var unreadsGroupQuery: UnreadQuery?

	var searchBar: UISearchBar!
	var searchBarHolder = UIView()
	var searchController: SearchController!
	var searchTableView = AirTableView(frame: CGRect.zero, style: .plain)
	var searchOn = false
	var rule = UIView()
	var transitionManager = PushDownAnimationController()

	var gradientImage: UIImage!
	var dropdownButton: DropdownButton!
	var titleView: UILabel!
	var subtitleView: UILabel!

	var showGroupsButton: UIBarButtonItem!
	var searchBarButton: UIBarButtonItem!
	var searchButton: UIBarButtonItem!
	var titleButton: UIBarButtonItem!

	var role = "guest"

	var unreadTotal = 0
	var unreadGroup = 0
	var unreadOther: Int? {
		didSet {
			if unreadOther != oldValue {
				updateDropdownButton()
			}
		}
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Lifecycle
	*--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
		bind()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.navigationBar.setBackgroundImage(self.gradientImage, for: .default)
		self.navigationController?.navigationBar.tintColor = Colors.white
        self.dropdownButton.isUserInteractionEnabled = true
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
        
        self.view.fillSuperview()
		if self.searchOn {
			self.searchTableView.fillSuperview()
		} else {
			self.tableView.fillSuperview()
		}
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Events
	*--------------------------------------------------------------------------------------------*/

	func addAction(sender: AnyObject?) {

		if self.role == "guest" {
			UIShared.toast(message: "Guests can\'t create new channels.")
			return
		}

		FireController.instance.isConnected() { connected in
			if connected == nil || !connected! {
				let message = "Creating a channel requires a network connection."
				self.alert(title: "Not connected", message: message, cancelButtonTitle: "OK")
			}
			else {
				let groupId = StateController.instance.groupId!
				let controller = ChannelEditViewController()
				let wrapper = AirNavigationController(rootViewController: controller)
				controller.mode = .insert
				controller.inputGroupId = groupId
				self.slideMenuController()?.closeLeft()
				self.present(wrapper, animated: true, completion: nil)
			}
		}
	}

	func showGroupsAction(sender: AnyObject?) {
		let controller = MainController.groupPicker
		controller.view.setNeedsLayout()
		let _ = self.navigationController?.pushViewController(controller, animated: true)
	}

	func searchAction(sender: AnyObject?) {
		search(on: true)
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	func userDidSwitch(notification: NSNotification?) {
		bind()
	}

	func groupDidSwitch(notification: NSNotification?) {
		bind()
	}

	func channelDidSwitch(notification: NSNotification?) {
		self.tableView.reloadData()
	}

	func leftWillOpen(notification: NSNotification?) {
        self.dropdownButton.isUserInteractionEnabled = true
	}

	func leftDidClose(notification: NSNotification?) {
		if self.searchOn {
			self.search(on: false)
			self.searchBar?.setShowsCancelButton(false, animated: false)
			self.searchBar?.endEditing(true)
			self.searchController.queryController.clearFilter()
			self.searchTableView.reloadData()
		}
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Methods
	*--------------------------------------------------------------------------------------------*/

	override func initialize() {
		super.initialize()

        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setToolbarHidden(false, animated: true)

		self.rule.backgroundColor = Theme.colorSeparator
        
		self.tableView.backgroundColor = Theme.colorBackgroundTable
		self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
		self.tableView.estimatedRowHeight = 36
		self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.contentInset = UIEdgeInsets(top: 74, left: 0, bottom: 44, right: 0)
        self.tableView.contentOffset = CGPoint(x: 0, y: -74)
		self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: "cell")
        
		self.view.addSubview(self.tableView)

        self.searchController = SearchController(tableView: self.searchTableView)
        
		self.searchTableView.backgroundColor = Theme.colorBackgroundTable
		self.searchTableView.tableFooterView = UIView()
		self.searchTableView.delegate = self
		self.searchTableView.separatorInset = UIEdgeInsets.zero
        self.searchTableView.contentInset = UIEdgeInsets(top: 74, left: 0, bottom: 44, right: 0)
        self.searchTableView.contentOffset = CGPoint(x: 0, y: -74)
		self.searchTableView.register(UINib(nibName: "ChannelSearchCell", bundle: nil), forCellReuseIdentifier: "cell")

		self.searchBar = UISearchBar(frame: CGRect.zero)
		self.searchBar.autocapitalizationType = .none
		self.searchBar.backgroundColor = Colors.clear
		self.searchBar.delegate = self
		self.searchBar.placeholder = "Search"
		self.searchBar.searchBarStyle = .prominent

		for subview in self.searchBar.subviews[0].subviews {
			if subview is UITextField {
				subview.tintColor = Colors.accentColor
			}
			if subview.isKind(of: NSClassFromString("UISearchBarBackground")!) {
				subview.alpha = 0.0
			}
		}

		self.searchBarHolder.addSubview(self.searchBar)
		self.searchBarButton = UIBarButtonItem(customView: self.searchBarHolder)
		self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchAction(sender:)))

		/* Dropdown button */
		self.dropdownButton = DropdownButton()
		self.dropdownButton.badgeLabel.alpha = CGFloat(0)
		self.dropdownButton.addTarget(self, action: #selector(showGroupsAction(sender:)), for: .touchUpInside)
        self.dropdownButton.isUserInteractionEnabled = true
        self.dropdownButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
		self.showGroupsButton = UIBarButtonItem(customView: dropdownButton)

		let gradient = CAGradientLayer()
		gradient.frame = CGRect(x: 0, y: 0, width: Config.navigationDrawerWidth, height: 64)
		gradient.colors = [Colors.accentColor.cgColor, Colors.brandColor.cgColor]
		gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
		gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
		gradient.zPosition = 1
		gradient.shouldRasterize = true
		gradient.rasterizationScale = UIScreen.main.scale

		self.gradientImage = ImageUtils.imageFromLayer(layer: gradient)

		let titleWidth = (Config.navigationDrawerWidth - 112)
		self.titleView = AirLabelDisplay(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 24))
		self.subtitleView = AirLabelDisplay(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 24))
		self.titleView.font = Theme.fontTextList
		self.subtitleView.font = Theme.fontBarText
		self.subtitleView.text = "Channels"
		self.subtitleView.textColor = Colors.white
		let titleHolder = UIView(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 56))
		titleHolder.addSubview(titleView)
		titleHolder.addSubview(subtitleView)
		self.titleView.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: titleWidth, height: 24)
		self.subtitleView.alignUnder(self.titleView, matchingLeftWithTopPadding: -2, width: titleWidth, height: 24)
		self.titleButton = UIBarButtonItem(customView: titleHolder)

		self.navigationItem.leftBarButtonItem = self.titleButton
		self.navigationItem.hidesBackButton = true
        self.navigationController?.delegate = self // For animation controller

		NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(groupDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidSwitch), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(channelDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.ChannelDidSwitch), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(leftDidClose(notification:)), name: NSNotification.Name(rawValue: Events.LeftDidClose), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(leftWillOpen(notification:)), name: NSNotification.Name(rawValue: Events.LeftWillOpen), object: nil)
	}

	func bind() {

		if let userId = UserController.instance.userId,
		   let groupId = StateController.instance.groupId {

			self.navigationItem.setRightBarButtonItems([self.showGroupsButton], animated: true)

			let path = "member-groups/\(userId)/\(groupId)/role"
			FireController.db.child(path).observeSingleEvent(of: .value, with: { [weak self] snap in
                if let role = snap.value as? String, self != nil {
                    self!.role = role
                    if role != "guest" {
                        self!.navigationItem.setRightBarButtonItems([self!.showGroupsButton, self!.searchButton], animated: true)
                        self!.searchController.load()
                    }

                    let addButton = UIBarButtonItem(title: "New Channel", style: .plain, target: self, action: #selector(self?.addAction(sender:)))
                    addButton.tintColor = Colors.brandColor
                    self?.toolbarItems = [spacerFlex, addButton, spacerFlex]
                }
            }, withCancel: { error in
                Log.w("Permission denied: \(path)")
            })

			if self.titleButton != nil {
				FireController.db.child("groups/\(groupId)/title").observe(.value, with: { [weak self] snap in
                    if let title = snap.value as? String {
                        self?.titleView.text = title
                    }
                })
			}

			self.unreadsTotalQuery?.remove()
			self.unreadsTotalQuery = UnreadQuery(level: .user, userId: userId)
			self.unreadsTotalQuery!.observe(with: { error, total in
				if total != self.unreadTotal {
					self.unreadTotal = total ?? 0
					self.unreadOther = self.unreadTotal - self.unreadGroup
				}
			})

			self.unreadsGroupQuery?.remove()
			self.unreadsGroupQuery = UnreadQuery(level: .group, userId: userId, groupId: groupId)
			self.unreadsGroupQuery!.observe(with: { error, total in
				if total != self.unreadGroup {
					self.unreadGroup = total ?? 0
					self.unreadOther = self.unreadTotal - self.unreadGroup
				}
			})

			let query = FireController.db.child("member-channels/\(userId)/\(groupId)")
					.queryOrdered(byChild: "index_priority_joined_at_desc")
            
            self.queryController = DataSourceController(name: "channel_switcher")
            self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChannelListCell
                
                if self != nil {
                    
                    if let userId = UserController.instance.userId,
                        let groupId = StateController.instance.groupId,
                        let snap = data as? FIRDataSnapshot {
                        
                        let channelId = snap.key
                        
                        cell.reset()    // Releases previous data observers
                        cell.query = ChannelQuery(groupId: groupId, channelId: channelId, userId: userId)    // Just channel lookup
                        cell.query!.observe(with: { error, channel in
                            
                            if channel != nil {
                                cell.selected(on: (channelId == StateController.instance.channelId), style: .prominent)
                                cell.bind(channel: channel!)
                                cell.unreadQuery = UnreadQuery(level: .channel, userId: userId, groupId: groupId, channelId: channelId)
                                cell.unreadQuery!.observe(with: { error, total in
                                    if total != nil && total! > 0 {
                                        cell.badge?.text = "\(total!)"
                                        cell.badge?.isHidden = false
                                        cell.accessoryType = .none
                                    }
                                    else {
                                        cell.badge?.isHidden = true
                                        cell.accessoryType = cell.selectedOn ? .checkmark : .none
                                    }
                                })
                            }
                            else {
                                Log.w("Ouch! User is member of channel that does not exist")
                            }
                        })
                    }
                }
                return cell
            }
			self.view.setNeedsLayout()
		}
	}

	func search(on: Bool) {
		self.searchOn = on
		if on {
			self.navigationItem.title = nil
			self.navigationItem.setLeftBarButton(self.searchBarButton, animated: true)
			self.navigationItem.setRightBarButtonItems(nil, animated: true)
			self.searchBarHolder.frame = CGRect(x: 0, y: 0, width: (self.navigationController?.navigationBar.width())! - 32, height: 44)
			self.searchBar.fillSuperview()
			self.searchBar.becomeFirstResponder()
			self.tableView.removeFromSuperview()
			self.searchTableView.frame = self.view.bounds
			self.view.addSubview(self.searchTableView)
		}
		else {
			self.navigationItem.setLeftBarButton(self.titleButton, animated: true)
			self.navigationItem.setRightBarButtonItems([self.showGroupsButton, self.searchButton], animated: true)
			self.searchBar.resignFirstResponder()
			self.searchTableView.removeFromSuperview()
			self.tableView.frame = self.view.bounds
			self.view.addSubview(self.tableView)
		}
	}

	func updateDropdownButton() {
		let unreadOther = (self.unreadTotal - self.unreadGroup)
		self.dropdownButton.badgeLabel.text = unreadOther > 0 ? "\(unreadOther)" : nil
		self.dropdownButton.setNeedsLayout()
		self.dropdownButton.layoutIfNeeded()
		if unreadOther > 0 {
			self.dropdownButton.badgeLabel.fadeIn()
		} else {
			self.dropdownButton.badgeLabel.fadeOut()
		}
	}

	override var prefersStatusBarHidden: Bool {
		return false
	}
}

extension ChannelSwitcherController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
		let channelId = cell.channel.id!
		let groupId = cell.channel.groupId!
		self.slideMenuController()?.closeLeft()
		if let currentChannelId = StateController.instance.channelId {
			if channelId != currentChannelId {
				StateController.instance.setChannelId(channelId: channelId, groupId: groupId)
				MainController.instance.showChannel(groupId: groupId, channelId: channelId)
			}
		}

		if let indexPath = self.tableView.indexPathForSelectedRow {
			self.tableView.deselectRow(at: indexPath, animated: false)
		}
	}
}

extension ChannelSwitcherController: UISearchBarDelegate {

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		self.searchBar?.setShowsCancelButton(true, animated: true)
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		self.searchController.filter(searchText: searchText)
	}

	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		self.searchBar?.text = nil
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		search(on: false)
		self.searchBar?.setShowsCancelButton(false, animated: true)
		self.searchBar?.endEditing(true)
        self.searchController.queryController.clearFilter()
		self.searchTableView.reloadData()
	}
}

extension ChannelSwitcherController: UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		self.searchController.filter(searchText: self.searchBar!.text!)
	}
}

extension ChannelSwitcherController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController
        , animationControllerFor operation: UINavigationControllerOperation
        , from fromVC: UIViewController
        , to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitionManager.presenting = (operation == .push)
        return self.transitionManager
    }
}

class SearchController: NSObject {

	var tableView: UITableView!
    var queryController: DataSourceController!

	init(tableView: UITableView) {
		self.tableView = tableView
	}

	func filter(searchText: String, scope: String = "All") {
        self.queryController.filter(searchText: searchText)
	}

	func load() {

		let userId = UserController.instance.userId!
		let groupId = StateController.instance.groupId!
        let path = "group-channels/\(groupId)"  // User must be group member and not guest
        let query = FireController.db.child(path).queryOrdered(byChild: "name")
        
        self.queryController = DataSourceController(name:"channel_switcher")
        self.queryController.startEmpty = true
        self.queryController.matcher = { searchText, data in
            let snap = data as! FIRDataSnapshot
            let dict = snap.value as! [String: Any]
            let name = dict["name"] as! String
            return name.lowercased().contains(searchText.lowercased())
        }
        
        self.queryController.mapper = { (snap, then) in
            if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                if channel.visibility == "open" {
                    then(snap)
                }
                else { // Only add if user is currently a member
                    let channelId = channel.id!
                    let path = "member-channels/\(userId)/\(groupId)/\(channelId)"
                    FireController.db.child(path).observeSingleEvent(of: .value, with: { snapMember in
                        if !(snapMember.value is NSNull) {
                            then(snap)
                        }
                        else {
                            then(nil)
                        }
                    })
                }
            }
        }
        
        self.queryController.bind(to: self.tableView, query: query) { [weak self] tableView, indexPath, data in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChannelListCell
            if self != nil {
                let snap = data as! FIRDataSnapshot
                if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                    cell.reset()
                    cell.bind(channel: channel, searching: true)
                }
            }
            return cell
        }
	}
}
