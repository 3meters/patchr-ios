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
import VTAcknowledgementsViewController

class AboutViewController: UITableViewController {

    /* Section 1: Informational */
    var termsOfServiceCell = AirTableViewCell()
    var privacyPolicyCell = AirTableViewCell()
    var softwareLicensesCell = AirTableViewCell()

    /* Section 2: About */
    var buildInfoCell = AirTableViewCell()
    var buildInfoLabel = AirLabelDisplay()
    
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
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let viewWidth = min(Config.contentWidthMax, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
        self.buildInfoLabel.fillSuperview()
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.navigationItem.title = "about".localized()

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.rowHeight = 48
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0

        self.buildInfoCell.contentView.addSubview(self.buildInfoLabel)
        self.buildInfoCell.accessoryType = .none

        let components = NSCalendar.current.dateComponents([.year, .month, .day], from: Date())
        self.buildInfoLabel.text = "©\(components.year!) 3meters LLC\n\("version".localized()) \(appVersion()) (\(build()))"
        self.buildInfoLabel.textColor = Theme.colorTextTitle
        self.buildInfoLabel.font = Theme.fontTextDisplay
        self.buildInfoLabel.numberOfLines = 2
        self.buildInfoLabel.textAlignment = .center
        self.buildInfoCell.isUserInteractionEnabled = false

        self.termsOfServiceCell.textLabel!.text = "terms_of_service".localized()
        self.privacyPolicyCell.textLabel!.text = "privacy_policy".localized()
        self.softwareLicensesCell.textLabel!.text = "acknowledgements".localized()
    }
    
    func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    func build() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "Unknown"
    }

    func pushWebViewController(url: URL?) -> Void {
        let webViewController = PBWebViewController()
        webViewController.url = url
        webViewController.showsNavigationToolbar = false
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
}

extension AboutViewController {
    /*
    * UITableViewDelegate
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedCell = tableView.cellForRow(at: indexPath)
        
        if selectedCell == self.termsOfServiceCell {
            Reporting.track("view_terms_of_service")
            let termsURLString = "http://patchr.com/terms"
            self.pushWebViewController(url: NSURL(string: termsURLString) as URL?)
        }
            
        if selectedCell == self.privacyPolicyCell {
            Reporting.track("view_privacy_policy")
            let privacyPolicyURLString = "http://patchr.com/privacy"
            self.pushWebViewController(url: NSURL(string: privacyPolicyURLString) as URL?)
        }
            
        if selectedCell == self.softwareLicensesCell {
            Reporting.track("view_software_licenses")
            let controller = VTAcknowledgementsViewController.acknowledgementsViewController()
            controller?.headerText = "licensing_comment".localized()
            controller?.navigationItem.title = "licensing_title".localized()
            self.navigationController?.pushViewController(controller!, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            return CGFloat(64)
        }
        
        return CGFloat(44)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0: return self.termsOfServiceCell
                    case 1: return self.privacyPolicyCell
                    case 2: return self.softwareLicensesCell
                    default: fatalError("Unknown row in section 3")
                }
            case 1:
                switch (indexPath.row) {
                    case 0: return self.buildInfoCell
                    default: fatalError("Unknown row in section 5")
                }
            default: fatalError("Unknown section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return 3
            case 1: return 1
            default: fatalError("Unknown number of sections")
        }
    }
}
