#import "Notification.h"
#import "Photo.h"

@interface Notification ()

// Private interface goes here.

@end

@implementation Notification

+ (Notification *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                     onObject:(Notification *)notification
                                 mappingNames:(BOOL)mapNames {
    notification = (Notification *)[Entity setPropertiesFromDictionary:dictionary onObject:notification mappingNames:mapNames];
    notification.targetId = dictionary[@"targetId"] ? dictionary[@"targetId"] : dictionary[@"_target"];
    notification.parentId = dictionary[@"parentId"] ? dictionary[@"parentId"] : dictionary[@"_parent"];
    notification.userId = dictionary[@"userId"] ? dictionary[@"userId"] : dictionary[@"_user"];
    
    if ([dictionary[@"sentDate"] isKindOfClass:[NSNumber class]]) {
        notification.sentDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"sentDate"] doubleValue]/1000];
    }
    
    notification.priority = dictionary[@"priority"];
    notification.trigger = dictionary[@"trigger"];
    notification.summary = dictionary[@"summary"];
    notification.event = dictionary[@"event"];
    notification.ticker = dictionary[@"ticker"];
    
    if (dictionary[@"photoBig"] && notification.managedObjectContext) {
        notification.photoBig = [Photo setPropertiesFromDictionary:dictionary[@"photoBig"] onObject:[Photo insertInManagedObjectContext:notification.managedObjectContext] mappingNames:mapNames];
    }
    
    return notification;
}

@end
