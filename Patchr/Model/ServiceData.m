//
//  ServiceData.m
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-27.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "ServiceData.h"

@implementation ServiceData

+ (ServiceData *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceData *)serviceData {
    
    serviceData.count = dictionary[@"count"];
    serviceData.date = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"date"] doubleValue]/1000];
    serviceData.more = dictionary[@"more"];
    serviceData.time = dictionary[@"time"];
    
    if ([dictionary[@"data"] isEqual:[NSNull null]]) {
        /* We rely on a tenuous NULL indicator that the call failed the query parameter */
        serviceData.noopValue = YES;
    }
    else if ([dictionary[@"data"] isKindOfClass:[NSDictionary class]]) {
        /* Wrap the object in an array to simplify handling later on */
        serviceData.data = [NSArray arrayWithObject:dictionary[@"data"]];
    }
    else {
        /* Should be an array of objects */
        serviceData.data = dictionary[@"data"];
    }
	
	if ([dictionary[@"clientMinVersions"] isKindOfClass:[NSDictionary class]]) {
		NSDictionary *versionMap = dictionary[@"clientMinVersions"];
		if (versionMap[@"com.3meters.patchr.ios"] != nil) {
			serviceData.minBuild = versionMap[@"com.3meters.patchr.ios"];
		}
	}
	
    if ([dictionary[@"user"] isKindOfClass:[NSDictionary class]]) {
        serviceData.user = dictionary[@"user"];
    }
    
    if ([dictionary[@"session"] isKindOfClass:[NSDictionary class]]) {
        serviceData.session = dictionary[@"session"];
    }
    
    return serviceData;
}

- (int32_t)countValue {
    return self.count.intValue;
}

- (void)setCountValue:(int32_t)countValue {
    self.count = [NSNumber numberWithInt:countValue];
}

- (BOOL)moreValue {
    return self.more.boolValue;
}

- (void)setMoreValue:(BOOL)moreValue {
    self.more = [NSNumber numberWithBool:moreValue];
}

- (double)timeValue {
    return self.time.doubleValue;
}

- (void)setTimeValue:(double)timeValue {
    self.time = [NSNumber numberWithDouble:timeValue];
}

- (BOOL)noopValue {
    return self.noop.boolValue;
}

- (void)setNoopValue:(BOOL)noopValue {
    self.noop = [NSNumber numberWithBool:noopValue];
}

- (int32_t)minBuildValue {
	return self.minBuild.intValue;
}

- (void)setMinBuildValue:(int32_t)minBuildValue {
	self.minBuild = [NSNumber numberWithInt:minBuildValue];
}

@end
