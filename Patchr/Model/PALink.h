#import "_PALink.h"

@interface PALink : _PALink {}

+ (instancetype)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(PALink *)link
                          mappingNames:(BOOL)mapNames;

@end
