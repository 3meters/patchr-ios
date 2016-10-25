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

class GroupPickerController: UIViewController, UITableViewDelegate {

    var groupsHeaderView: PatchesHeaderView!
    var groupsTableView = UITableView(frame: CGRect.zero, style: .plain)
    var groupsTableViewDataSource: FirebaseTableViewDataSource!
    var groupsFooterView = AirLinkButton()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.groupsHeaderView.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: 72)
        self.groupsFooterView.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.groupsTableView.alignBetweenTop(self.groupsHeaderView, andBottom: self.groupsFooterView, centeredWithLeftAndRightPadding: 0, topAndBottomPadding: 0)
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
    
    func closeAction(sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }

    /*--------------------------------------------------------------------------------------------
    * Notifications
    *--------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    func initialize() {
        
        self.view.backgroundColor = UIColor.clear
        self.view.isOpaque = false
        
        self.groupsHeaderView = Bundle.main.loadNibNamed("PatchesHeaderView", owner: nil, options: nil)?.first as? PatchesHeaderView
        self.groupsHeaderView.closeButton?.addTarget(self, action: #selector(GroupPickerController.closeAction(sender:)), for: .touchUpInside)
        
        self.groupsFooterView.setTitle("Create group", for: .normal)
        self.groupsFooterView.setImage(UIImage(named: "imgAddLight"), for: .normal)
        self.groupsFooterView.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        self.groupsFooterView.imageView?.tintColor = Colors.brandColorDark
        self.groupsFooterView.imageEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 24)
        self.groupsFooterView.contentHorizontalAlignment = .center
        self.groupsFooterView.backgroundColor = Colors.gray95pcntColor
        self.groupsFooterView.addTarget(self, action: #selector(GroupPickerController.addAction(sender:)), for: .touchUpInside)
        
        self.groupsTableView.backgroundColor = Theme.colorBackgroundEmptyBubble
        self.groupsTableView.delegate = self
        
        self.view.addSubview(self.groupsHeaderView)
        self.view.addSubview(self.groupsTableView)
        self.view.addSubview(self.groupsFooterView)
    }
    
    func bind() {
        
        let userId = FIRAuth.auth()?.currentUser?.uid
        let db = FIRDatabase.database().reference()
        let ref = db.child("member-groups/\(userId!)")
        self.groupsTableViewDataSource = FirebaseTableViewDataSource(ref: ref, nibNamed: "PatchListCell", cellReuseIdentifier: "PatchViewCell", view: self.groupsTableView)
        self.groupsTableView.dataSource = self.groupsTableViewDataSource
        
        self.groupsTableViewDataSource.populateCell { (cell, data) in
            
            let snap = data as! FIRDataSnapshot
            let cell = cell as! PatchListCell
            
            let groupId = snap.key
            let link = snap.value as! [String: Any]
            
            cell.title?.textColor = Theme.colorText
            if groupId == UserController.instance.currentPatchId.value {
                cell.title?.textColor = Colors.accentColorTextLight
            }
            
            db.child("groups/\(groupId)").observeSingleEvent(of: .value, with: { snap in
                if let group = FireGroup(dict: snap.value as! [String: Any], id: snap.key) {
                    group.membershipFrom(dict: link)
                    cell.bind(patch: group)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! PatchListCell
        UserController.instance.currentPatchId.value = cell.patch.id
        self.slideMenuController()?.closeLeft()
        self.closeAction(sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}