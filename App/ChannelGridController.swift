//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import FirebaseAuth
import Localize_Swift
import pop

class ChannelGridController: UICollectionViewController {
    
    var authHandle: AuthStateDidChangeListenerHandle!
    
	var totalUnreadsQuery: UnreadQuery?
    var searchController = UISearchController(searchResultsController: nil)
    var queryController: DataSourceController!
    var titles: [String: String] = [:]

	var searchBar: UISearchBar!
	var searchBarHolder = UIView()
    
	var searchBarButton: UIBarButtonItem!
	var searchButton: UIBarButtonItem!
    var addButton: UIBarButtonItem!
    var menuButton: UIBarButtonItem!
	var titleButton: UIBarButtonItem!
    
    fileprivate var sectionInsets: UIEdgeInsets?
    fileprivate var cellWidth: CGFloat?
    fileprivate var cellHeight: CGFloat?
    fileprivate var availableWidth: CGFloat?

	/*--------------------------------------------------------------------------------------------
	* MARK: - Lifecycle
	*--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        if self.collectionView?.numberOfItems(inSection: 0) == 0 {
            bind()
        }
	}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
        self.view.fillSuperview()
        self.collectionView?.fillSuperview()
	}

    deinit {
        Log.v("ChannelGridController released")
        unbind()
    }

	/*--------------------------------------------------------------------------------------------
	* MARK: - Events
	*--------------------------------------------------------------------------------------------*/

	func addAction(sender: AnyObject?) {

		FireController.instance.isConnected() { connected in
			if connected == nil || !connected! {
				let message = "channel_not_connected_message".localizedFormat("creating".localized())
				self.alert(title: "channel_not_connected_title".localized(), message: message, cancelButtonTitle: "ok".localized())
			}
			else {
                Reporting.track("view_channel_new")
				let controller = ChannelEditViewController()
				let wrapper = AirNavigationController(rootViewController: controller)
				controller.mode = .insert
				self.present(wrapper, animated: true, completion: nil)
			}
		}
	}

