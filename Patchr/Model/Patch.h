#import "_Patch.h"

@interface Patch : _Patch {}

+ (Patch *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                         onObject:(Patch *)patch
                     mappingNames:(BOOL)mapNames;

@end
