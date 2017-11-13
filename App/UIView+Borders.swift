//
//  UIView+Borders.swift
//  Teeny
//
//  Created by Jay Massena on 11/12/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation
extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard layer.borderColor != nil else {
                return nil
            }
            return UIColor(cgColor: layer.borderColor!)
        }
    }
    @IBInspectable var layerBackgroundColor: UIColor? {
        set {
            layer.backgroundColor = newValue?.cgColor
        }
        get {
            guard layer.backgroundColor != nil else {
                return nil
            }
            return UIColor(cgColor: layer.backgroundColor!)
        }
    }
}
