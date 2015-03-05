//
//  ModelUtilities.m
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-04.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "ModelUtilities.h"
#import "User.h"

@implementation ModelUtilities

+ (Class)modelClassForSchema:(NSString *)schema {
    if ([schema isEqualToString:@"user"]) {
        return [User class];
    }
    NSLog(@"Unknown model class for schema %@", schema);
    return nil;
}

@end
