//
//  MessageCell.swift
//  Patchr
//
//  Created by Jay Massena on 10/15/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import Localize_Swift
import UIKit
import TTTAttributedLabel

class MessageCell: UICollectionViewCell {

    @IBOutlet weak var userPhotoControl: PhotoControl!
    @IBOutlet weak var userName: AirLabel!
    @IBOutlet weak var createdDate: AirLabel!
    @IBOutlet weak var unreadIndicator: UIView!
    @IBOutlet weak var description_: TTTAttributedLabel!
    @IBOutlet weak var imageView: AirImageView!
    @IBOutlet weak var edited: AirLabel!
    @IBOutlet weak var reactionToolbar: AirReactionToolbar!
    @IBOutlet weak var commentsButton: CommentsButton!
    
    var inputUserQuery: UserQuery! // Passed in by table data source
    var inputUnreadQuery: UnreadQuery? // Passed in by table data source
    var unreadCommentsQuery: UnreadQuery?
    var message: FireMessage!
    
    var decorated = false
    var isUnread = false {
        didSet {
            self.unreadIndicator?.isHidden = !isUnread
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
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
        
        let columnLeft = CGFloat(48 + 8)
        let columnWidth = min(Config.contentWidthMax, Config.screenWidth) - (columnLeft /*+ self.chrome.padding.left + self.chrome.padding.right*/)
        
        /* Footer */
        if self.reactionToolbar.superview != nil {
            let toolbarSize = self.reactionToolbar.intrinsicContentSize
            var toolbarWidth = columnWidth
            if self.commentsButton?.superview != nil {
                self.commentsButton?.sizeToFit()
                toolbarWidth = min(toolbarSize.width, columnWidth - (16 + (self.commentsButton?.width())! + 8))
            }
            self.reactionToolbar.alignUnder(self.edited
                , matchingLeftWithTopPadding: 8
                , width: toolbarWidth
                , height: toolbarSize.height)
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {
        /*
         * The calls to addSubview will trigger a call to layoutSubviews for
         * the current update cycle.
         */
        self.description_.linkAttributes = [kCTForegroundColorAttributeName as AnyHashable: Theme.colorTint]
        self.description_.activeLinkAttributes = [kCTForegroundColorAttributeName as AnyHashable: Theme.colorTint]
        self.description_.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.address.rawValue

        /* Photo: give initial size in case the image displays before call to layoutSubviews		 */
        let columnLeft = CGFloat(48 + 8)
        let columnWidth = min(Config.contentWidthMax, Config.screenWidth) - columnLeft
        let photoHeight = columnWidth * 0.5625 // 16:9 aspect ratio
        self.imageView.frame = CGRect(x: 0, y: 0, width: columnWidth, height: photoHeight)
        self.imageView!.isHidden = true

        self.edited.text = "edited_parens".localized()
        self.edited.isHidden = true
        self.unreadIndicator.isHidden = true
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func bind(message: FireMessage) {
        
        guard message.createdAt != nil else { return }

        self.message = message
        
        /* Text */

        self.description_?.isHidden = true

        if let description = message.text {
            self.description_?.isHidden = false
            self.description_.textInsets = UIEdgeInsets.zero
            self.description_?.textColor = Colors.black
            self.description_!.font = Theme.fontTextList
            self.description_?.text = description
        }
        
        /* User */
        if let creator = message.creator {

            /* Username */
            self.userName.text = creator.username

            /* User photo */
            if let profilePhoto = creator.profile?.photo {
                let url = ImageProxy.url(photo: profilePhoto, category: SizeCategory.profile)
                if !self.userPhotoControl.imageView.associated(withUrl: url) {
                    let fullName = creator.title
                    self.userPhotoControl.imageView.image = nil
                    self.userPhotoControl.bind(url: url, name: fullName, colorSeed: creator.id)
                }
            }
            else {
                let fullName = creator.title
                self.userPhotoControl.bind(url: nil, name: fullName, colorSeed: creator.id)
            }
        }
        else {
            self.userName.text = "deleted".localized()
            self.userPhotoControl.bind(url: nil, name: "deleted".localized(), colorSeed: nil, color: Theme.colorBackgroundImage)
        }

        /* Message photo */
        
        if let photo = message.attachments?.values.first?.photo {
            self.imageView?.isHidden = false
            let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
            let uploading = (photo.uploading != nil)
            if !self.imageView.associated(withUrl: url) {
                self.imageView?.image = nil
                self.imageView.setImageWithUrl(url: url, uploading: uploading, animate: true)
            }
        }
        else {
            self.imageView?.isHidden = true
            self.imageView?.image = nil
        }
        
        /* Created date and edited flag */

        let createdAtDate = DateUtils.from(timestamp: message.createdAt!)
        self.createdDate.text = DateUtils.timeAgoShort(date: createdAtDate)
        let isEdited = (self.message.createdAt != self.message.modifiedAt)
        self.edited.isHidden = !isEdited

        /* Unread indicator */
        
        self.unreadIndicator.isHidden = !self.isUnread
        
        /* Reaction toolbar */
        
        if self.reactionToolbar.superview != nil {
            self.reactionToolbar.isHidden = true
            self.reactionToolbar.bind(message: message)
            self.reactionToolbar.isHidden = (self.reactionToolbar.reactionButtons.count == 0)
        }
        
        /* Comments button */
        
        if self.commentsButton.superview != nil {
            self.commentsButton.bind(message: message) // Message has commentCount property
            let userId = UserController.instance.userId!
            let channelId = message.channelId!
            let messageId = message.id!
            self.unreadCommentsQuery = UnreadQuery(level: .comments, userId: userId, channelId: channelId, messageId: messageId)
            self.unreadCommentsQuery!.observe(with: { [weak commentsButton] error, total in
                guard let button = commentsButton else { return }
                if total != nil && total! > 0 {
                    button.setTitleColor(Theme.colorBackgroundBadge, for: .normal)
                }
                else {
                    button.setTitleColor(Theme.colorButtonBorder, for: .normal)
                }
            })
        }
        
        self.setNeedsLayout()
    }
    
    func reset() {
        self.imageView.reset()
        self.userPhotoControl.reset()
        self.commentsButton.reset()
        self.description_?.textColor = Colors.black
        self.description_!.font = Theme.fontTextList
        self.unreadIndicator.isHidden = true
        self.isUnread = false
        self.inputUserQuery?.remove()
        self.inputUserQuery = nil
        self.inputUnreadQuery?.remove()
        self.inputUnreadQuery = nil
        self.unreadCommentsQuery?.remove()
        self.unreadCommentsQuery = nil
    }
}
