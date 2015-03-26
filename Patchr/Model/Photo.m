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
    
    if (dictionary[@"createdDate"]) {
        photo.createdDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"createdDate"] doubleValue]/1000];
    }
    
    return photo;
}

- (NSURL *)photoURL {
    if ([self.source isEqualToString:@"aircandi.images"] || [self.source isEqualToString:@"aircandi"]) {
        NSString *mediaImagesBaseURL = @"http://aircandi-images.s3.amazonaws.com/";
        NSString *path = [mediaImagesBaseURL stringByAppendingString:self.prefix];
        return [NSURL URLWithString:path];
    } else if ([self.source isEqualToString:@"aircandi.users"]) {
        NSString *mediaImagesBaseURL = @"http://aircandi-users.s3.amazonaws.com/";
        NSString *path = [mediaImagesBaseURL stringByAppendingString:self.prefix];
        return [NSURL URLWithString:path];
    } else {
        //NSLog(@"Unknown photo source: %@", self.source);
        return [NSURL URLWithString:self.prefix];
    }
}

@end
