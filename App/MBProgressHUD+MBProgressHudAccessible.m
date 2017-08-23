//
//  MBProgressHUD+MBProgressHudAccessible.m
//  TIPAReader
//
//  Created by Rui Batista on 18/06/13.
//  Copyright (c) 2013 Tiflotecnia, LDa. All rights reserved.
//

#import "MBProgressHUD+MBProgressHudAccessible.h"

@implementation MBProgressHUD (MBProgressHudAccessible)

- (NSString *)accessibilityValue {
	if(self.mode == MBProgressHUDModeAnnularDeterminate || self.mode == MBProgressHUDModeDeterminate) {
		return [NSString stringWithFormat:@"%.0f%%", self.progress * 100];
	}
	return nil;
}

- (NSString *) accessibilityLabel {
	NSMutableString *buffer = [[NSMutableString alloc] init];
	if(self.labelText) {
		[buffer appendString:self.labelText];
	}
	if(self.detailsLabelText) {
		[buffer appendFormat:@",%@", self.detailsLabelText, nil];
	}

	return [NSString stringWithString:buffer];
}

- (BOOL) isAccessibilityElement {
	return YES;
}

- (UIAccessibilityTraits) accessibilityTraits {
	return UIAccessibilityTraitUpdatesFrequently;
}

- (CGRect) accessibilityFrame {
	return self.frame;
}

@end
