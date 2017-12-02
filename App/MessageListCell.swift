import Localize_Swift
import UIKit
import TTTAttributedLabel

class MessageListCell: UICollectionViewCell {

    var description_: UILabel!
    var imageView: AirImageView!
    var userName = AirLabelDisplay()
    var userPhotoControl = PhotoControl()
    var createdDate = AirLabelDisplay()
    var edited = AirLabelDisplay()
    var unreadIndicator = UIView()
    var reactionToolbar: AirReactionToolbar!
    var commentsButton = CommentsButton()
    var commentsStack = UIStackView(frame: .zero)
    var chrome: ChromeViewBase!
    var payload = UIView()

    var inputUserQuery: UserQuery! // Passed in by table data source
    var inputUnreadQuery: UnreadQuery? // Passed in by table data source
    var unreadCommentsQuery: UnreadQuery?
    var message: FireMessage!
    
    var template = false
    var decorated = false
    var isUnread = false {
        didSet {
            self.unreadIndicator.isHidden = !isUnread
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Events
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
        
        self.contentView.bounds.size.width = self.bounds.size.width
        
        let columnLeft = CGFloat(48 + 8)
        let columnWidth = min(Config.contentWidthMax, Config.screenWidth) - (columnLeft + self.chrome.padding.left + self.chrome.padding.right)
        let photoHeight = columnWidth * 0.5625 // 16:9 aspect ratio

        self.userPhotoControl.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: 48, height: 48)
        self.userPhotoControl.cornerRadius = 24

        /* Header */

        self.createdDate.sizeToFit()
        self.edited.sizeToFit()
        self.userName.sizeToFit()
        self.userName.align(toTheRightOf: self.userPhotoControl, matchingTopWithLeftPadding: 8, width: self.userName.width(), height: 22)
        self.createdDate.align(toTheRightOf: self.userName, matchingBottomWithLeftPadding: 8, width: self.createdDate.width(), height: self.createdDate.height())
        self.unreadIndicator.cornerRadius = 6
        self.unreadIndicator.align(toTheRightOf: self.createdDate, matchingCenterWithLeftPadding: 8, width: 12, height: 12)

        /* Body */

        var bottomView: UIView? = self.imageView
        if self.message.attachments == nil {
            bottomView = self.description_
            self.description_?.bounds.size.width = columnWidth
            self.description_?.sizeToFit()
            self.description_?.alignUnder(self.userName, matchingLeftWithTopPadding: 2, width: columnWidth, height: self.description_!.height())
        }

        if self.message.text != nil && self.message.attachments != nil {
            self.description_?.bounds.size.width = columnWidth
            self.description_?.sizeToFit()
            self.description_?.alignUnder(self.userName, matchingLeftWithTopPadding: 2, width: columnWidth, height: self.description_!.height())
            self.imageView?.alignUnder(self.description_!, matchingLeftWithTopPadding: 10, width: columnWidth, height: photoHeight)
            self.imageView.progressView.anchorInCenter(withWidth: 150, height: 20)
        }
        else if (self.message.attachments?.first) != nil {
            self.imageView?.alignUnder(self.userName, matchingLeftWithTopPadding: 10, width: columnWidth, height: photoHeight)
            self.imageView.progressView.anchorInCenter(withWidth: 150, height: 20)
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
        
        if self.commentsStack.arrangedSubviews.count > 0 {
            let size = self.commentsStack.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
            self.commentsStack.alignUnder(self.reactionToolbar
                , matchingLeftWithTopPadding: 8
                , width: columnWidth
                , height: size.height)
        } else {
            self.commentsStack.alignUnder(self.reactionToolbar
                , matchingLeftWithTopPadding: 0
                , width: columnWidth
                , height: 0)
        }

        self.payload.resizeToFitSubviews()
        self.bounds.size.height = self.payload.height() + self.chrome.padding.top + self.chrome.padding.bottom
        self.contentView.fillSuperview()
        self.chrome.fillSuperview() // super is contentView
        self.payload.fillSuperview(withLeftPadding: self.chrome.padding.left // super is contentView
            , rightPadding: self.chrome.padding.right
            , topPadding: self.chrome.padding.top
            , bottomPadding: self.chrome.padding.bottom)
    }

    /*--------------------------------------------------------------------------------------------
    * MARK: - Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {
        /*
         * The calls to addSubview will trigger a call to layoutSubviews for
         * the current update cycle.
         */
        self.chrome = ChromeViewRuled()
        self.payload.backgroundColor = Colors.white
        
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
        let photoHeight = columnWidth * 0.5625 // 16:9 aspect ratio

        self.imageView = AirImageView(frame: CGRect(x: 0, y: 0, width: columnWidth, height: photoHeight))
        self.imageView!.clipsToBounds = true
        self.imageView!.cornerRadius = 4
        self.imageView!.contentMode = .scaleAspectFill
        self.imageView!.backgroundColor = Theme.colorBackgroundImage
        self.imageView!.isHidden = true

        /* Header */
        self.userName.font = Theme.fontTextBold
        self.userName.numberOfLines = 1
        self.userName.lineBreakMode = .byTruncatingMiddle

        self.createdDate.font = Theme.fontComment
        self.createdDate.numberOfLines = 1
        self.createdDate.textColor = Theme.colorTextSecondary
        self.createdDate.textAlignment = .right

        self.edited.text = "edited_parens".localized()
        self.edited.font = Theme.fontCommentSmall
        self.edited.numberOfLines = 1
        self.edited.textColor = Colors.gray66pcntColor
        self.edited.textAlignment = .left

        self.unreadIndicator.backgroundColor = Theme.colorBackgroundBadge
        self.unreadIndicator.clipsToBounds = true
        self.unreadIndicator.isHidden = true
        
        self.reactionToolbar = AirReactionToolbar()
        self.reactionToolbar.alwaysShowAddButton = true
        
        self.commentsStack.axis = .vertical
        self.commentsStack.distribution = .equalSpacing
        self.commentsStack.alignment = .leading
        self.commentsStack.spacing = 8

        self.commentsButton.setTitle("comment".localized(), for: .normal)

        self.payload.addSubview(self.reactionToolbar)
        self.payload.addSubview(self.commentsButton)
        self.payload.addSubview(self.description_!)
        self.payload.addSubview(self.imageView!)
        self.payload.addSubview(self.userPhotoControl)
        self.payload.addSubview(self.userName)
        self.payload.addSubview(self.createdDate)
        self.payload.addSubview(self.edited)
        self.payload.addSubview(self.unreadIndicator)
        self.payload.addSubview(self.commentsStack)

        self.contentView.addSubview(self.chrome)
        self.contentView.addSubview(self.payload)

        self.commentsStack.translatesAutoresizingMaskIntoConstraints = false
        self.commentsStack.leftAnchor.constraint(equalTo: self.reactionToolbar.leftAnchor).isActive = true
        self.commentsStack.topAnchor.constraint(equalTo: self.reactionToolbar.bottomAnchor, constant: 8).isActive = true
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
        
        /* User */
        if let creator = message.creator {

            /* Username */
            self.userName.text = creator.username

            /* User photo */
            if let profilePhoto = creator.profile?.photo {
                if !self.template {
                    let url = ImageProxy.url(photo: profilePhoto, category: SizeCategory.profile)
                    if !self.userPhotoControl.imageView.associated(withUrl: url) {
                        let fullName = creator.title
                        self.userPhotoControl.imageView.image = nil
                        self.userPhotoControl.bind(url: url, name: fullName, colorSeed: creator.id)
                    }
                }
            }
            else {
                let fullName = creator.title
                if !self.template {
                    self.userPhotoControl.bind(url: nil, name: fullName, colorSeed: creator.id)
                }
            }
        }
        else {
            self.userName.text = "deleted".localized()
            if !self.template {
                self.userPhotoControl.bind(url: nil, name: "deleted".localized(), colorSeed: nil, color: Theme.colorBackgroundImage)
            }
        }

        /* Message photo */
        
        if let photo = message.attachments?.values.first?.photo {
            self.imageView?.isHidden = false
            if !self.template { // Don't fetch if acting as template
                let url = ImageProxy.url(photo: photo, category: SizeCategory.standard)
                let uploading = (photo.uploading != nil)
                if !self.imageView.associated(withUrl: url) {
                    self.imageView?.image = nil
                    self.imageView.setImageWithUrl(url: url, uploading: uploading, animate: true)
                }
            }
        }
        else {
            self.imageView?.isHidden = true
            self.imageView?.image = nil
        }
        
        /* Created date and edited flag */

        let createdAtDate = DateUtils.from(timestamp: message.createdAt!)
        self.createdDate.text = DateUtils.timeAgoShort(date: createdAtDate)
        
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
            self.commentsButton.bind(message: message)
        }

