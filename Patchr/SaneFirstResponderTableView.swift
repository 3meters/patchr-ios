//
//  SaneFirstResponderTableView.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-19.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class SaneFirstResponderTableView: UITableView {

    override func scrollRectToVisible(rect: CGRect, animated: Bool) {
        // NSLog("ignoring call to scrollRectToVisible on UITableView")
        // UIScrollView responds strangely when a textfield becomes first responder
        // http://stackoverflow.com/a/12640831/2247399
        return
    }
    
    override func scrollToNearestSelectedRowAtScrollPosition(scrollPosition: UITableViewScrollPosition, animated: Bool) {
        // NSLog("ignoring call to scrollToNearestSelectedRowAtScrollPosition on UITableView")
        return
    }
    
    override func scrollToRowAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UITableViewScrollPosition, animated: Bool) {
        // NSLog("ignoring call to scrollToRowAtIndexPath on UITableView")
        return
    }

}
