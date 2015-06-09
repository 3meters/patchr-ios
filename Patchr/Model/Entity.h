#import "_Entity.h"

@interface Entity : _Entity {}

+ (Entity *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                               onObject:(Entity *)entity
                           mappingNames:(BOOL)mapNames;

+ (NSNumber *)countForStatWithType:(NSString *)type schema:(NSString *)schema enabled:(NSString *)enabled direction:(NSString *)direction inLinkCounts:(NSDictionary *)linkCounts;

// Convenience properties that query the linksInCounts (if they exist)
@property (readonly) NSNumber *numberOfMessages;

@end
