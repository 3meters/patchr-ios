//
//  AirTableViewCell.m
//  Patchr
//
//  Created by Jay Massena on 5/8/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "AirTableViewCell.h"

// From: http://stackoverflow.com/questions/19256996/uibutton-not-showing-highlight-on-tap-in-ios7/26049216#26049216

@implementation AirTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self delayContentTouches];
    }
    return self;
}

/*
 * Called instead of initWithStyle if cell comes from a storyboard
 * or nib file.
 *
 * Warning: Will not work if you need to access IBOutlet during custom initialization.
 */
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self delayContentTouches];
    }
    return self;
}

- (void)delayContentTouches {
    // iterate over all the UITableViewCell's subviews
    for (id view in self.subviews) {
        
        // looking for a UITableViewCellScrollView
        if ([NSStringFromClass([view class]) isEqualToString:@"UITableViewCellScrollView"]) {
            
            // this test is here for safety only, also there is no UITableViewCellScrollView in iOS8
            if([view isKindOfClass:[UIScrollView class]]) {
                
                // turn OFF delaysContentTouches in the hidden subview
                UIScrollView *scroll = (UIScrollView *) view;
                scroll.delaysContentTouches = NO;
            }
            break;
        }
    }
}

@end
