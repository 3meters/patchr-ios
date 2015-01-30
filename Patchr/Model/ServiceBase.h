#import "_ServiceBase.h"

@interface ServiceBase : _ServiceBase {}

+ (ServiceBase *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceBase *)base
                                mappingNames:(BOOL)mapNames;

@end
