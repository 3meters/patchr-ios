#import "_Shortcut.h"

@interface Shortcut : _Shortcut {}

+ (Shortcut *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Shortcut *)shortcut
                          mappingNames:(BOOL)mapNames;

@end
