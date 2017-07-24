//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import Facade

class AirReactionToolbar: AirScrollView {

    var contentHolder = UIView()
    var reactionButtons = [UIControl]()
    var reactionAddButton = AirAddReactionButton()
    var alwaysShowAddButton = false
    
	var buttonSpacing = CGFloat(8)
    var buttonHeight = CGFloat(32)
    var paddingLeft = CGFloat(0)
    var paddingRight = CGFloat(0)
    
    var messageQuery: MessageQuery!
    
    deinit {
        self.messageQuery?.remove()
    }
    
    override func initialize() {
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.addSubview(self.contentHolder)
    }

	func bind(message: FireMessage) {
        
        self.layout(message: message, animate: false)
        
        let channelId = message.channelId!
        let messageId = message.id!
        self.messageQuery = MessageQuery(channelId: channelId, messageId: messageId)
        self.messageQuery.observe { [weak self] error, message in
            guard let this = self else { return }
            guard let message = message else { return }
            this.layout(message: message)
        }
	}
    
    func layout(message: FireMessage, animate: Bool = true) {
        self.reactionButtons.removeAll()
        self.contentHolder.removeSubviews()
        
        if let reactions = message.reactions, reactions.count > 0 {
            for reactionCode in reactions.keys {
                let reactionCount = message.getReactionCount(emoji: reactionCode)
                if reactionCount > 0 {
                    let reactionButton = AirReactionButton()
                    reactionButton.bind(message: message, emojiCode: reactionCode, animate: animate)
                    self.reactionButtons.append(reactionButton)
                    self.contentHolder.addSubview(reactionButton)
                }
            }
        }
        
        if self.reactionButtons.count > 0 || self.alwaysShowAddButton {
            self.reactionAddButton.message = message
            self.reactionButtons.append(self.reactionAddButton)
            self.contentHolder.addSubview(self.reactionAddButton)
        }
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

	override func layoutSubviews() {
        self.contentHolder.fillSuperview()
		var previous: UIView? = nil
		for reactionButton in self.reactionButtons {
            let buttonSize = reactionButton.intrinsicContentSize
			if previous == nil {
                reactionButton.anchorCenterLeft(withLeftPadding: self.paddingLeft, width: buttonSize.width, height: self.buttonHeight)
			} else {
                reactionButton.align(toTheRightOf: previous, matchingCenterWithLeftPadding: self.buttonSpacing, width: buttonSize.width, height: self.buttonHeight)
            }
            previous = reactionButton
		}
        self.contentHolder.resizeToFitSubviews()
        self.contentSize = CGSize(width: self.contentHolder.width(), height: self.contentHolder.height())
	}
    
    override var intrinsicContentSize: CGSize {
        get {
            var width = self.paddingLeft
            for reactionButton in self.reactionButtons {
                width += reactionButton.intrinsicContentSize.width
                if self.reactionButtons.count > 1 {
                    width += self.buttonSpacing
                }
            }
            width += paddingRight
            let desiredSize = CGSize(width: width, height: self.reactionButtons.count > 0 ? self.buttonHeight : 0)
            return desiredSize
        }
    }
}
