#import "_PACategory.h"

@interface PACategory : _PACategory {}

+ (PACategory *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                   onObject:(PACategory *)category
                               mappingNames:(BOOL)mapNames;

@end
