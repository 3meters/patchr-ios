#import "_Statistic.h"

@interface Statistic : _Statistic {}

// Maps to Count.java in Android project

+ (Statistic *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(Statistic *)stat
                                mappingNames:(BOOL)mapNames;

@end
