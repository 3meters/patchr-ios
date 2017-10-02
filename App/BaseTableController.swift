//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import FirebaseDatabaseUI
import FirebaseAuth

class BaseTableController: UIViewController {
    
    var authHandle: AuthStateDidChangeListenerHandle!
    var tableView = UITableView(frame: CGRect.zero, style: .plain)
    var queryController: DataSourceController!
    
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func viewWillLayoutSubviews() {
        let viewWidth = min(Config.contentWidthMax, self.view.width())
        self.view.anchorTopCenter(withTopPadding: 0, width: viewWidth, height: self.view.height())
    }
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
        self.authHandle = Auth.auth().addStateDidChangeListener() { [weak self] auth, user in
            guard let this = self else { return }
            if user == nil && this.queryController != nil {
                this.queryController.unbind()
            }
        }
        self.view.backgroundColor = Theme.colorBackgroundForm
	}
}
