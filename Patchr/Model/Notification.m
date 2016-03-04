#import "Notification.h"
#import "Photo.h"

@interface Notification ()

// Private interface goes here.

@end

@implementation Notification

+ (Notification *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                     onObject:(Notification *)notification {
    
    notification = (Notification *)[Entity setPropertiesFromDictionary:dictionary onObject:notification];
    notification.targetId = dictionary[@"targetId"] ? dictionary[@"targetId"] : dictionary[@"_target"];
    notification.parentId = dictionary[@"parentId"] ? dictionary[@"parentId"] : dictionary[@"_parent"];
    notification.userId = dictionary[@"userId"] ? dictionary[@"userId"] : dictionary[@"_user"];
    
    notification.sentDate = nil;
    if ([dictionary[@"sentDate"] isKindOfClass:[NSNumber class]]) {
        notification.sentDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"sentDate"] doubleValue]/1000];
    }
    
    notification.priority = dictionary[@"priority"];
    notification.trigger = dictionary[@"trigger"];
	notification.summary = dictionary[@"summary"];	// can have html markup	
    notification.event = dictionary[@"event"];
    notification.ticker = dictionary[@"ticker"];
    
    notification.photoBig = nil;
    if (dictionary[@"photoBig"] && notification.managedObjectContext) {
        notification.photoBig = [Photo setPropertiesFromDictionary:dictionary[@"photoBig"] onObject:[Photo insertInManagedObjectContext:notification.managedObjectContext]];
    }
    
    return notification;
}

#pragma mark Private Internal

+ (NSString *)stringByStrippingHTMLFromString:(NSString *)string {
    NSRange range;
    while ((range = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        string = [string stringByReplacingCharactersInRange:range withString:@""];
    return string;
}

@end
