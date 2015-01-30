#import "_Entity.h"

@interface Entity : _Entity {}

+ (Entity *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(Entity *)entity
                                mappingNames:(BOOL)mapNames;

// Convenience properties that query the linksInCounts (if they exist)
@property (readonly) NSNumber *numberOfLikes;
@property (readonly) NSNumber *numberOfWatchers;
@property (readonly) NSNumber *numberOfMessages;

@end
