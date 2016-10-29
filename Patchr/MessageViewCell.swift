//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage

class MessageViewCell: UIView {
    
    var message: FireMessage!
	
	var description_	: UILabel?
	var photo			: AirImageView?
	var userName		= AirLabelDisplay()
	var userPhoto		= PhotoView()
	var createdDate		= AirLabelDisplay()
	
	var toolbar			= UIView()
	var likeButton		= AirLikeButton(frame: CGRect.zero)
	var likes			= AirLabelDisplay()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	/*--------------------------------------------------------------------------------------------
	* Events
	*--------------------------------------------------------------------------------------------*/
	
	override func layoutSubviews() {
		super.layoutSubviews()
		/*
		* Triggers:
		* - foo.addSubview(bar) triggers layoutSubviews on foo, bar and all subviews of foo
		* - Bounds (not frame) change for foo or foo.subviews (frame.size is propogated to bounds.size)
		* - foo.addSubview does not trigger layoutSubviews if foo.autoresize mask == false
		* - foo.setNeedsLayout is called
		*
		* Note: above triggers set dirty flag using setNeedsLayout which gets
		* checked for all views in the view hierarchy for every run loop iteration.
		* If dirty, layoutSubviews is called in hierarchy order and flag is reset.
		*/
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = self.bounds.size.width - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
		self.userPhoto.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 48, height: 48)
		
		/* Header */
        
		self.createdDate.sizeToFit()
		self.userName.sizeToFit()
		self.userName.align(toTheRightOf: self.userPhoto, matchingTopWithLeftPadding: 8, width: columnWidth - (self.createdDate.width() + 8), height: self.userName.height())
		self.createdDate.align(toTheRightOf: self.userName, matchingCenterAndFillingWidthWithLeftAndRightPadding: 0, height: self.createdDate.height())
		
		/* Body */
		
		var bottomView: UIView? = self.photo
		if self.message.attachments == nil {
			bottomView = self.description_
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: self.description_!.height())
		}
		
		if self.message.text != nil && self.message.attachments != nil {
			self.description_?.bounds.size.width = columnWidth
			self.description_?.sizeToFit()
			self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: self.description_!.height())
			self.photo?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		else if (self.message.attachments?.first) != nil {
            self.photo?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 8, height: photoHeight)
		}
		
		/* Footer */
		
        self.toolbar.alignUnder(bottomView!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: 48)
        self.likeButton.anchorCenterLeft(withLeftPadding: 0, width: self.likeButton.width(), height: self.likeButton.height())
        self.likeButton.frame.origin.x -= 12
        self.likes.sizeToFit()
        self.likes.align(toTheRightOf: self.likeButton, matchingCenterWithLeftPadding: 0, width: self.likes.width(), height: self.likes.height())
        self.likes.frame.origin.x -= 4
	}

	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		/*
		 * The calls to addSubview will trigger a call to layoutSubviews for
		 * the current update cycle.
		 */
		
		/* Description */
		self.description_ = TTTAttributedLabel(frame: CGRect.zero)
		self.description_!.numberOfLines = 0
		self.description_!.font = Theme.fontTextList
		
		if self.description_ != nil && !(self.description_ is TTTAttributedLabel) {
			let linkColor = Theme.colorTint
			let linkActiveColor = Theme.colorTint
			let label = self.description_ as! TTTAttributedLabel
			label.linkAttributes = [kCTForegroundColorAttributeName as AnyHashable : linkColor]
			label.activeLinkAttributes = [kCTForegroundColorAttributeName as AnyHashable : linkActiveColor]
			label.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue|NSTextCheckingResult.CheckingType.address.rawValue
		}
		
		/* Photo: give initial size in case the image displays before call to layoutSubviews		 */
		let columnLeft = CGFloat(48 + 8)
		let columnWidth = min(CONTENT_WIDTH_MAX, UIScreen.main.bounds.size.width) - columnLeft
		let photoHeight = columnWidth * 0.5625		// 16:9 aspect ratio
		
        self.photo = AirImageView(frame: CGRect(x:0, y:0, width:columnWidth, height:photoHeight))
		self.photo!.clipsToBounds = true
		self.photo!.contentMode = .scaleAspectFill
		self.photo!.backgroundColor = Theme.colorBackgroundImage
		
		/* Header */
		self.userName.font = Theme.fontTextBold
		self.userName.numberOfLines = 1
		self.userName.lineBreakMode = .byTruncatingMiddle
		
		self.createdDate.font = Theme.fontComment
		self.createdDate.numberOfLines = 1
		self.createdDate.textColor = Theme.colorTextSecondary
		self.createdDate.textAlignment = .right
		
		/* Footer */
		
		self.likeButton.imageView!.tintColor = Theme.colorTint
        self.likeButton.bounds.size = CGSize(width:48, height:48)
		self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(14, 12, 14, 12)

		self.likes.font = Theme.fontText
		self.likes.numberOfLines = 1
		self.likes.textColor = Theme.colorText
		self.likes.textAlignment = .right
		
		self.toolbar.addSubview(self.likeButton)
		self.toolbar.addSubview(self.likes)
        
		self.addSubview(self.toolbar)
        self.addSubview(self.description_!)
        self.addSubview(self.photo!)
        self.addSubview(self.userPhoto)
        self.addSubview(self.userName)
        self.addSubview(self.createdDate)
	}
	
    func bind(message: FireMessage) {
        
		self.message = message
		
		self.description_?.isHidden = true
		self.photo?.isHidden = true
		self.toolbar.isHidden = true
		
		if let description = message.text {
			self.description_?.isHidden = false
			self.description_?.text = description
		}
		
		if let photo = message.attachments?.first?.photo {
			self.photo?.isHidden = false
            if let photoUrl = PhotoUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                bindPhoto(photoUrl: photoUrl)
            }
		}
        
        self.userName.text = message.creator?.username
        let fullName = message.creator?.profile?.fullName
        let photoUrl = PhotoUtils.url(prefix: message.creator?.profile?.photo?.filename, source: message.creator?.profile?.photo?.source, category: SizeCategory.profile)
        self.userPhoto.bindPhoto(photoUrl: photoUrl, name: fullName)
		
        self.createdDate.text = UIShared.timeAgoShort(date: NSDate(timeIntervalSince1970: Double(message.createdAt!) / 1000))
			
        self.toolbar.isHidden = false
//        self.likeButton.bindEntity(entity: message)
//        self.likes.text = nil
//        if message.countLikes != nil {
//            if message.countLikes?.intValue != 0 {
//                self.likes.text = String(message.countLikes.intValue)
//            }
//        }
//        self.likes.textColor = message.userLikesValue ? Colors.brandColor : Theme.colorText
		
		self.setNeedsLayout()	// Needed because binding can change the layout
	}
	
	private func bindPhoto(photoUrl: URL) {
		
		if self.photo?.image != nil
			&& self.photo!.linkedPhotoUrl != nil
			&& self.photo!.linkedPhotoUrl?.absoluteString == photoUrl.absoluteString {
			return
		}
		
		self.photo?.image = nil
		self.photo!.setImageWithUrl(url: photoUrl, animate: true)
	}
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        self.bounds.size.width = size.width
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return sizeThatFitsSubviews()
    }
}