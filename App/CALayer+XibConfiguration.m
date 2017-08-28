//
//  CALayer+XibConfiguration.m
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-18.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "CALayer+XibConfiguration.h"

@implementation CALayer (XibConfiguration)

-(void)setBorderUIColor:(UIColor*)color {
    self.borderColor = color.CGColor;
}

-(UIColor*)borderUIColor {
    return [UIColor colorWithCGColor:self.borderColor];
}

@end
