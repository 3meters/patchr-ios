//
//  AirView.h
//  Patchr
//
//  Created by Jay Massena on 5/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(BorderLayer)

@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end
