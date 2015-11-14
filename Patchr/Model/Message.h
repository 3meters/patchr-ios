#import "_Message.h"

@interface Message : _Message {}

+ (Message *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                onObject:(Message *)message;

@end
