//
//  MessageTableViewCell.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-12.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class MessageView: BaseView {
    
    var entity: Entity?
    
	@IBOutlet weak var createdDate:			UILabel!
	@IBOutlet weak var description_:		UILabel!
	@IBOutlet weak var likes:				UILabel!
    @IBOutlet weak var patchName:			UILabel!
    @IBOutlet weak var userName:			UILabel!
	@IBOutlet weak var photo:				AirImageView!
	@IBOutlet weak var userPhoto:			AirImageView!
	@IBOutlet weak var likeButton:			AirLikeButton!
    @IBOutlet weak var toolbar:				UIView!
	
	@IBOutlet weak var descriptionHeight:   NSLayoutConstraint!
	@IBOutlet weak var patchNameHeight:		NSLayoutConstraint!
	@IBOutlet weak var photoHeight:			NSLayoutConstraint!
	@IBOutlet weak var photoTopSpace:		NSLayoutConstraint!
	@IBOutlet weak var toolbarHeight:		NSLayoutConstraint!
	
    weak var delegate: ViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
        self.photo.addGestureRecognizer(tap)
    }
    
    func tapGestureRecognizerAction(sender: AnyObject) {
        if sender.view != nil && self.delegate != nil {
            self.delegate!.view(self, didTapOnView: sender.view!!)
        }
    }
}
