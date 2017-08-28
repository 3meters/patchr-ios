//
//  JSONResponseSerializerWithData.m
//  Patchr
//
//  Created by Rob MacEachern on 2015-01-21.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import "JSONResponseSerializerWithData.h"

NSString *const JSONResponseSerializerWithDataKey = @"JSONResponseSerializerWithDataKey";

@implementation JSONResponseSerializerWithData

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    id JSONObject = [super responseObjectForResponse:response data:data error:error];
    if (*error != nil) {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        if (data != nil) {
            id responseJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            userInfo[JSONResponseSerializerWithDataKey] = responseJSON;
        }
        NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
        (*error) = newError;
    }
    
    return (JSONObject);
}
@end
