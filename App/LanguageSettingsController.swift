//
//  NotificationSettingsViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import MBProgressHUD
import Localize_Swift

class LanguageSettingsController: UITableViewController {
    
    var enCell = AirTableViewCell(style: .subtitle, reuseIdentifier: nil)
    var ruCell = AirTableViewCell(style: .subtitle, reuseIdentifier: nil)
    
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    override func loadView() {
        super.loadView()
        initialize()
        bindLanguage()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth = min(Config.contentWidthMax, self.tableView.bounds.size.width)
        self.tableView.bounds.size.width = viewWidth
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
    
    func closeAction(sender: AnyObject?) {
        close(animated: true)
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 48
        self.tableView.backgroundColor = Colors.gray95pcntColor
        self.tableView.sectionFooterHeight = 0
        
        self.enCell.accessoryType = .none
        self.enCell.data = "en" as AnyObject?
        self.enCell.textLabel?.text = Language.iso["en"]?["nativeName"]
        self.enCell.detailTextLabel?.text = Language.iso["en"]?["name"]
        self.ruCell.data = "ru" as AnyObject?
        self.ruCell.accessoryType = .none
        self.ruCell.textLabel?.text = Language.iso["ru"]?["nativeName"]
        self.ruCell.detailTextLabel?.text = Language.iso["ru"]?["name"]
        
        self.enCell.selectionStyle = .none
        self.ruCell.selectionStyle = .none
        
        let langCode = Localize.currentLanguage()
        if langCode == "ru" {
            self.ruCell.accessoryType = .checkmark
        }
        else {
            self.enCell.accessoryType = .checkmark
        }
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
        self.navigationItem.leftBarButtonItems = [closeButton]
        
        NotificationCenter.default.addObserver(self, selector: #selector(bindLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)        
        bindLanguage()
    }
    
    func bindLanguage() {
        self.navigationItem.title = "language_settings_title".localized()
        self.tableView.reloadData()
    }
}

extension LanguageSettingsController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let selectedCell = tableView.cellForRow(at: indexPath) as! AirTableViewCell
            if let langCode = selectedCell.data as? String {
                Localize.setCurrentLanguage(langCode)
            }
            self.enCell.accessoryType = .none
            self.ruCell.accessoryType = .none
            selectedCell.accessoryType = .checkmark
        }
    }

    override func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 1 { return self.ruCell }
        return self.enCell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "language_settings_section_title".localized().uppercased()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
}
