//
//  SettingsTableViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit


class PatchSettingsController: UITableViewController {
    
	var inputSettings	: PatchSettings!
	
    var lockedCell		= AirTableViewCell()
	
    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
	
	override func loadView() {
		super.loadView()
		initialize()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		let viewWidth = min(CONTENT_WIDTH_MAX, self.tableView.bounds.size.width)
		self.tableView.bounds.size.width = viewWidth
	}

	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		Reporting.screen("PatchSettings")
		
		self.navigationItem.title = "Patch settings"
		
		self.tableView = UITableView(frame: self.tableView.frame, style: .grouped)
		self.tableView.rowHeight = 48
		self.tableView.tableFooterView = UIView()
		self.tableView.backgroundColor = Colors.gray95pcntColor
		self.tableView.sectionFooterHeight = 0
		
		self.lockedCell.textLabel?.text = "Only owners can post messages"
		
		self.lockedCell.accessoryView = makeSwitch(settingType: .Locked, state: self.inputSettings.locked)
	}
	
    func toggleAction(sender: AnyObject?) {
        if let switcher = sender as? UISwitch {
            if switcher.tag == SettingType.Locked.rawValue {
				self.inputSettings.locked = switcher.isOn
            }
        }
    }
	
    func makeSwitch(settingType: SettingType, state: Bool = false) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = settingType.rawValue
        switchView.addTarget(self, action: #selector(PatchSettingsController.toggleAction(sender:)), for: UIControlEvents.valueChanged)
        switchView.isOn = state
        return switchView
    }
}

extension PatchSettingsController {
	
	override func numberOfSections(in: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch(section) {
			case 0: return 1
			default: fatalError("Unknown number of sections")
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch(indexPath.section) {
			case 0:
				switch(indexPath.row) {
					case 0: return self.lockedCell
					default: fatalError("Unknown row in section 0")
				}
			default: fatalError("Unknown section")
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch(section) {
			case 0: return "Post Permissions".uppercased()
			default: fatalError("Unknown section")
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 48
	}
}

enum SettingType: Int {
    case Locked
}
