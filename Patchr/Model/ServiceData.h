//
//  ServiceData.h
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import <Foundation/Foundation.h>

// Note: This is not currently an NSManagedObject

@interface ServiceData : NSObject

@property (nonatomic, strong) NSNumber *count;
@property (nonatomic, strong) id data; // NSArray or NSDictionary
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *more;
@property (nonatomic, strong) NSNumber *time;
@property (nonatomic, strong) NSNumber *noop;

@property (atomic, setter=setCountValue:) int32_t countValue;
@property (atomic, setter=setMoreValue:) BOOL moreValue;
@property (atomic, setter=setTimeValue:) double timeValue;
@property (atomic, setter=setNoopValue:) BOOL noopValue;

+ (ServiceData *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceData *)serviceData
                                mappingNames:(BOOL)mapNames;

@end
