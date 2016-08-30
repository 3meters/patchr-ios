#import "FeedItem.h"
#import "Photo.h"

@interface FeedItem ()

// Private interface goes here.

@end

@implementation FeedItem

+ (FeedItem *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                     onObject:(FeedItem *)feedItem {
    
    feedItem = (FeedItem *)[Entity setPropertiesFromDictionary:dictionary onObject:feedItem];
    feedItem.targetId = dictionary[@"targetId"] ? dictionary[@"targetId"] : dictionary[@"_target"];
    feedItem.parentId = dictionary[@"parentId"] ? dictionary[@"parentId"] : dictionary[@"_parent"];
    feedItem.userId = dictionary[@"userId"] ? dictionary[@"userId"] : dictionary[@"_user"];
    
    feedItem.sentDate = nil;
    if ([dictionary[@"sentDate"] isKindOfClass:[NSNumber class]]) {
        feedItem.sentDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"sentDate"] doubleValue]/1000];
    }
    
    feedItem.priority = dictionary[@"priority"];
    feedItem.trigger = dictionary[@"trigger"];
	feedItem.summary = dictionary[@"summary"];	// can have html markup
    feedItem.event = dictionary[@"event"];
    feedItem.ticker = dictionary[@"ticker"];
    
    feedItem.photoBig = nil;
    if (dictionary[@"photoBig"] && feedItem.managedObjectContext) {
        feedItem.photoBig = [Photo setPropertiesFromDictionary:dictionary[@"photoBig"] onObject:[Photo insertInManagedObjectContext:feedItem.managedObjectContext]];
    }
    
    return feedItem;
}

#pragma mark Private Internal

+ (NSString *)stringByStrippingHTMLFromString:(NSString *)string {
    NSRange range;
    while ((range = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        string = [string stringByReplacingCharactersInRange:range withString:@""];
    return string;
}

@end
