#import "Patch.h"
#import "Link.h"
#import "Shortcut.h"

@interface Patch ()

// Private interface goes here.

@end

@implementation Patch

+ (Patch *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Patch *)patch {
    
    patch = (Patch *) [Entity setPropertiesFromDictionary:dictionary onObject:patch];

    patch.countMessagesValue = 0;
	
	if ([dictionary[@"linkCounts"] isKindOfClass:[NSArray class]]) {
		for (id linkMap in dictionary[@"linkCounts"]) {
			if ([linkMap isKindOfClass:[NSDictionary class]]) {
				if ([linkMap[@"from"] isEqualToString:@"messages"] && [linkMap[@"type"] isEqualToString:@"content"]) {
					patch.countMessages = linkMap[@"count"];
				}
			}
		}
	}
		
    patch.userWatchStatusValue = PAWatchStatusNonMember;  // Default for convenience property
    patch.userWatchMutedValue = NO;
    patch.userWatchId = nil;
    patch.userLikesValue = NO;
    patch.userLikesId = nil;
    patch.userHasMessagedValue = NO;
    
    if ([dictionary[@"links"] isKindOfClass:[NSArray class]]) {
        for (id linkMap in dictionary[@"links"]) {
            if ([linkMap isKindOfClass:[NSDictionary class]]) {
                
                if ([linkMap[@"fromSchema"] isEqualToString:@"message"] && [linkMap[@"type"] isEqualToString:@"content"]) {
                    patch.userHasMessagedValue = YES;
                }
                else if ([linkMap[@"fromSchema"] isEqualToString:@"user"] && [linkMap[@"type"] isEqualToString:@"watch"]) {
                    patch.userWatchId = linkMap[@"_id"];
                    patch.userWatchStatusValue = PAWatchStatusPending;
                    if ([[linkMap objectForKey:@"enabled"]boolValue] == YES) {
                        patch.userWatchStatusValue = PAWatchStatusMember;
                    }
                    if ([[linkMap objectForKey:@"mute"]boolValue] == YES) {
                        patch.userWatchMutedValue = YES;
                    }
                }
            }
        }
    }

    return patch;
}

@end
