//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class MessageListCell: UITableViewCell {

    var message: FireMessage!
    var userQuery: UserQuery! // Passed in by table data source
    var unreadQuery: UnreadQuery? // Passed in by table data source

    var description_: UILabel!
    var photoView: AirImageView!
    var userName = AirLabelDisplay()
    var userPhotoControl = PhotoControl()
    var createdDate = AirLabelDisplay()
    var edited = AirLabelDisplay()
    var unread = AirLabelDisplay()
    var hitInsets: UIEdgeInsets = UIEdgeInsets.zero

    var reactionToolbar: AirReactionToolbar!
    var commentsButton = CommentsButton()

    var template = false
    var decorated = false

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        guard self.message != nil else { return }
        
        self.contentView.bounds.size.width = self.bounds.size.width - 24
        
        let columnLeft = CGFloat(48 + 8)
        let columnWidth = self.contentView.width() - columnLeft
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
            self.photoView.progressView.anchorInCenter(withWidth: 150, height: 20)
        }
        else if (self.message.attachments?.first) != nil {
            self.photoView?.alignUnder(self.userName, matchingLeftAndFillingWidthWithRightPadding: 0, topPadding: 10, height: photoHeight)
            self.photoView.progressView.anchorInCenter(withWidth: 150, height: 20)
        }
        
        let isEdited = (self.message.createdAt != self.message.modifiedAt)
        self.edited.alignUnder(bottomView!, matchingLeftWithTopPadding: isEdited ? 2 : 0, width: self.edited.width(), height: isEdited ? self.edited.height() : 0)

        /* Footer */

        if self.reactionToolbar.superview != nil {
            let toolbarSize = self.reactionToolbar.intrinsicContentSize
            var toolbarWidth = columnWidth
            if self.commentsButton.superview != nil {
                self.commentsButton.sizeToFit()
                toolbarWidth = min(toolbarSize.width, columnWidth - (16 + self.commentsButton.width() + 8))
            }
            self.reactionToolbar.alignUnder(self.edited
                , matchingLeftWithTopPadding: 8
                , width: toolbarWidth
                , height: toolbarSize.height)
        }
        
        if self.commentsButton.superview != nil {
            self.commentsButton.align(toTheRightOf: self.reactionToolbar
                , matchingCenterWithLeftPadding: 8
                , width: self.commentsButton.width() + 16
                , height: self.reactionToolbar.height())
        }
        
        self.contentView.resizeToFitSubviews()
        self.bounds.size.height = self.contentView.height() + 24
        self.contentView.fillSuperview(withLeftPadding: 12, rightPadding: 12, topPadding: 12, bottomPadding: 12)
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

        if let label = self.description_ as? TTTAttributedLabel {
            let linkColor = Theme.colorTint
            let linkActiveColor = Theme.colorTint
            label.linkAttributes = [kCTForegroundColorAttributeName as AnyHashable: linkColor]
            label.activeLinkAttributes = [kCTForegroundColorAttributeName as AnyHashable: linkActiveColor]
            label.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.address.rawValue
        }

        /* Photo: give initial size in case the image displays before call to layoutSubviews		 */
        let columnLeft = CGFloat(48 + 8)
        let columnWidth = min(Config.contentWidthMax, Config.screenWidth) - columnLeft
        let photoHeight = columnWidth * 0.5625        // 16:9 aspect ratio

        self.photoView = AirImageView(frame: CGRect(x: 0, y: 0, width: columnWidth, height: photoHeight))
        self.photoView!.clipsToBounds = true
        self.photoView!.cornerRadius = 4
        self.photoView!.contentMode = .scaleAspectFill
        self.photoView!.backgroundColor = Theme.colorBackgroundImage
        self.photoView!.isHidden = true

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

        self.unread.text = "new"
        self.unread.font = Theme.fontText
        self.unread.numberOfLines = 1
        self.unread.textColor = Theme.colorBackgroundBadge
        self.unread.textAlignment = .left
        self.unread.isHidden = true
        
        self.selectionStyle = .none
        
        self.reactionToolbar = AirReactionToolbar()
        self.reactionToolbar.alwaysShowAddButton = true
        
        self.contentView.addSubview(self.reactionToolbar)
        self.contentView.addSubview(self.commentsButton)
        self.contentView.addSubview(self.description_!)
        self.contentView.addSubview(self.photoView!)
        self.contentView.addSubview(self.userPhotoControl)
        self.contentView.addSubview(self.userName)
        self.contentView.addSubview(self.createdDate)
        self.contentView.addSubview(self.edited)
        self.contentView.addSubview(self.unread)
    }

    func bind(message: FireMessage) {
        
        guard message.createdAt != nil else { return }

        self.message = message
        
        /* Text */

        self.description_?.isHidden = true

        if let description = message.text {
            self.description_?.isHidden = false
            let label = self.description_ as! TTTAttributedLabel
            label.textInsets = UIEdgeInsets.zero
            self.description_?.textColor = Colors.black
            self.description_!.font = Theme.fontTextList
            self.description_?.text = description
        }
        
        /* Username */
        
        self.userName.text = message.creator?.username
        
        /* User photo */
        
        if let profilePhoto = message.creator?.profile?.photo {
            if !self.template {
                let url = ImageProxy.url(photo: profilePhoto, category: SizeCategory.profile)
                if !self.userPhotoControl.photoView.associated(withUrl: url) {
                    let fullName = message.creator?.fullName
                    self.userPhotoControl.photoView.image = nil
                    self.userPhotoControl.bind(url: url, name: fullName, colorSeed: message.creator?.id)
                }
            }
        }
        else {
            let fullName = message.creator?.fullName
            self.userPhotoControl.bind(url: nil, name: fullName, colorSeed: message.creator?.id)
        }
        
        /* Message photo */
        
        if let photo = message.attachments?.values.first?.photo {
            self.photoView?.isHidden = false
            if !self.template { // Don't fetch if acting as template
                let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
                let uploading = (photo.uploading != nil)
                if !self.photoView.associated(withUrl: url) {
                    self.photoView?.image = nil
                    self.photoView.setImageWithUrl(url: url, uploading: uploading, animate: true)
                }
            }
        }
        else {
            self.photoView?.isHidden = true
            self.photoView?.image = nil
        }
        
        /* Created date and edited flag */

        let createdAtDate = DateUtils.from(timestamp: message.createdAt!)
        self.createdDate.text = DateUtils.timeAgoShort(date: createdAtDate)
        
        /* Reaction toolbar */
        
        if self.reactionToolbar.superview != nil {
            self.reactionToolbar.isHidden = true
            self.reactionToolbar.bind(message: message)
            self.reactionToolbar.isHidden = (self.reactionToolbar.reactionButtons.count == 0)
        }
        
        /* Comments button */
        
        if self.commentsButton.superview != nil {
            self.commentsButton.bind(message: message)
        }
        
        self.setNeedsLayout()
    }
    
    func reset() {
        self.photoView.reset()
        self.userPhotoControl.reset()
        self.commentsButton.reset()
        self.description_?.textColor = Colors.black
        self.description_!.font = Theme.fontTextList
        self.unread.isHidden = true
        self.userQuery?.remove()
        self.userQuery = nil
        self.unreadQuery?.remove()
        self.unreadQuery = nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let newRect = CGRect(x: 0 + hitInsets.left,
                             y: 0 + hitInsets.top,
                             width: self.frame.size.width - hitInsets.left - hitInsets.right,
                             height: self.frame.size.height - hitInsets.top - hitInsets.bottom)

        return newRect.contains(point)
    }
}
