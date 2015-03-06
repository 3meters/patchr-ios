#import "Location.h"


@interface Location ()

// Private interface goes here.

@end

@implementation Location

+ (Location *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                 onObject:(Location *)location
                             mappingNames:(BOOL)mapNames {
    location.lat = dictionary[@"lat"];
    location.lng = dictionary[@"lng"];
    location.altitude = dictionary[@"altitude"];
    location.accuracy = dictionary[@"accuracy"];
    location.bearing = dictionary[@"bearing"];
    location.speed = dictionary[@"speed"];
    location.provider = dictionary[@"provider"];
    return location;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latValue, self.lngValue);
}

@end
