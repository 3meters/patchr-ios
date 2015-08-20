#import "Photo.h"

@interface Photo ()

// Private interface goes here.

@end

@implementation Photo

+ (Photo *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Photo *)photo
                          mappingNames:(BOOL)mapNames {
    
    photo.prefix = dictionary[@"prefix"];
    photo.suffix = dictionary[@"suffix"];
    photo.width = dictionary[@"width"];
    photo.height = dictionary[@"height"];
    photo.source = dictionary[@"source"];
    
    photo.createdDate = nil;
    if (dictionary[@"createdDate"]) {
        photo.createdDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"createdDate"] doubleValue]/1000];
    }
    
    return photo;
}

@end
