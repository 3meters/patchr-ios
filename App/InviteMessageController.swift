//
//  NavigationController.swift
//
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import PopupDialog

class InviteMessageController: BaseViewController, UITextViewDelegate {
    
    lazy var textView: AirTextView = {
        let textView = AirTextView(frame: .zero)
        textView.placeholder = "Add personal message (optional)"
        textView.initialize()
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.isScrollEnabled = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.cornerRadius = 4.0
        textView.borderColor = Colors.gray80pcntColor
        textView.borderWidth = 0.5
        textView.rule.backgroundColor = Colors.clear
        textView.ruleEnabled = false
        textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12)
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
        self.view.setNeedsLayout()
        if let placeHolderLabel = textView.viewWithTag(100) as? UILabel {
            placeHolderLabel.isHidden = textView.hasText
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.textView.resignFirstResponder()
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    override func initialize() {
        super.initialize()
        self.view.addSubview(self.textView)
        
        /* Setup constraints */
        self.view.heightAnchor.constraint(equalToConstant: 192).isActive = true
        
        var constraints = [NSLayoutConstraint]()
        let views: [String: UIView] = ["textView": self.textView]
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[textView]-12-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[textView]-16-|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(constraints)

        self.textView.delegate = self
    }
}
