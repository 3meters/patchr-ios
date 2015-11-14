#import "Place.h"

@interface Place ()

// Private interface goes here.

@end

@implementation Place

+ (Place *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Place *)place {
    
    place = (Place *)[Entity setPropertiesFromDictionary:dictionary onObject:place];
    
    place.address = dictionary[@"address"];
    place.city = dictionary[@"city"];
    place.region = dictionary[@"region"];
    place.country = dictionary[@"country"];
    place.postalCode = dictionary[@"postalCode"];
    place.phone = dictionary[@"phone"];
    
    return place;
}

@end
