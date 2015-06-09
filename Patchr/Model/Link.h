#import "_Link.h"

@interface Link : _Link {}

+ (instancetype)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                   onObject:(Link *)link
                               mappingNames:(BOOL)mapNames;

@end
