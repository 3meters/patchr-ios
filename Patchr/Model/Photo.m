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
    // TODO complete implementation is quite complicated. See Photo.java in Android project
    if ([self.source isEqualToString:@"aircandi.images"]) {
        NSString *mediaImagesBaseURL = @"http://aircandi-images.s3.amazonaws.com/";
        NSString *path = [mediaImagesBaseURL stringByAppendingString:self.prefix];
        return [NSURL URLWithString:path];
    } else {
        NSLog(@"Unknown photo source: %@", self.source);
    }
    return nil;
}

@end
