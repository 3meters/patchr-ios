//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import pop

struct Animation {
	
	static func bounce(view: UIView?) {
		if view != nil {
			view!.pop_removeAllAnimations()
			let springAnimation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
			springAnimation.velocity = NSValue(CGPoint: CGPointMake(5, 5))
			springAnimation.springBounciness = 20.0
			springAnimation.toValue = NSValue(CGPoint: CGPointMake(1, 1))
			view!.pop_addAnimation(springAnimation, forKey: "springAnimation")
		}
	}
	
	static func spin(view: UIView?, to: Double) {
		if view != nil {
			view!.layer.pop_removeAllAnimations()
			let spin = POPSpringAnimation(propertyNamed: kPOPLayerRotation)
			spin.velocity = NSValue(CGPoint: CGPointMake(10, 10))
			spin.springBounciness = 20.0
			spin.toValue = NSNumber(double: to)
			view!.layer.pop_addAnimation(spin, forKey: "spinAnimation")
		}
	}
}