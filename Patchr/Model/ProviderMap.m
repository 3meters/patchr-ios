#import "ProviderMap.h"

@interface ProviderMap ()

// Private interface goes here.

@end

@implementation ProviderMap

+ (ProviderMap *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ProviderMap *)providerMap
                                mappingNames:(BOOL)mapNames {
    
    providerMap.aircandi = dictionary[@"aircandi"];
    providerMap.foursquare = dictionary[@"foursquare"];
    providerMap.yelp = dictionary[@"yelp"];
    providerMap.google = dictionary[@"google"];
    providerMap.googleReference = dictionary[@"googleReference"];
    providerMap.factual = dictionary[@"factual"];
    
    return providerMap;
}

@end
