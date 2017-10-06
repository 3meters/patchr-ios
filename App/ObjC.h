//
//  ObjC.h
//  Patchr
//
//  Created by Jay Massena on 8/12/17.
//  Copyright © 2017 3meters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
