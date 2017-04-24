//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Emoji
import STPopup

class AirReactionButton: UIControl {
    
    var message: FireMessage?
    var reactionPath: String!
    var reactionHandle: UInt!
    var emojiCode: String!  // :thumbsup:, :sunglasses:, etc
    var emojiLabel: UILabel!
    var countLabel: UILabel!
    var toggledOn = false
    var asAddButton = false
    weak var sheetController: STPopupController!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    override func layoutSubviews() {
        self.countLabel.sizeToFit()
        self.emojiLabel.sizeToFit()
        self.emojiLabel.anchorCenterLeft(withLeftPadding: 8, width: self.emojiLabel.width(), height: self.emojiLabel.height())
        self.countLabel.align(toTheRightOf: self.emojiLabel, matchingCenterWithLeftPadding: 8, width: self.countLabel.width(), height: self.countLabel.height())
    }
    
    deinit {
        if self.reactionHandle != nil {
            FireController.db.child(self.reactionPath).removeObserver(withHandle: self.reactionHandle)
        }
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    func onClick(sender: AnyObject) {
        if let message = self.message {
            self.isEnabled = false
            if self.toggledOn {
                Reporting.track("remove_reaction", properties: ["code": emojiCode])
                message.removeReaction(emoji: self.emojiCode)
                self.toggle(on: false, animate: true)
                self.isEnabled = true
            }
            else {
                Reporting.track("add_reaction", properties: ["code": emojiCode])
                message.addReaction(emoji: self.emojiCode)
                self.toggle(on: true, animate: true)
                self.isEnabled = true
            }
        }
    }
    
    func backgroundTapped(sender: AnyObject?) {
        if let controller = self.sheetController {
            controller.dismiss()
        }
    }
    
    func longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if let message = self.message {
                let messageId = message.id!
                let groupId = message.groupId!
                let channelId = message.channelId!
                let emojiCode = self.emojiCode!
                let emojiCount = message.getReactionCount(emoji: emojiCode)
                let emoji = self.emojiLabel.text
                let path = "group-messages/\(groupId)/\(channelId)/\(messageId)/reactions/\(emojiCode)"
                let controller = MemberListController()
                
                controller.scope = .reaction
                controller.inputReactionPath = path
                controller.inputEmojiCode = emojiCode
                controller.inputEmoji = emoji
                controller.inputEmojiCount = emojiCount
                controller.contentSizeInPopup = CGSize(width: Config.screenWidth, height: Config.screenWidth)
                
                if let topController = UIViewController.topMostViewController() {
                    let popController = STPopupController(rootViewController: controller)
                    let backgroundView = UIView()
                    backgroundView.backgroundColor = Colors.opacity25pcntBlack
                    popController.style = .bottomSheet
                    popController.backgroundView = backgroundView
                    popController.hidesCloseButton = true
                    self.sheetController = popController
                    let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(sender:)))
                    self.sheetController.backgroundView?.addGestureRecognizer(tap)
                    self.sheetController.present(in: topController)
                }
            }
        }
    }
    
    /*--------------------------------------------------------------------------------------------
     * MARK: - Methods
     *--------------------------------------------------------------------------------------------*/

    func initialize() {
        
        self.backgroundColor = Theme.colorButtonFill
        self.layer.borderColor = Theme.colorButtonBorder.cgColor
        self.layer.borderWidth = Theme.dimenButtonBorderWidth
        self.layer.cornerRadius = Theme.dimenButtonCornerRadius

        self.emojiLabel = UILabel()
        self.emojiLabel.font = Theme.fontButtonTitle
        
        self.countLabel = UILabel()
        self.countLabel.font = Theme.fontButtonTitle
        self.countLabel.textColor = Theme.colorTextSecondary

        self.addSubview(self.emojiLabel)
        self.addSubview(self.countLabel)
        self.addTarget(self, action: #selector(onClick(sender:)), for: .touchUpInside)
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressAction(sender:)))
        recognizer.minimumPressDuration = TimeInterval(0.2)
        self.addGestureRecognizer(recognizer)
    }
    
    func bind(message: FireMessage, emojiCode: String /* :thumbsup: */, animate: Bool = true) {
        
        self.message = message
        self.emojiCode = emojiCode
        
        let emojiCodeStripped = emojiCode.replacingOccurrences(of: ":", with: "")
        self.emojiLabel.text = String.emojiDictionary[emojiCodeStripped]
        self.countLabel.text = "\(message.getReactionCount(emoji: emojiCode))"
        
        let userId = UserController.instance.userId!
        let hasReaction = message.getReaction(emoji: self.emojiCode, userId: userId)
        self.toggle(on: hasReaction, animate: true)
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func toggle(on: Bool, animate: Bool = true) {
        self.layer.borderColor = on ? Theme.colorButtonBorderSelected.cgColor : Theme.colorButtonBorder.cgColor
        self.backgroundColor = on ? Theme.colorButtonFillSelected : Theme.colorButtonFill
        self.countLabel.textColor = on ? Colors.accentColorTextLight : Theme.colorTextSecondary
        self.toggledOn = on
        if animate {
            Animation.bounce(view: self.countLabel)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            self.countLabel.sizeToFit()
            self.emojiLabel.sizeToFit()
            let desiredWidth = 8 + self.emojiLabel.width() + 8 + self.countLabel.width() + 8
            let desiredHeight = CGFloat(32)
            let desiredButtonSize = CGSize(width: desiredWidth, height: desiredHeight)
            return desiredButtonSize
        }
    }
}
