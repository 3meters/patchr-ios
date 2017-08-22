//
//  MessageDetailViewController.swift
//  Teeny
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Emoji

class ReactionPickerController: UICollectionViewController {
	
    var inputMessage: FireMessage!
    /* New codes must be added to firebase security rules */
	var emojiCodes = [
        "thumbsup",
        "thumbsdown",
        "grinning",
        "laughing",
        "yum",
        "heart_eyes",
        "drooling_face",
        "astonished",
        "sleeping",
        "confused",
        "clap",
        "tada",
        "heart",
        "100",
        "muscle",
        "trophy",
        "cocktail",
        "fireworks",
        "gift",
        "bulb",
        "smiley_cat",
        "smiling_imp",
        "zzz",
        "poop",
    ]
	var footerView: UIView!
    fileprivate var sectionInsets: UIEdgeInsets?
    fileprivate var thumbnailWidth: CGFloat?
    fileprivate var availableWidth: CGFloat?
    fileprivate let maxDimen: Int = Int(Config.imageDimensionMax)
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
    
    override func viewWillLayoutSubviews() {
        self.view.fillSuperview(withLeftPadding: 12, rightPadding: 12, topPadding: 12, bottomPadding: 12)
    }
    
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func closeAction(sender: AnyObject) {
        self.close(animated: true)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.collectionView!.backgroundColor = Theme.colorBackgroundForm
        self.collectionView!.register(UINib(nibName: "EmojiCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
        
		/* Navigation bar buttons */
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
		self.navigationItem.leftBarButtonItems = [closeButton]
	}
}

extension ReactionPickerController { /* UICollectionViewDelegate, UICollectionViewDataSource */
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) -> Void {
        
		let cell = collectionView.cellForItem(at: indexPath) as! EmojiViewCell
        let emojiCode = ":\(cell.emojiCode!):"
        let userId = UserController.instance.userId!
        let messageId = self.inputMessage.id!
        let reacted = self.inputMessage.getReaction(emoji: emojiCode, userId: userId)
        
        if !reacted {
            Reporting.track("add_reaction", properties: ["code": emojiCode])
            inputMessage.addReaction(emoji: emojiCode)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.MessageDidUpdate)
                , object: self, userInfo: ["message_id": messageId]) // Clears cached row height for the message
        }
        
        self.close()
	}
	
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.emojiCodes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? EmojiViewCell
        cell!.backgroundColor = Theme.colorBackgroundForm
        cell!.emojiCode = self.emojiCodes[indexPath.row]
        cell!.emojiLabel.text = String.emojiDictionary[self.emojiCodes[indexPath.row]]
        
        return cell!
    }
}