        /* Comments */
        
        if message.comments.count > 0 {
            let columnLeft = CGFloat(48 + 8)
            let columnWidth = min(Config.contentWidthMax, Config.screenWidth) - (columnLeft + self.chrome.padding.left + self.chrome.padding.right)
            let sortedKeys = Array(message.comments.keys).sorted(by: <)
            for key in sortedKeys {
                let comment = message.comments[key]
                let commentView = Bundle.loadView(fromNib: "CommentView", withType: CommentView.self)
                commentView.isUnread = false
                commentView.maxWidth = columnWidth
                commentView.bounds.size.width = columnWidth
                if self.template {
                    commentView.bind(comment: comment!)
                    self.commentsStack.addArrangedSubview(commentView)
                } else {
                    commentView.inputUserQuery = UserQuery(userId: comment!.createdBy!)
                    commentView.inputUserQuery.once(with: { error, user in
                        comment!.creator = user
                        commentView.bind(comment: comment!)
                        self.commentsStack.addArrangedSubview(commentView)
                        
                        if comment!.createdBy != UserController.instance.userId! {
                            let commentId = comment!.id!
                            let userId = UserController.instance.userId!
                            let channelId = comment!.channelId!
                            let messageId = comment!.messageId!
                            
                            commentView.inputUnreadQuery = UnreadQuery(level: .comment, userId: userId, channelId: channelId, messageId: messageId, commentId: commentId)
                            commentView.inputUnreadQuery!.observe(with: { [weak commentView] error, total in
                                guard let commentView = commentView else { return }
                                if total != nil && total! > 0 {
                                    commentView.isUnread = true
                                    FireController.instance.clearCommentUnread(commentId: commentId, messageId: messageId, channelId: channelId)
                                }
                            })
                        }
                    })
                }
            }
        }

        self.setNeedsLayout()
    }
    
    func reset() {
        self.imageView.reset()
        self.userPhotoControl.reset()
        self.commentsButton.reset()
        self.commentsStack.removeSubviews()
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
