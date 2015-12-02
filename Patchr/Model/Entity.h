#import "_Entity.h"

@interface Entity : _Entity {}

+ (Entity *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                               onObject:(Entity *)entity;

@end
