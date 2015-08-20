#import "_Photo.h"

@interface Photo : _Photo {}

+ (Photo *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Photo *)photo
                          mappingNames:(BOOL)mapNames;

@end
