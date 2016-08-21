#import "User.h"

@interface User ()

// Private interface goes here.

@end

@implementation User

+ (User *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                             onObject:(User *)user {
    
    user = (User *)[Entity setPropertiesFromDictionary:dictionary onObject:user];
	
    user.area = dictionary[@"area"];
    user.email = dictionary[@"email"];
    user.role = dictionary[@"role"];
    user.developer = dictionary[@"developer"];
    user.password = dictionary[@"password"];
    
    user.patchesOwnedValue = 0;
    user.patchesWatchingValue = 0;
	
	if ([dictionary[@"linkCounts"] isKindOfClass:[NSArray class]]) {
		for (id linkMap in dictionary[@"linkCounts"]) {
			if ([linkMap isKindOfClass:[NSDictionary class]]) {
				if ([linkMap[@"to"] isEqualToString:@"patches"] && [linkMap[@"type"] isEqualToString:@"create"]) {
					user.patchesOwned = linkMap[@"count"];
				}
				if ([linkMap[@"to"] isEqualToString:@"patches"] && [linkMap[@"type"] isEqualToString:@"watch"]) {
					user.patchesWatching = linkMap[@"count"];
				}
			}
		}
	}
	
    return user;
}

@end
