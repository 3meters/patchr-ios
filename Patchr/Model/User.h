#import "_User.h"

@interface User : _User {}

+ (User *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                             onObject:(User *)user;

@end
