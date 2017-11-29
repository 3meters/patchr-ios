//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class InviteMessageController: BaseViewController, UITextViewDelegate {
    
    lazy var textView: AirTextView = {
        let textView = AirTextView(frame: .zero)
        textView.placeholderAttributedText = NSAttributedString(
            string: "invite_message_placeholder".localized(),
            attributes: [
                NSAttributedStringKey.font: Theme.fontText,
                NSAttributedStringKey.foregroundColor: Theme.colorTextPlaceholder
            ])
        textView.initialize()
        textView.minNumberOfLines = 6
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.view.updateConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let _ = self.textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let _ = self.textView.resignFirstResponder()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        self.view.addSubview(self.textView)
        
        /* Setup constraints */
        self.view.heightAnchor.constraint(equalToConstant: 180).isActive = true
        
        var constraints = [NSLayoutConstraint]()
        let views: [String: UIView] = ["textView": self.textView]
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[textView]-12-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[textView]-16-|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(constraints)

        self.textView.delegate = self
    }
}
