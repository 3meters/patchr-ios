#import "User.h"

@interface User ()

// Private interface goes here.

@end

@implementation User

+ (User *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                             onObject:(User *)user
                         mappingNames:(BOOL)mapNames {
    user = (User *)[Entity setPropertiesFromDictionary:dictionary onObject:user mappingNames:mapNames];
    user.area = dictionary[@"area"];
    user.email = dictionary[@"email"];
    user.role = dictionary[@"role"];
    user.bio = dictionary[@"bio"];
    user.webUri = dictionary[@"webUri"];
    user.developer = dictionary[@"developer"];
    user.password = dictionary[@"password"];
    user.authSource = dictionary[@"authSource"];
    
    if ([dictionary[@"lastSignedInDate"] isKindOfClass:[NSNumber class]]) {
        user.lastSignedInDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"lastSignedInDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"valdiationDate"] isKindOfClass:[NSNumber class]]) {
        user.validationDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"validationDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"validationNotifyDate"] isKindOfClass:[NSNumber class]]) {
        user.validationNotifyDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"validationNotifyDate"] doubleValue]/1000];
    }
    
    return user;
}

@end
