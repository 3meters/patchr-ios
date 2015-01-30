#import "_ProviderMap.h"

@interface ProviderMap : _ProviderMap {}

+ (ProviderMap *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ProviderMap *)providerMap
                                mappingNames:(BOOL)mapNames;

@end
