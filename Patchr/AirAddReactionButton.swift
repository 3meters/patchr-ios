//
//  Created by Jay Massena on 5/22/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Emoji
import STPopup

class AirAddReactionButton: UIControl {
    
    var message: FireMessage?
    var imageView: UIImageView!
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
        self.imageView.anchorInCenter(withWidth: 20, height: 20)
    }

    /*--------------------------------------------------------------------------------------------
     * MARK: - Events
     *--------------------------------------------------------------------------------------------*/

    func onClick(sender: AnyObject?) {
        showReactionPicker()
    }
    
    func backgroundTapped(sender: AnyObject?) {
        if let controller = self.sheetController {
            controller.dismiss()
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
        self.imageView = UIImageView()
        self.imageView.image = UIImage(named: "imgAddReactionLight")
        self.imageView.tintColor = Theme.colorButtonBorder
        self.addSubview(self.imageView)
        self.addTarget(self, action: #selector(onClick(sender:)), for: .touchUpInside)
    }
    
    func showReactionPicker() {
        let layout = UICollectionViewFlowLayout()
        let controller = ReactionPickerController(collectionViewLayout: layout)
        controller.inputMessage = self.message
        controller.contentSizeInPopup = CGSize(width: Config.screenWidth, height: 192)
        
        if let topController = UIViewController.topMostViewController() {
            let popController = STPopupController(rootViewController: controller)
            popController.style = .bottomSheet
            popController.hidesCloseButton = true
            self.sheetController = popController
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped(sender:)))
            self.sheetController.backgroundView?.addGestureRecognizer(tap)
            self.sheetController.present(in: topController)
        }
    }

    override var intrinsicContentSize: CGSize {
        get {
            let desiredButtonSize = CGSize(width: 40, height: 36)
            return desiredButtonSize
        }
    }
}
