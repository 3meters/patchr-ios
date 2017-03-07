//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import SDWebImage
import TTTAttributedLabel

class MessageViewCell: AirUIView {

    var message: FireMessage!

    var description_: UILabel!
    var photoView: AirImageView!
    var userName = AirLabelDisplay()
    var userPhotoControl = PhotoControl()
    var createdDate = AirLabelDisplay()
    var edited = AirLabelDisplay()
    var unread = AirLabelDisplay()

    var toolbar = AirUIView()
    var likeButton = AirLikeButton(frame: CGRect.zero)
    var likesLabel = AirLabelDisplay()
    
    var template = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
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
        let photoHeight = columnWidth * 0.5625        // 16:9 aspect ratio

        self.userPhotoControl.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 48, height: 48)

        /* Header */

        self.createdDate.sizeToFit()
        self.edited.sizeToFit()
        self.unread.sizeToFit()
        self.userName.sizeToFit()
        self.userName.align(toTheRightOf: self.userPhotoControl, matchingTopWithLeftPadding: 8, width: self.userName.width(), height: 22)
        self.createdDate.align(toTheRightOf: self.userName, matchingBottomWithLeftPadding: 8, width: self.createdDate.width(), height: self.createdDate.height())
        self.unread.align(toTheRightOf: self.createdDate, matchingBottomWithLeftPadding: 8, width: self.unread.width(), height: self.unread.height())

        /* Body */

        var bottomView: UIView? = self.photoView
        if self.message.attachments == nil {
            bottomView = self.description_
            self.description_?.bounds.size.width = columnWidth
            self.description_?.sizeToFit()
            self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 2, height: self.description_!.height())
        }

        if self.message.text != nil && self.message.attachments != nil {
            self.description_?.bounds.size.width = columnWidth
            self.description_?.sizeToFit()
            self.description_?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 2, height: self.description_!.height())
            self.photoView?.alignUnder(self.description_!, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 10, height: photoHeight)
        }
        else if (self.message.attachments?.first) != nil {
            self.photoView?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 10, height: photoHeight)
        }

        self.edited.alignUnder(bottomView!, matchingLeftWithTopPadding: 2, width: self.edited.width(), height: self.edited.isHidden ? 0 : self.edited.height())

        /* Footer */

        self.toolbar.alignUnder(self.edited, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 0, height: self.toolbar.isHidden ? 0 : 36)
        self.likeButton.anchorCenterLeft(withLeftPadding: 0, width: self.likeButton.width(), height: self.likeButton.height())
        self.likeButton.frame.origin.x -= 12
        self.likesLabel.sizeToFit()
        self.likesLabel.align(toTheRightOf: self.likeButton, matchingCenterWithLeftPadding: 0, width: self.likesLabel.width(), height: self.likesLabel.height())
        self.likesLabel.frame.origin.x -= 4
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {
        /*
         * The calls to addSubview will trigger a call to layoutSubviews for
         * the current update cycle.
         */
        self.hitInsets = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)

        /* Description */
        self.description_ = TTTAttributedLabel(frame: CGRect.zero)
        self.description_!.numberOfLines = 0
        self.description_!.font = Theme.fontTextList

        if self.description_ != nil && (self.description_ is TTTAttributedLabel) {
            let linkColor = Theme.colorTint
            let linkActiveColor = Theme.colorTint
            let label = self.description_ as! TTTAttributedLabel
            label.linkAttributes = [kCTForegroundColorAttributeName as AnyHashable: linkColor]
            label.activeLinkAttributes = [kCTForegroundColorAttributeName as AnyHashable: linkActiveColor]
            label.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.address.rawValue
        }

        /* Photo: give initial size in case the image displays before call to layoutSubviews		 */
        let columnLeft = CGFloat(48 + 8)
        let columnWidth = min(Config.contentWidthMax, UIScreen.main.bounds.size.width) - columnLeft
        let photoHeight = columnWidth * 0.5625        // 16:9 aspect ratio

        self.photoView = AirImageView(frame: CGRect(x: 0, y: 0, width: columnWidth, height: photoHeight))
        self.photoView!.clipsToBounds = true
        self.photoView!.cornerRadius = 4
        self.photoView!.contentMode = .scaleAspectFill
        self.photoView!.backgroundColor = Theme.colorBackgroundImage

        /* Header */
        self.userName.font = Theme.fontTextBold
        self.userName.numberOfLines = 1
        self.userName.lineBreakMode = .byTruncatingMiddle

        self.createdDate.font = Theme.fontComment
        self.createdDate.numberOfLines = 1
        self.createdDate.textColor = Theme.colorTextSecondary
        self.createdDate.textAlignment = .right

        self.edited.text = "(edited)"
        self.edited.font = Theme.fontCommentSmall
        self.edited.numberOfLines = 1
        self.edited.textColor = Colors.gray66pcntColor
        self.edited.textAlignment = .left
        self.edited.isHidden = true

        self.unread.text = "new"
        self.unread.font = Theme.fontText
        self.unread.numberOfLines = 1
        self.unread.textColor = Colors.accentColorDark
        self.unread.textAlignment = .left
        self.unread.isHidden = true
        
        /* Footer */

        self.toolbar.hitInsets = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)
        self.toolbar.isHidden = true

        self.likeButton.imageView!.tintColor = Theme.colorTint
        self.likeButton.bounds.size = CGSize(width: 48, height: 48)
        self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(14, 12, 14, 12)
        self.likeButton.hitInsets = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)

        self.likesLabel.font = Theme.fontText
        self.likesLabel.numberOfLines = 1
        self.likesLabel.textColor = Theme.colorText
        self.likesLabel.textAlignment = .right

        self.toolbar.addSubview(self.likeButton)
        self.toolbar.addSubview(self.likesLabel)

        self.addSubview(self.toolbar)
        self.addSubview(self.description_!)
        self.addSubview(self.photoView!)
        self.addSubview(self.userPhotoControl)
        self.addSubview(self.userName)
        self.addSubview(self.createdDate)
        self.addSubview(self.edited)
        self.addSubview(self.unread)
    }

    func reset() {
        self.description_?.text = nil
        self.description_?.textColor = Colors.black
        self.description_!.font = Theme.fontTextList
        self.userName.text = nil
        self.unread.isHidden = true
        self.toolbar.isHidden = true
        self.likeButton.isHidden = true
        self.likesLabel.isHidden = true
        self.edited.isHidden = true
    }

    func bind(message: FireMessage) {

        self.message = message

        self.description_?.isHidden = true
        
        if let description = message.text {
            self.description_?.isHidden = false
            let label = self.description_ as! TTTAttributedLabel
            if message.source == "system" {
                label.textInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
                self.description_.textColor = Colors.accentColorTextLight
                self.description_!.font = Theme.fontTextListItalic
            }
            else {
                label.textInsets = UIEdgeInsets.zero
            }
            self.description_?.text = description
        }
        
        self.userName.text = message.creator?.username
        let fullName = message.creator?.fullName
        
        if let photo = message.creator?.profile?.photo {
            if !self.template {
                if photo.uploading != nil {
                    self.userPhotoControl.bind(url: URL(string: photo.cacheKey)!, fallbackUrl: nil, name: nil, colorSeed: nil, uploading: true)
                }
                else {
                    if let url = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.profile) {
                        let fallbackUrl = ImageUtils.fallbackUrl(prefix: photo.filename!)
                        self.userPhotoControl.bind(url: url, fallbackUrl: fallbackUrl, name: fullName, colorSeed: message.creator?.id)
                    }
                }
            }
        }
        else {
            self.userPhotoControl.bind(url: nil, fallbackUrl: nil, name: fullName, colorSeed: message.creator?.id)
        }
        
        if let photo = message.attachments?.values.first?.photo {
            self.photoView?.isHidden = false
            if !self.template { // Don't fetch if acting as template
                if let url = ImageUtils.url(prefix: photo.filename, source: photo.source, category: SizeCategory.standard) {
                    if !self.photoView.associated(withUrl: url) {
                        self.photoView?.image = nil
                        FireController.instance.isConnected() { connected in
                            if connected == nil || !connected! {
                                let cacheUrl = URL(string: photo.cacheKey)!
                                self.photoView.setImageFromCache(url: cacheUrl, animate: true)
                            }
                            else {
                                let fallbackUrl = ImageUtils.fallbackUrl(prefix: photo.filename!)
                                self.photoView?.image = nil
                                self.photoView.setImageWithUrl(url: url, fallbackUrl: fallbackUrl, animate: true)
                            }
                        }
                    }
                }
            }
        }
        else {
            self.photoView?.isHidden = true
            self.photoView?.image = nil
        }

        let createdAt = DateUtils.from(timestamp: message.createdAt!)
        self.createdDate.text = DateUtils.timeAgoShort(date: createdAt)

        self.edited.isHidden = (message.createdAt == message.modifiedAt)

        let thumbsupCount = message.getReactionCount(emoji: .thumbsup)
        let userId = UserController.instance.userId!

        if thumbsupCount != 0 {
            self.likeButton.bind(message: message)
            self.likesLabel.textColor = Theme.colorText
            self.likesLabel.text = String(thumbsupCount)
            if message.getReaction(emoji: .thumbsup, userId: userId) {
                self.likesLabel.textColor = Colors.brandColor
            }
            self.toolbar.isHidden = false
            self.likeButton.isHidden = false
            self.likesLabel.isHidden = false
        }
        else {
            self.toolbar.isHidden = true
            self.likeButton.isHidden = true
            self.likesLabel.isHidden = true
        }

        self.setNeedsLayout()    // Needed because binding can change the layout
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        self.bounds.size.width = size.width
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return sizeThatFitsSubviews()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let newRect = CGRect(x: 0 + hitInsets.left,
                             y: 0 + hitInsets.top,
                             width: self.frame.size.width - hitInsets.left - hitInsets.right,
                             height: self.frame.size.height - hitInsets.top - hitInsets.bottom)

        return newRect.contains(point)
    }
}
