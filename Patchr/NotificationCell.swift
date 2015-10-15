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
	var footer: OAStackView!
	var body: OAStackView!	
	
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
		
		self.footer = OAStackView(arrangedSubviews: [self.iconImageView, self.createdDate, self.ageDot])
		
		let components = (self.cellType == .TextAndPhoto)
			? [self.description_, self.photo, footer]
			: (self.cellType == .Text)
			? [self.description_, footer]
			: [self.photo, footer]
		
		self.body = OAStackView(arrangedSubviews: components)
		
		self.footer.translatesAutoresizingMaskIntoConstraints = false
		self.footer.axis = UILayoutConstraintAxis.Horizontal
		self.footer.alignment = OAStackViewAlignment.Leading
		self.footer.spacing = CGFloat(8)
		
		self.body.translatesAutoresizingMaskIntoConstraints = false
		self.body.axis = UILayoutConstraintAxis.Vertical
		self.body.alignment = OAStackViewAlignment.Fill
		self.body.spacing = CGFloat(8)
		
		/* Description */
		if self.cellType != .Photo {
			self.description_.numberOfLines = 5
			self.description_.lineBreakMode = .ByTruncatingTail
			self.description_.font = UIFont(name: "HelveticaNeue-Light", size: 17)
		}
		
		/* Photo */
		if self.cellType != .Text {
			self.photo.contentMode = UIViewContentMode.ScaleAspectFill
			self.photo.clipsToBounds = true
			self.photo.userInteractionEnabled = true
			let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecognizerAction:")
			self.photo.addGestureRecognizer(tapGestureRecognizer)
		}
		
		/* User photo */
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		
		/* Footer */
		self.ageDot.layer.cornerRadius = 6
		self.createdDate.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.createdDate.textColor = UIColor.darkGrayColor()
		
		/* Assemble */
		self.contentView.addSubview(self.userPhoto)
		self.contentView.addSubview(self.body)
	}
	
	override func updateConstraints() {
		if !self.didSetupConstraints {
			
			/* Prevent the body from being compressed below its intrinsic content height */
			if self.cellType != .Photo {
				NSLayoutConstraint.autoSetPriority(1000) {
					self.description_.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
				}
			}
			
			if self.cellType != .Text {
				NSLayoutConstraint.autoSetPriority(1000) {
					self.photo.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
					self.photo.autoMatchDimension(.Height, toDimension: .Width, ofView: self.photo, withMultiplier: 0.5625)
				}
			}
			
			/* Body */
			NSLayoutConstraint.autoSetPriority(1000) {
				self.body.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
			}
			self.body.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 8, left: 64, bottom: 8, right: 8), excludingEdge: .Bottom)
			
			/* User photo */
			NSLayoutConstraint.autoSetPriority(999) {
				self.userPhoto.autoSetDimensionsToSize(CGSizeMake(48, 48))
			}
			self.userPhoto.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: self.contentView, withOffset: -8, relation: .LessThanOrEqual)
			self.userPhoto.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 8)
			self.userPhoto.autoPinEdge(.Top, toEdge: .Top, ofView: self.contentView, withOffset: 8)
			
			/* Footer */
			self.iconImageView.autoSetDimensionsToSize(CGSizeMake(20, 20))
			self.ageDot.autoSetDimensionsToSize(CGSizeMake(12, 12))
			
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
