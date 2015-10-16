//
//  NotificationCellTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/14/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
	
	var didSetupConstraints = false
	var entity: Entity?
	var cellType: CellType = .TextAndPhoto
	
	var description_ = UILabel()
	var userPhoto = AirImageView(frame: CGRectZero)
	var photo = AirImageView(frame: CGRectZero)
	var iconImageView = UIImageView(frame: CGRectZero)
	var ageDot = UIView()
	var createdDate = UILabel()
	
	weak var delegate: ViewDelegate?
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		configure()
	}
	
	init(style: UITableViewCellStyle, cellType: CellType?, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		if cellType != nil {
			self.cellType = cellType!
		}
		configure()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		configure()
	}
	
	func configure() {
		
		/* Description */
		if self.cellType != .Photo {
			self.description_.translatesAutoresizingMaskIntoConstraints = false
			self.description_.numberOfLines = 5
			self.description_.lineBreakMode = .ByTruncatingTail
			self.description_.font = UIFont(name: "HelveticaNeue-Light", size: 17)
			self.contentView.addSubview(self.description_)
		}
		
		/* Photo */
		if self.cellType != .Text {
			self.photo.translatesAutoresizingMaskIntoConstraints = false
			self.photo.contentMode = UIViewContentMode.ScaleAspectFill
			self.photo.clipsToBounds = true
			self.photo.userInteractionEnabled = true
			self.contentView.addSubview(self.photo)
			
			let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
			self.photo.addGestureRecognizer(tapGestureRecognizer)
		}
		
		/* User photo */
		self.userPhoto.translatesAutoresizingMaskIntoConstraints = false
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		self.contentView.addSubview(self.userPhoto)
		
		/* Footer */
		self.createdDate.translatesAutoresizingMaskIntoConstraints = false
		self.createdDate.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.createdDate.textColor = Colors.secondaryText
		self.iconImageView.translatesAutoresizingMaskIntoConstraints = false
		self.ageDot.translatesAutoresizingMaskIntoConstraints = false
		self.ageDot.layer.cornerRadius = 6
		
		self.contentView.addSubview(self.iconImageView)
		self.contentView.addSubview(self.createdDate)
		self.contentView.addSubview(self.ageDot)
	}
	
	override func updateConstraints() {
		if !self.didSetupConstraints {
			
			let bottomView = (self.cellType == .Text) ? self.description_ : self.photo
			
			/* Prevent the body from being compressed below its intrinsic content height */
			if self.cellType == .TextAndPhoto {
				self.description_.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 64)
				self.description_.autoPinEdge(.Trailing, toEdge: .Trailing, ofView: self.contentView, withOffset: -8)
				self.description_.autoPinEdge(.Top, toEdge: .Top, ofView: self.contentView, withOffset: 8)
				self.description_.autoPinEdge(.Bottom, toEdge: .Top, ofView: self.photo, withOffset: -8)
				NSLayoutConstraint.autoSetPriority(1000) {
					self.description_.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
				}
				
				self.photo.autoMatchDimension(.Height, toDimension: .Width, ofView: self.photo, withMultiplier: 0.5625)
				
				self.photo.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 64)
				self.photo.autoPinEdge(.Trailing, toEdge: .Trailing, ofView: self.contentView, withOffset: -8)
				self.photo.autoPinEdge(.Top, toEdge: .Bottom, ofView: self.description_, withOffset: 8)
				self.photo.autoPinEdge(.Bottom, toEdge: .Top, ofView: self.iconImageView, withOffset: -8)
				NSLayoutConstraint.autoSetPriority(1000) {
					self.photo.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
				}
			}
				
			if self.cellType == .Photo {
				self.photo.autoMatchDimension(.Height, toDimension: .Width, ofView: self.photo, withMultiplier: 0.5625)
				self.photo.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 64)
				self.photo.autoPinEdge(.Trailing, toEdge: .Trailing, ofView: self.contentView, withOffset: -8)
				self.photo.autoPinEdge(.Top, toEdge: .Bottom, ofView: self.contentView, withOffset: 8)
				self.photo.autoPinEdge(.Bottom, toEdge: .Top, ofView: self.iconImageView, withOffset: -8)
				NSLayoutConstraint.autoSetPriority(1000) {
					self.photo.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
				}
			}
			
			if self.cellType == .Text {
				self.description_.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 64)
				self.description_.autoPinEdge(.Trailing, toEdge: .Trailing, ofView: self.contentView, withOffset: -8)
				self.description_.autoPinEdge(.Top, toEdge: .Top, ofView: self.contentView, withOffset: 8)
				self.description_.autoPinEdge(.Bottom, toEdge: .Top, ofView: self.iconImageView, withOffset: -8)
				NSLayoutConstraint.autoSetPriority(1000) {
					self.description_.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
				}
			}
			
			/* User photo */
			self.userPhoto.autoSetDimensionsToSize(CGSizeMake(48, 48))
			self.userPhoto.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: self.contentView, withOffset: -8, relation: .LessThanOrEqual)
			self.userPhoto.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 8)
			self.userPhoto.autoPinEdge(.Top, toEdge: .Top, ofView: self.contentView, withOffset: 8)
			
			/* Footer */
			self.iconImageView.autoSetDimensionsToSize(CGSizeMake(20, 20))
			self.iconImageView.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 64)
			self.iconImageView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: self.contentView, withOffset: -8)
			self.iconImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: bottomView, withOffset: 8)
			
			self.createdDate.autoSetDimension(.Height, toSize: 18)
			self.createdDate.autoPinEdge(.Leading, toEdge: .Trailing, ofView: self.iconImageView, withOffset: 8)
			self.createdDate.autoAlignAxis(.Horizontal, toSameAxisOfView: self.iconImageView)
			
			self.ageDot.autoSetDimensionsToSize(CGSizeMake(12, 12))
			self.ageDot.autoPinEdge(.Leading, toEdge: .Trailing, ofView: self.createdDate, withOffset: 8)
			self.ageDot.autoAlignAxis(.Horizontal, toSameAxisOfView: self.iconImageView)
			
			self.didSetupConstraints = true
		}
		super.updateConstraints()
	}
	
	override func prepareForReuse() {
		self.description_.text = nil
		self.photo.image = nil
		self.userPhoto.image = nil
		self.createdDate.text = nil
	}
	
	func tapGestureRecognizerAction(sender: AnyObject) {
		if sender.view != nil && self.delegate != nil {
			self.delegate!.view(self, didTapOnView: sender.view!!)
		}
	}
}

enum CellType: String {
	case Text = "text"
	case Photo = "photo"
	case TextAndPhoto = "text_and_photo"
}
