#import "Statistic.h"

@interface Statistic ()

// Private interface goes here.

@end

@implementation Statistic

+ (Statistic *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                  onObject:(Statistic *)stat
                              mappingNames:(BOOL)mapNames {
    stat.type = dictionary[@"type"];
    
    if (stat.type == nil && dictionary[@"event"]) {
        stat.type = dictionary[@"event"];
    }
    
    stat.schema = dictionary[@"schema"];
    stat.enabled = dictionary[@"enabled"];
    stat.count = dictionary[@"count"];
    
    if (stat.count == nil && dictionary[@"countBy"]) {
        stat.count = dictionary[@"countBy"];
    }
    
    return stat;
}

@end
