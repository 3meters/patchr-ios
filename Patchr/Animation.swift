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
			let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
			animation.velocity = NSValue(CGPoint: CGPointMake(5, 5))
			animation.springBounciness = 20.0
			animation.toValue = NSValue(CGPoint: CGPointMake(1, 1))
			view!.pop_addAnimation(animation, forKey: "bounce")
		}
	}
	
	static func bounceIn(view: UIView?) {
		if view != nil {
			view!.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
			animation.velocity = NSValue(CGPoint: CGPointMake(5, 5))
			animation.springBounciness = 15.0
			animation.toValue = NSValue(CGPoint: CGPointMake(1, 1))
			view!.pop_addAnimation(animation, forKey: "bounceIn")
		}
	}
	
	static func bounceOut(view: UIView?) {
		if view != nil {
			view!.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
			animation.velocity = NSValue(CGPoint: CGPointMake(10, 10))
			animation.springBounciness = 4.0
			animation.toValue = NSValue(CGPoint: CGPointMake(0.001, 0.001))
			view!.pop_addAnimation(animation, forKey: "bounceOut")
		}
	}
	
	static func spin(view: UIView?, to: Double) {
		if view != nil {
			view!.layer.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPLayerRotation)
			animation.velocity = NSValue(CGPoint: CGPointMake(10, 10))
			animation.springBounciness = 20.0
			animation.toValue = NSNumber(double: to)
			view!.layer.pop_addAnimation(animation, forKey: "spin")
		}
	}
}