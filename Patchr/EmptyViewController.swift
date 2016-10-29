//
//  BaseViewController.swift
//  Patchr
//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class EmptyViewController: BaseViewController {
		
	/*--------------------------------------------------------------------------------------------
	* MARK: - Lifecycle
	*--------------------------------------------------------------------------------------------*/
    
    override func loadView() {
        super.loadView()
        initialize()
        self.emptyLabel.alpha = 1.0
    }
}
