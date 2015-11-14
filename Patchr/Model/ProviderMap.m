#import "ProviderMap.h"

@interface ProviderMap ()

// Private interface goes here.

@end

@implementation ProviderMap

+ (ProviderMap *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ProviderMap *)providerMap
                                mappingNames:(BOOL)mapNames {
    
    providerMap.google = dictionary[@"google"];
    providerMap.googleReference = dictionary[@"googleReference"];
    
    return providerMap;
}

@end
