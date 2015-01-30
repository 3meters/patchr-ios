#import "_Place.h"

@interface Place : _Place {}

+ (Place *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                         onObject:(Place *)place
                     mappingNames:(BOOL)mapNames;

@end
