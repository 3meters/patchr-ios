//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {

	var didSetupConstraints = false
	var entity: Entity?
	var cellType: CellType = .TextAndPhoto
	
	var createdDate = UILabel()
	var description_ = UILabel()
	var likes = UILabel()
	var patchName = UILabel()
	var userName = UILabel()
	var photo = AirImageView(frame: CGRectZero)
	var userPhoto = AirImageView(frame: CGRectZero)
	var likeButton = AirLikeButton(frame: CGRectZero)
	var header: OAStackView!
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
		
		self.footer = OAStackView(arrangedSubviews: [self.likeButton, self.likes])
		self.header = OAStackView(arrangedSubviews: [self.userName, self.createdDate])
		
		let components = (self.cellType == .TextAndPhoto)
			? [self.patchName, self.header, self.description_, self.photo, self.footer]
			: (self.cellType == .Text)
			? [self.patchName, self.header, self.description_, self.footer]
			: [self.patchName, self.header, self.photo, self.footer]
		
		self.body = OAStackView(arrangedSubviews: components)
		
		self.header.translatesAutoresizingMaskIntoConstraints = false
		self.header.axis = UILayoutConstraintAxis.Horizontal
		self.header.alignment = OAStackViewAlignment.Center
		self.header.distribution = OAStackViewDistribution.Fill
		self.header.spacing = CGFloat(8)
		
		self.footer.translatesAutoresizingMaskIntoConstraints = false
		self.footer.axis = UILayoutConstraintAxis.Horizontal
		self.footer.alignment = OAStackViewAlignment.Center
		self.footer.spacing = CGFloat(8)
		
		self.body.translatesAutoresizingMaskIntoConstraints = false
		self.body.axis = UILayoutConstraintAxis.Vertical
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
		
		/* Patch name */
		self.patchName.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.patchName.textColor = Colors.secondaryText
		
		/* User photo */
		self.userPhoto.contentMode = UIViewContentMode.ScaleAspectFill
		self.userPhoto.clipsToBounds = true
		self.userPhoto.layer.cornerRadius = 24
		
		/* Header */
		self.userName.numberOfLines = 1
		self.userName.lineBreakMode = .ByTruncatingMiddle
		self.userName.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
		self.createdDate.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.createdDate.textColor = Colors.secondaryText
		
		/* Footer */
		self.likeButton.imageView!.tintColor(Colors.brandColor)
		self.likes.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		self.likes.textColor = Colors.brandColor
		
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
				self.body.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 8, left: 64, bottom: 8, right: 8)/*, excludingEdge: .Bottom*/)
			}
			
			NSLayoutConstraint.autoSetPriority(1000) {
				self.likeButton.autoSetDimensionsToSize(CGSizeMake(24, 20))
			}
			
			/* User photo */
			NSLayoutConstraint.autoSetPriority(1000) {
				self.userPhoto.autoSetDimensionsToSize(CGSizeMake(48, 48))
			}
			self.userPhoto.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: self.contentView, withOffset: -8, relation: .LessThanOrEqual)
			self.userPhoto.autoPinEdge(.Leading, toEdge: .Leading, ofView: self.contentView, withOffset: 8)
			self.userPhoto.autoPinEdge(.Top, toEdge: .Top, ofView: self.contentView, withOffset: 8)
			
			/* Footer */
			
			self.didSetupConstraints = true
		}
		super.updateConstraints()
	}
	
	override func prepareForReuse() {
		self.patchName.text = nil
		self.userPhoto.image = nil
		self.userName.text = nil
		self.createdDate.text = nil
		self.description_.text = nil
		self.photo.image = nil
		self.likes.text = nil
	}
	
	func tapGestureRecognizerAction(sender: AnyObject) {
		if sender.view != nil && self.delegate != nil {
			self.delegate!.view(self, didTapOnView: sender.view!!)
		}
	}
}
