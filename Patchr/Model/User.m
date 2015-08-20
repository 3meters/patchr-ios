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
    user.developer = dictionary[@"developer"];
    user.password = dictionary[@"password"];
    
    user.patchesOwnedValue = 0;
    user.patchesWatchingValue = 0;
    user.patchesLikesValue = 0;
    if ([dictionary[@"linkCount"] isKindOfClass:[NSDictionary class]]) {
        user.patchesOwned = [User countForStatWithType:@"create" schema:@"patches" enabled:@"true" direction:@"to" inLinkCounts:user.linkCounts];
        user.patchesWatching = [User countForStatWithType:@"watch" schema:@"patches" enabled:@"true" direction:@"to" inLinkCounts:user.linkCounts];
        user.patchesLikes = [User countForStatWithType:@"like" schema:@"patches" enabled:@"true" direction:@"to" inLinkCounts:user.linkCounts];
    }
    
    return user;
}

@end
