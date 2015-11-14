#import "_Location.h"
#import <CoreLocation/CoreLocation.h>

@interface Location : _Location {}

+ (Location *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                 onObject:(Location *)location;


@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) CLLocation* cllocation;
@end
