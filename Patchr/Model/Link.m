#import "Link.h"

@interface Link ()

// Private interface goes here.

@end

@implementation Link

+ (instancetype)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                   onObject:(Link *)link
                               mappingNames:(BOOL)mapNames {
        
    link.id_ = (mapNames && dictionary[@"_id"]) ? dictionary[@"_id"] : dictionary[@"id"];
    link.type = dictionary[@"type"];
    link.toSchema = dictionary[@"toSchema"];
    link.toId = dictionary[@"_to"];
    link.fromSchema = dictionary[@"fromSchema"];
    link.fromId = dictionary[@"_from"];
    link.enabled = [dictionary[@"enabled"] isKindOfClass:[NSNumber class]] ? dictionary[@"enabled"] : link.enabled;
    
    return link;
}

@end
