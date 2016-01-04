//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

struct Animation {
	
	static func bounce(view: UIView) {
		let springAnimation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
		springAnimation.velocity = NSValue(CGPoint: CGPointMake(5, 5))
		springAnimation.springBounciness = 20.0
		springAnimation.toValue = NSValue(CGPoint: CGPointMake(1, 1))
		view.pop_addAnimation(springAnimation, forKey: "springAnimation")
	}
}