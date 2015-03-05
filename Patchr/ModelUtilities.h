//
//  ModelUtilities.h
//  Patchr
//
//  Created by Rob MacEachern on 2015-03-04.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelUtilities : NSObject

+ (Class)modelClassForSchema:(NSString *)schema;

@end
