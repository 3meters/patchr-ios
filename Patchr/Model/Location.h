#import "_Location.h"
#import <CoreLocation/CoreLocation.h>

@interface Location : _Location {}

+ (Location *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                 onObject:(Location *)location
                             mappingNames:(BOOL)mapNames;


@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end
