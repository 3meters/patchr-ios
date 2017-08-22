//
//  AirView.m
//  Teeny
//
//  Created by Jay Massena on 5/31/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "UIView+BorderLayer.h"

@implementation UIView(BorderLayer)

@dynamic borderColor,borderWidth,cornerRadius;

-(void)setBorderColor:(UIColor *)borderColor{
    [self.layer setBorderColor:borderColor.CGColor];
}

-(void)setBorderWidth:(CGFloat)borderWidth{
    [self.layer setBorderWidth:borderWidth];
}

-(void)setCornerRadius:(CGFloat)cornerRadius{
    [self.layer setCornerRadius:cornerRadius];
}

@end
