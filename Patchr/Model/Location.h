#import "_Location.h"

@interface Location : _Location {}

+ (Location *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                 onObject:(Location *)location
                             mappingNames:(BOOL)mapNames;

@end
