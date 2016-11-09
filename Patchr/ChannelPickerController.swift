//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabaseUI
import RxSwift
import SlideMenuControllerSwift
import pop

class ChannelPickerController: UIViewController, UITableViewDelegate, SlideMenuControllerDelegate, UINavigationControllerDelegate {

    let db = FIRDatabase.database().reference()
    var groupRef: FIRDatabaseReference!
    var groupHandle: UInt!
    var channelsQuery: FIRDatabaseQuery!
    var group: FireGroup!
    
    var headerView: ChannelsHeaderView!
    var tableView = AirTableView(frame: CGRect.zero, style: .plain)
    var tableViewDataSource: FUITableViewDataSource!
    var cellReuseIdentifier: String!
    var footerView = AirLinkButton()
    var hasFavorites = false
    let navigationAnimator = SlideAnimationController()
    var groupPickerController = GroupPickerController()

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
        self.headerView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 72)
        self.footerView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.tableView.alignBetweenTop(self.headerView, andBottom: self.footerView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func addAction(sender: AnyObject?) {
        let controller = PatchEditViewController()
        let navController = AirNavigationController()
        controller.inputState = .Creating
        controller.inputType = "group"
        navController.viewControllers = [controller]
        self.present(navController, animated: true, completion: nil)
    }
    
    func switchAction(sender: AnyObject?) {
        self.navigationController!.pushViewController(self.groupPickerController, animated: true)
    }
    
    func leftDidClose() {
        let _ = self.navigationController?.popToRootViewController(animated: false)
    }
    
    func navigationController(_ navigationController: UINavigationController,
                    animationControllerFor operation: UINavigationControllerOperation,
                                         from fromVC: UIViewController,
                                             to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.navigationAnimator.reverse = (operation == .pop)
        return self.navigationAnimator
    }
    
    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    func groupDidChange(notification: NSNotification?) {
        bind()
        if (self.slideMenuController()?.isLeftOpen())! && StateController.instance.channelId != nil {
            self.slideMenuController()?.closeLeft()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.definesPresentationContext = true
        self.navigationController?.delegate = self
        self.view.backgroundColor = UIColor.white
        
        self.slideMenuController()?.delegate = self
        
        self.headerView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.headerView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        
        self.footerView.setImage(UIImage(named: "imgAddCircleLight"), for: .normal)
        self.footerView.imageView!.contentMode = .scaleAspectFit
        self.footerView.imageView?.tintColor = Colors.brandOnLight
        self.footerView.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        self.footerView.contentHorizontalAlignment = .center
        self.footerView.backgroundColor = Colors.gray95pcntColor
        self.footerView.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        
        self.cellReuseIdentifier = "channel-cell"
        self.tableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.register(UINib(nibName: "ChannelListCell", bundle: nil), forCellReuseIdentifier: self.cellReuseIdentifier)
        
        self.view.addSubview(self.headerView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(groupDidChange(notification:)), name: NSNotification.Name(rawValue: Events.GroupDidChange), object: nil)
    }
    
    func bind() {
        
        let groupId = StateController.instance.groupId
        let userId = UserController.instance.userId
        
        if userId != nil && groupId != nil {
            
            self.groupRef = self.db.child("groups/\(groupId!)")
            self.channelsQuery = self.db.child("member-channels/\(userId!)/\(groupId!)").queryOrdered(byChild: "sort_priority")
            
            self.groupHandle = self.groupRef.observe(.value, with: { snap in
                if !(snap.value is NSNull) {
                    self.group = FireGroup.from(dict: snap.value as? [String: Any], id: snap.key)
                    self.bindChannels()
                }
            })
        }
        else {
            self.tableView.dataSource = nil
            self.tableView.reloadData()
        }
    }
    
    func bindChannels() {
        
        let groupId = StateController.instance.groupId
        
        self.headerView.bind(patch: self.group)
        
        self.tableView.dataSource = nil
        self.tableView.reloadData()
        
        self.tableViewDataSource = ChannelsDataSource(
            query: self.channelsQuery,
            view: self.tableView,
            populateCell: { [weak self] (view, indexPath, snap) -> ChannelListCell in
            
            let cell = view.dequeueReusableCell(withIdentifier: (self?.cellReuseIdentifier)!, for: indexPath) as! ChannelListCell
            let channelId = snap.key
            let link = snap.value as! [String: Any]
            
            cell.backgroundColor = Colors.white
            cell.title?.textColor = Theme.colorText
            cell.lock?.tintColor = Colors.brandColorLight
            cell.star?.tintColor = Colors.brandColorLight
            if channelId == StateController.instance.channelId {
                cell.backgroundColor = Colors.accentColorFill
                cell.title?.textColor = Colors.white
                cell.lock?.tintColor = Colors.white
                cell.star?.tintColor = Colors.white
            }
                
            let path = "group-channels/\(groupId!)/\(channelId)"
            if let ref = self?.db.child(path) {
                ref.observeSingleEvent(of: .value, with: { snap in
                    if !(snap.value is NSNull) {
                        if let channel = FireChannel.from(dict: snap.value as? [String: Any], id: snap.key) {
                            channel.membershipFrom(dict: link)
                            cell.bind(channel: channel)
                        }
                    }
                })
            }
                
                return cell
        })
        
        self.tableView.dataSource = self.tableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        StateController.instance.setChannelId(channelId: cell.channel.id)
        self.slideMenuController()?.closeLeft()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36
    }
    
    class SlideAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
        
        var reverse: Bool = false
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 2.0
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            
            let containerView = transitionContext.containerView
            let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
            let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
            let toView = toViewController.view
            let fromView = fromViewController.view
            
            if !reverse {
                toView?.frame = CGRect(x: 0, y: 0, width: containerView.width(), height: containerView.height())
                toView?.center = containerView.center
                toView?.center.y = containerView.center.y + containerView.height()
                
                containerView.addSubview(toView!)
                containerView.sendSubview(toBack: fromView!)
                
                let spring = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
                spring?.toValue = containerView.center.y
                spring?.springBounciness = 10
                spring?.springSpeed = 8
                spring?.completionBlock = { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }                
                toView?.layer.pop_add(spring, forKey: "positionAnimation")
            }
            else {
                fromView?.frame = CGRect(x: 0, y: 0, width: containerView.width(), height: containerView.height())
                fromView?.center = containerView.center
                fromView?.center.y = containerView.center.y
                
                containerView.addSubview(toView!)
                containerView.sendSubview(toBack: toView!)
                
                let spring = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
                spring?.toValue = containerView.center.y + containerView.height()
                spring?.springBounciness = 10
                spring?.springSpeed = 8
                spring?.completionBlock = { finished in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
                fromView?.layer.pop_add(spring, forKey: "positionAnimation")
            }
        }
    }
}

extension ChannelPickerController {
    /* 
     * UITableViewDataSource 
     */
    class ChannelsDataSource: FUITableViewDataSource {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "Channels"
        }
    }
}
