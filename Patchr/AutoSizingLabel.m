//
//  AutoSizingLabel.m
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-24.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "AutoSizingLabel.h"

// From: https://github.com/smileyborg/TableViewCellWithAutoLayoutiOS8/issues/7#issuecomment-56652247

@implementation AutoSizingLabel

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    if (self.numberOfLines == 0) {
        CGFloat boundsWidth = CGRectGetWidth(bounds);
        if (self.preferredMaxLayoutWidth != boundsWidth) {
            self.preferredMaxLayoutWidth = boundsWidth;
            [self setNeedsUpdateConstraints];
        }
    }
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    
    if (self.numberOfLines == 0) {
        // There's a bug where intrinsic content size may be 1 point too short
        size.height += 1;
    }
    
    return size;
}

@end
