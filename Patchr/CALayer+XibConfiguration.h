//
//  CALayer+XibConfiguration.h
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-18.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

// Allows a layer's border color to be set from interface build using runtime attributes
// From http://stackoverflow.com/a/17993890/2247399
@interface CALayer (XibConfiguration)

// This assigns a CGColor to borderColor.
@property(nonatomic, assign) UIColor* borderUIColor;

@end
