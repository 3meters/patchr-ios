//
//  PatchDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailViewController: QueryResultTableViewController {
    
    @IBOutlet weak var patchImageView: UIImageView!
    @IBOutlet weak var patchNameLabel: UILabel!
    @IBOutlet weak var patchCategoryLabel: UILabel!
    
    var patch: Patch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let query = Query.insertInManagedObjectContext(self.managedObjectContext) as Query
        query.name = "Messages for patch"
        self.managedObjectContext.save(nil)
        self.query = query
        dataStore.loadMoreResultsFor(self.query, completion: { (results, error) -> Void in
            NSLog("Default query fetch for tableview")
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.patchImageView.setImageWithURL(patch.photo?.photoURL())
        self.patchNameLabel.text = patch.name
        self.patchCategoryLabel.text = patch.category?.name
    }

    @IBAction func unwindFromCreateMessage(segue: UIStoryboardSegue) {}
    @IBAction func unwindFromCreatePatch(segue: UIStoryboardSegue) {}
}
