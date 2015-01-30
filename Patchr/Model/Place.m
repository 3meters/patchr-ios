#import "Place.h"
#import "ProviderMap.h"

@interface Place ()

// Private interface goes here.

@end

@implementation Place

+ (Place *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Place *)place
                          mappingNames:(BOOL)mapNames {
    place = (Place *)[Patch setPropertiesFromDictionary:dictionary onObject:place mappingNames:mapNames];
    
    place.address = dictionary[@"address"];
    place.city = dictionary[@"city"];
    place.region = dictionary[@"region"];
    place.country = dictionary[@"country"];
    place.postalCode = dictionary[@"postalCode"];
    place.phone = dictionary[@"phone"];
    place.applinkDate = dictionary[@"applinkDate"];
    
    if (dictionary[@"provider"]) {
        place.provider = [ProviderMap setPropertiesFromDictionary:dictionary[@"provider"] onObject:[ProviderMap insertInManagedObjectContext:place.managedObjectContext] mappingNames:mapNames];
    }
    return place;
}

@end
