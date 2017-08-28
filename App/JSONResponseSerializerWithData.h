//
//  JSONResponseSerializerWithData.h
//  Patchr
//
//  Courtesy of http://blog.gregfiumara.com/archives/239
//
//  Created by Rob MacEachern on 2015-01-21.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "AFNetworking/AFURLResponseSerialization.h"

// NSError userInfo key that will contain response data
FOUNDATION_EXPORT NSString *const JSONResponseSerializerWithDataKey;

@interface JSONResponseSerializerWithData : AFJSONResponseSerializer

@end
