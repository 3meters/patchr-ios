//
//  ModelUtilities.m
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-04.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "ModelUtilities.h"
#import "User.h"
#import "Message.h"
#import "Place.h"

@implementation ModelUtilities

+ (Class)modelClassForSchema:(NSString *)schema {
    if ([schema isEqualToString:@"user"]) {
        return [User class];
    } else if ([schema isEqualToString:@"message"]) {
        return [Message class];
    } else if ([schema isEqualToString:@"place"]) {
        return [Place class];
    }
    NSLog(@"Unknown model class for schema %@", schema);
    return nil;
}

@end
