//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import FirebaseAuth
import Localize_Swift
import pop

class ChannelGridController: UICollectionViewController {
    
    var authHandle: AuthStateDidChangeListenerHandle!
    var queryController: DataSourceController!
	var totalUnreadsQuery: UnreadQuery?
    var searchController = UISearchController(searchResultsController: nil)
    var titles: [String: String] = [:]

	var searchBar: UISearchBar!
    var searchBarActive = false
    var searchBarHeight = 44
    
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
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(self.collectionView!, delay: 50.0)
        }
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    deinit {
        Log.v("ChannelGridController released")
        unbind()
    }

	/*--------------------------------------------------------------------------------------------
	* MARK: - Events
	*--------------------------------------------------------------------------------------------*/

	@objc func addAction(sender: AnyObject?) {

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

	@objc func searchAction(sender: AnyObject?) {
        self.searchBarActive = true
        self.collectionView?.collectionViewLayout.invalidateLayout()
        self.searchBar.fadeIn()
        self.searchBar.becomeFirstResponder()
	}

    @objc func showActions(sender: AnyObject?) {
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
    
	/*--------------------------------------------------------------------------------------------
	* MARK: - Notifications
	*--------------------------------------------------------------------------------------------*/

	@objc func userDidSwitch(notification: NSNotification?) {
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
                this.queryController?.unbind()
            }
        }
        
        self.view.backgroundColor = Theme.colorBackgroundForm
        self.definesPresentationContext = true
        
        /* Search bar when toggled on */
        var fieldBackgroundImage = ImageUtils.imageFromColor(color: Colors.gray97pcntColor, width: 32, height: 32)
        fieldBackgroundImage = fieldBackgroundImage.roundedCornerImage(cornerRadius: 6, borderSize: 0)
        self.searchBar = UISearchBar(frame: CGRect.zero)
		self.searchBar.autocapitalizationType = .none
        self.searchBar.backgroundColor = Colors.gray90pcntColor
        self.searchBar.searchTextPositionAdjustment = UIOffsetMake(8, 0)
        self.searchBar.setSearchFieldBackgroundImage(fieldBackgroundImage, for: .normal)
		self.searchBar.delegate = self
		self.searchBar.searchBarStyle = .minimal
        self.searchBar.barStyle = .default
        self.searchBar.showsCancelButton = true
        self.searchBar.alpha = 0

        self.view.addSubview(self.searchBar!)
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.backgroundColor = Theme.colorBackgroundForm
        self.collectionView?.delaysContentTouches = false
        self.collectionView!.register(ChannelGridCell.self, forCellWithReuseIdentifier: "cell")
        
        /* Buttons (*/
		self.searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchAction(sender:)))
        self.addButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(addAction(sender:)))
        
        /* New channel button */
        var button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(#imageLiteral(resourceName: "imgChannelAdd"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
        self.addButton = UIBarButtonItem(customView: button)
        
        /* Menu button */
        button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.addTarget(self, action: #selector(showActions(sender:)), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        button.setImage(UIImage(named: "imgOverflowVerticalLight"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 0)
        self.menuButton = UIBarButtonItem(customView: button)
        
        bindLanguage()

		self.navigationItem.leftBarButtonItem = self.searchButton
        self.navigationItem.setRightBarButtonItems([self.menuButton, UI.spacerFixed, self.addButton], animated: true)
        
		NotificationCenter.default.addObserver(self, selector: #selector(userDidSwitch(notification:)), name: NSNotification.Name(rawValue: Events.UserDidSwitch), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        
        self.searchBar.translatesAutoresizingMaskIntoConstraints = false
        self.searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        self.searchBar.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.searchBar.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
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
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChannelGridCell
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
                        cell.bind(channel: channel!)
                        cell.unreadQuery = UnreadQuery(level: .channel, userId: userId, channelId: channelId)
                        cell.unreadQuery!.observe(with: { [weak cell] error, total in
                            guard let cell = cell else { return }
                            if total != nil && total! > 0 {
                                cell.badge.text = "\(total!)"
                                cell.badgeIsHidden = false
                            }
                            else {
                                cell.badgeIsHidden = true
                            }
                        })
                    })
                    
                }
                return cell
            }
			self.view.setNeedsLayout()
		}
	}
    
    @objc func bindLanguage() {
        self.searchBar.placeholder = "channel_grid_search_bar_placeholder".localized()
        self.searchBar.setValue("cancel".localized(), forKey: "_cancelButtonText")
        self.navigationItem.title = "channel_grid_title".localized()
    }
    
    func unbind() {
        if self.queryController != nil {
            self.queryController.unbind()
        }
        self.totalUnreadsQuery?.remove()
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
        return true
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

extension ChannelGridController { // UICollectionViewDelegate
    
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
        
        let cell = collectionView.cellForItem(at: indexPath) as! ChannelGridCell
        if let channelId = cell.channel?.id {
            if channelId != StateController.instance.channelId {
                StateController.instance.setChannelId(channelId: channelId)
                MainController.instance.showChannel(channelId: channelId, animated: true)
            }
        }
        
        if let indexPath = self.collectionView?.indexPathsForSelectedItems?[0] {
            self.collectionView?.deselectItem(at: indexPath, animated: false)
        }
    }
}

extension ChannelGridController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView
        , layout collectionViewLayout: UICollectionViewLayout
        , sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let availableWidth = collectionView.width() - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        let preferredColumnWidth: CGFloat = (UIDevice.current.userInterfaceIdiom == .phone) ? 100 : 150
        let numColumns: CGFloat = floor(CGFloat(availableWidth) / CGFloat(preferredColumnWidth))
        let spaceLeftOver = availableWidth - (numColumns * preferredColumnWidth) - ((numColumns - 1) * flowLayout.minimumInteritemSpacing)
        let cellWidth = preferredColumnWidth + (spaceLeftOver / numColumns)
        let cellHeight = (cellWidth * 0.65) + 32
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView
        , layout collectionViewLayout: UICollectionViewLayout
        , insetForSectionAt section: Int) -> UIEdgeInsets {
        let top = CGFloat(self.searchBarActive ? self.searchBarHeight + 8 : 8)
        return UIEdgeInsetsMake(top, 8, 8, 8)
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
        self.searchBar.endEditing(true)
        self.searchBar.text = nil
        self.searchBar.resignFirstResponder()
        self.queryController.filterActive = false
        self.searchBar.fadeOut()
        self.searchBarActive = false
        self.collectionView?.collectionViewLayout.invalidateLayout()
	}
}