	func searchAction(sender: AnyObject?) {
        self.navigationItem.setLeftBarButton(self.searchBarButton, animated: true)
        self.navigationItem.setRightBarButtonItems(nil, animated: true)
        self.searchBarHolder.frame = CGRect(x: 0, y: 0, width: (self.navigationController?.navigationBar.width())! - 24, height: 44)
        self.searchBar.fillSuperview()
        self.searchBar.becomeFirstResponder()
        self.searchBar?.setShowsCancelButton(true, animated: true)
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	func userDidSwitch(notification: NSNotification?) {
		bind()
	}

	/*--------------------------------------------------------------------------------------------
	* MARK: - Methods
	*--------------------------------------------------------------------------------------------*/

	func initialize() {
        
        self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
            guard let this = self else { return }
            if user == nil {
                this.totalUnreadsQuery?.remove()
            }
            if user == nil && this.queryController != nil {
                this.queryController.unbind()
            }
        }
        
        self.view.backgroundColor = Theme.colorBackgroundForm
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.collectionView?.delaysContentTouches = false
        
        self.searchController.dimsBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        
        /* Search bar when toggled on */
		self.searchBar = UISearchBar(frame: CGRect.zero)
		self.searchBar.autocapitalizationType = .none
		self.searchBar.backgroundColor = Colors.clear
		self.searchBar.delegate = self
		self.searchBar.searchBarStyle = .prominent
        if !self.searchBar!.isDescendant(of: self.view) {
            self.view.addSubview(self.searchBar!)
        }

		for subview in self.searchBar.subviews[0].subviews {
			if subview is UITextField {
				subview.tintColor = Colors.accentColor
			}
			if subview.isKind(of: NSClassFromString("UISearchBarBackground")!) {
				subview.alpha = 0.0
			}
		}

		self.searchBarHolder.addSubview(self.searchBar)
        self.searchBarButton = UIBarButtonItem(customView: self.searchBarHolder) // Used when search is visible
        
        /* Scroll inset */
        self.sectionInsets = UIEdgeInsets(top: self.searchBar!.frame.size.height + 12, left: 8, bottom: 16, right: 8)
        
        /* Calculate desired cell size */
        self.availableWidth = Config.screenWidth - (self.sectionInsets!.left + self.sectionInsets!.right)
        let requestedColumnWidth: CGFloat = 100
        let numColumns: CGFloat = floor(CGFloat(self.availableWidth!) / CGFloat(requestedColumnWidth))
        let spaceLeftOver = self.availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 8)
        self.cellWidth = requestedColumnWidth + (spaceLeftOver / numColumns)
        self.cellHeight = (self.cellWidth! * 0.65) + 32
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.cellWidth!, height: self.cellHeight!)
        layout.sectionInset = self.sectionInsets!
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        
        self.collectionView!.collectionViewLayout = layout
        
        self.collectionView!.backgroundColor = Theme.colorBackgroundForm
        self.collectionView!.contentInset = UIEdgeInsets(top: self.chromeHeight, left: 0, bottom: 44, right: 0)
        self.collectionView!.contentOffset = CGPoint(x: 0, y: -self.chromeHeight)
        self.collectionView!.register(UINib(nibName: "ChannelCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        /* Buttons (*/
		self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchAction(sender:)))
        self.addButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(addAction(sender:)))
        
        /* New channel button */
        var button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(#imageLiteral(resourceName: "imgChannelAdd"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
        self.addButton = UIBarButtonItem(customView: button)
        
        /* Menu button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 0)
        self.menuButton = UIBarButtonItem(customView: button)
        
        bindLanguage()

		self.navigationItem.leftBarButtonItem = self.searchButton
        self.navigationItem.setRightBarButtonItems([self.menuButton, UI.spacerFixed, self.addButton], animated: true)

		NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
	}
    
    func bindLanguage() {
        self.searchBar.placeholder = "channel_grid_search_bar_placeholder".localized()
        self.searchBar.setValue("cancel".localized(), forKey: "_cancelButtonText")
        self.navigationItem.title = "channel_grid_title".localizedFormat("patchr".localized())
    }

	func bind() {

		if let userId = UserController.instance.userId {
            
            unbind()

			let query = FireController.db.child("member-channels/\(userId)").queryOrdered(byChild: "activity_at_desc")
            
            self.queryController = DataSourceController(name: "channel_switcher")
            self.queryController.delegate = self
            self.queryController.matcher = { [weak self] searchText, data in
                guard let this = self else { return false }
                let snap = data as! DataSnapshot
                let key = snap.key
                let title = this.titles[key]! as String
                return title.lowercased().contains(searchText.lowercased())
            }
            
            self.queryController.bind(to: self.collectionView!, query: query) { [weak self] scrollView, indexPath, data in
                
                let collectionView = scrollView as! UICollectionView
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChannelCell
                cell.reset()    // Releases previous data observers
                
                guard self != nil else { return cell }
                
                if let snap = data as? DataSnapshot {
                    
                    let channelId = snap.key
                    
                    cell.channelQuery = ChannelQuery(channelId: channelId, userId: userId)    // Just channel lookup
                    cell.channelQuery!.observe(with: { [weak cell] error, channel in
                        guard let cell = cell else { return }
                        if error != nil {
                            cell.channelQuery?.remove()
                            Log.v("Removing channel from grid: \(channelId)")
                            return
                        }
                        if channel != nil {
                            cell.bind(channel: channel!)
                            cell.unreadQuery = UnreadQuery(level: .channel, userId: userId, channelId: channelId)
                            cell.unreadQuery!.observe(with: { [weak cell] error, total, isComment in
                                guard let cell = cell else { return }
                                if total != nil && total! > 0 {
                                    cell.badge?.text = "\(total!)"
                                    cell.badge?.isHidden = false
                                }
                                else {
                                    cell.badge?.isHidden = true
                                }
                            })
                        }
                    })
                    
                }
                return cell
            }
			self.view.setNeedsLayout()
		}
	}
    
    func unbind() {
        if self.queryController != nil {
            self.queryController.unbind()
        }
        self.totalUnreadsQuery?.remove()
    }
    
    func showActions(sender: AnyObject?) {
        
        Reporting.track("view_channel_grid_actions")
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let profileAction = UIAlertAction(title: "profile_and_settings".localized(), style: .default) { action in
            let wrapper = AirNavigationController(rootViewController: MemberViewController(userId: UserController.instance.userId!))
            UIViewController.topController?.present(wrapper, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: "cancel".localized(), style: .cancel) { action in
            sheet.dismiss(animated: true, completion: nil)
        }
        
        sheet.addAction(profileAction)
        sheet.addAction(cancel)
        
        if let presenter = sheet.popoverPresentationController {
            presenter.sourceView = self.menuButton.customView
            presenter.sourceRect = (self.menuButton.customView?.bounds)!
        }
    
        present(sheet, animated: true, completion: nil)
    }
    
    func scrollToFirstRow(animated: Bool = true) {
        let indexPath = IndexPath(row: 0, section: 0)
        self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
    }
}

extension ChannelGridController: FUICollectionDelegate {
    
    func arrayDidEndUpdates(_ collection: FUICollection) {
        self.titles.removeAll()
        for data in self.queryController.items {
            let snap = data as! DataSnapshot // Membership
            let channelId = snap.key
            let path = "channels/\(channelId)"
            FireController.db.child(path).observeSingleEvent(of: .value, with: { snap in
                if let dict = snap.value as? [String: Any] {
                    let channel = FireChannel(dict: dict, id: snap.key)
                    self.titles[channel.id!] = channel.title!
                }
            })
        }
    }
}

extension ChannelGridController {
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = Theme.colorBackgroundSelected
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = Theme.colorBackgroundCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) -> Void {
        /*
         * Create browser (must be done each time photo browser is displayed. Photo
         * browser objects cannot be re-used)
         */
        Reporting.track("select_channel")
        
        let cell = collectionView.cellForItem(at: indexPath) as! ChannelCell
        let channelId = cell.channel.id!
        if channelId != StateController.instance.channelId {
            StateController.instance.setChannelId(channelId: channelId)
            MainController.instance.showChannel(channelId: channelId, animated: true)
        }
        
        if let indexPath = self.collectionView?.indexPathsForSelectedItems?[0] {
            self.collectionView?.deselectItem(at: indexPath, animated: false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView
        , layout collectionViewLayout: UICollectionViewLayout
        , sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.cellWidth!, height: self.cellHeight!)
    }
    
    func collectionView(_ collectionView: UICollectionView
        , layout collectionViewLayout: UICollectionViewLayout
        , insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.sectionInsets!
    }
}

extension ChannelGridController: UISearchBarDelegate {

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.queryController.filterActive = !searchText.isEmpty
        self.queryController.filter(searchText: searchText.isEmpty ? nil : searchText)
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !(searchBar.text?.isEmpty)! {
            self.queryController.filter(searchText: nil)
        }
        searchBar.endEditing(true)
        searchBar.text = nil
        self.searchBar.resignFirstResponder()
        self.queryController.filterActive = false
        searchBar.setShowsCancelButton(false, animated: true)
        self.navigationItem.setLeftBarButton(self.searchButton, animated: true)
        self.navigationItem.setRightBarButtonItems([self.menuButton, UI.spacerFixed, self.addButton], animated: true)
	}
}
