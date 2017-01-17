//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD
import PBWebViewController
import Firebase
import FirebaseAuth

class ManageViewController: UITableViewController {

    var progress: AirProgress?

    /* Section 1: Global settings */
    var manageUsersCell = AirTableViewCell()
    var editGroupCell = AirTableViewCell()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
        }
        bind()
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
    }
    
    func closeAction(sender: AnyObject?){
        if self.presented {
            self.dismiss(animated: true)
        }
        else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.navigationItem.title = "Manage"

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.manageUsersCell.textLabel!.text = "Manage Members"
        self.editGroupCell.textLabel!.text = "Group Settings"
        
        if self.presented {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeAction(sender:)))
            self.navigationItem.rightBarButtonItems = [closeButton]
        }
    }
    
    func bind() { }
}

extension ManageViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)
        
        if selectedCell == self.editGroupCell {
            let controller = GroupEditViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if selectedCell == self.manageUsersCell {
            let controller = MemberListController()
            controller.scope = .group
            controller.manage = true
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { return self.manageUsersCell }
        return self.editGroupCell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
}
