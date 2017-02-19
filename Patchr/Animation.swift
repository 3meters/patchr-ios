//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import pop

struct Animation {
	
    static func bounce(view: UIView?, then: (()->())? = nil) {
		if view != nil {
			view!.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)!
            animation.velocity = NSValue(cgPoint: CGPoint(x:5, y:5))
			animation.springBounciness = 20.0
            animation.toValue = NSValue(cgPoint: CGPoint(x:1, y:1))
            animation.completionBlock = { animation, finished in
                if finished {
                    then?()
                }                
            }
			view!.pop_add(animation, forKey: "bounce")
		}
	}
	
	static func bounceIn(view: UIView?) {
		if view != nil {
			view!.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
            animation?.velocity = NSValue(cgPoint: CGPoint(x:5, y:5))
			animation?.springBounciness = 15.0
			animation?.toValue = NSValue(cgPoint: CGPoint(x:1, y:1))
			view!.pop_add(animation, forKey: "bounceIn")
		}
	}
	
	static func bounceOut(view: UIView?) {
		if view != nil {
			view!.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
			animation?.velocity = NSValue(cgPoint: CGPoint(x:10, y:10))
			animation?.springBounciness = 4.0
			animation?.toValue = NSValue(cgPoint: CGPoint(x:0.001, y:0.001))
			view!.pop_add(animation, forKey: "bounceOut")
		}
	}
	
	static func spin(view: UIView?, to: Double) {
		if view != nil {
			view!.layer.pop_removeAllAnimations()
			let animation = POPSpringAnimation(propertyNamed: kPOPLayerRotation)
			animation?.velocity = NSValue(cgPoint: CGPoint(x:10, y:10))
			animation?.springBounciness = 20.0
			animation?.toValue = NSNumber(value: to)
			view!.layer.pop_add(animation, forKey: "spin")
		}
	}
}
