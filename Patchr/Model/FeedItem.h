#import "_FeedItem.h"

@interface FeedItem : _FeedItem {}

+ (FeedItem *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                     onObject:(FeedItem *)feedItem;

@end
