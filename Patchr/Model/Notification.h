#import "_Notification.h"

@interface Notification : _Notification {}

+ (Notification *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                     onObject:(Notification *)notification
                                 mappingNames:(BOOL)mapNames;

@end
