#import "PALink.h"

@interface PALink ()

// Private interface goes here.

@end

@implementation PALink

+ (instancetype)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                   onObject:(PALink *)link
                               mappingNames:(BOOL)mapNames {
    
    link = (PALink *)[ServiceBase setPropertiesFromDictionary:dictionary onObject:link mappingNames:mapNames];
    link.toSchema = dictionary[@"toSchema"];
    link.toId = dictionary[@"_to"];
    link.fromSchema = dictionary[@"fromSchema"];
    link.fromId = dictionary[@"_from"];
    link.enabled = [dictionary[@"enabled"] isKindOfClass:[NSNumber class]] ? dictionary[@"enabled"] : link.enabled;
    
    return link;
}

@end
