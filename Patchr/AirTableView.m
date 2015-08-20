//
//  AirTableView.m
//  Patchr
//
//  Created by Jay Massena on 5/8/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "AirTableView.h"

// From: http://stackoverflow.com/questions/19256996/uibutton-not-showing-highlight-on-tap-in-ios7/26049216#26049216

@implementation AirTableView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self delayContentTouches];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self delayContentTouches];
    }
    return self;
}

-(void)delayContentTouches {
    // iterate over all the UITableView's subviews
    for (id view in self.subviews) {
        
        // looking for a UITableViewWrapperView
        if ([NSStringFromClass([view class]) isEqualToString:@"UITableViewWrapperView"]) {
            
            // this test is necessary for safety and because a "UITableViewWrapperView" is NOT a UIScrollView in iOS7
            if([view isKindOfClass:[UIScrollView class]]) {
                
                // turn OFF delaysContentTouches in the hidden subview
                UIScrollView *scroll = (UIScrollView *) view;
                scroll.delaysContentTouches = NO;
            }
            break;
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSArray *sortedIndexPaths = [[self indexPathsForVisibleRows] sortedArrayUsingSelector:@selector(compare:)];
    for (NSIndexPath *path in sortedIndexPaths) {
        UITableViewCell *cell = [self cellForRowAtIndexPath:path];
        [self bringSubviewToFront:cell];
    }
}

-(void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    // UIScrollView responds strangely when a textfield becomes first responder
    // http://stackoverflow.com/a/12640831/2247399
    return;
}

-(void)scrollToNearestSelectedRowAtScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    return;
}

-(void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    return;
}

@end
