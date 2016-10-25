//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseDatabaseUI
import RxSwift

class ChannelPickerController: UIViewController, UITableViewDelegate {

    let db = FIRDatabase.database().reference()
    
    var channelsHeaderView: ChannelsHeaderView!
    var channelsTableView = UITableView(frame: CGRect.zero, style: .plain)
    var channelsTableViewDataSource: FirebaseTableViewDataSource!
    var channelsFooterView = AirLinkButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.channelsHeaderView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 72)
        self.channelsFooterView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.channelsTableView.alignBetweenTop(self.channelsHeaderView, andBottom: self.channelsFooterView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
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
        let controller = PatchPickerController()
        controller.modalPresentationStyle = .overCurrentContext
        if let nav = self.slideMenuController()?.leftViewController as? UINavigationController {
           nav.present(controller, animated: true, completion: nil)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.view.backgroundColor = UIColor.white
        
        self.channelsHeaderView = Bundle.main.loadNibNamed("ChannelsHeaderView", owner: nil, options: nil)?.first as? ChannelsHeaderView
        self.channelsHeaderView.switchButton?.addTarget(self, action: #selector(ChannelPickerController.switchAction(sender:)), for: .touchUpInside)
        
        self.channelsFooterView.setTitle("Add channel", for: .normal)
        self.channelsFooterView.setImage(UIImage(named: "imgAddLight"), for: .normal)
        self.channelsFooterView.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        self.channelsFooterView.imageView?.tintColor = Colors.brandColorDark
        self.channelsFooterView.imageEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 24)
        self.channelsFooterView.contentHorizontalAlignment = .center
        self.channelsFooterView.backgroundColor = Colors.gray95pcntColor
        self.channelsFooterView.addTarget(self, action: #selector(ChannelPickerController.addAction(sender:)), for: .touchUpInside)
        
        self.channelsTableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.channelsTableView.delegate = self
        self.channelsTableView.separatorStyle = .none
        
        _ = UserController.instance.currentPatchId.asObservable().subscribe(onNext: { [unowned self] (groupId: String?) in
            self.bind(groupId: groupId! as String, userId: FIRAuth.auth()!.currentUser!.uid)
        })
        
        self.view.addSubview(self.channelsHeaderView)
        self.view.addSubview(self.channelsTableView)
        self.view.addSubview(self.channelsFooterView)
    }
    
    func bind(groupId: String, userId: String) {
        
        self.channelsHeaderView.observe(groupId: groupId)
        
        self.channelsTableView.dataSource = nil
        self.channelsTableView.reloadData()
        
        let ref = self.db.child("member-channels/\(userId)/\(groupId)")
        
        self.channelsTableViewDataSource = FirebaseTableViewDataSource(ref: ref
            , nibNamed: "ChannelListCell"
            , cellReuseIdentifier: "ChannelViewCell"
            , view: self.channelsTableView)
        
        self.channelsTableViewDataSource.populateCell { (cell, data) in
            
            let snap = data as! FIRDataSnapshot
            let cell = cell as! ChannelListCell
            
            let channelId = snap.key
            let link = snap.value as! [String: Any]
            
            cell.title?.textColor = Theme.colorText
            if channelId == UserController.instance.currentChannelId.value {
                cell.title?.textColor = Colors.accentColorTextLight
            }
            
            let ref = self.db.child("group-channels/\(groupId)/\(channelId)")
            ref.observeSingleEvent(of: .value, with: { snap in
                if let channel = FireChannel(dict: snap.value as! [String: Any], id: snap.key) {
                    channel.membershipFrom(dict: link)
                    cell.bind(channel: channel)
                }
            })
        }
        
        self.channelsTableView.dataSource = self.channelsTableViewDataSource
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelListCell
        UserController.instance.currentChannelId.value = cell.channel.id
        
        /* Switch channels */
        let mainController = PatchDetailViewController()
        mainController.entityId = "pa.150820.00499.464.259239"
        let mainNavController = AirNavigationController(rootViewController: mainController)
        self.slideMenuController()?.changeMainViewController(mainNavController, close: true)
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36
    }
}
