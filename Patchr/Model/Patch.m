#import "Patch.h"
#import "Link.h"
#import "Shortcut.h"
#import "Patchr-Swift.h"

@interface Patch ()

// Private interface goes here.

@end

@implementation Patch

+ (Patch *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Patch *)patch
                          mappingNames:(BOOL)mapNames {
    
    patch = (Patch *) [Entity setPropertiesFromDictionary:dictionary onObject:patch mappingNames:mapNames];

    patch.countMessagesValue = 0;
    if (dictionary[@"linkCount"]) {
        patch.countMessages = [Entity countForStatWithType:@"content" schema:@"messages" enabled:@"true" direction:@"from" inLinkCounts:dictionary[@"linkCount"]];
    }
    
    patch.place = nil;
    if (dictionary[@"linked"]) {
        for (id linkMap in dictionary[@"linked"]) {
            if ([linkMap isKindOfClass:[NSDictionary class]]) {
                if ([linkMap[@"schema"] isEqualToString: @"place"]) {
                    NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
                    NSString *decoratedId = [Shortcut decorateId:entityId];
                    id shortcut = [Shortcut fetchOrInsertOneById:decoratedId inManagedObjectContext:patch.managedObjectContext];
                    patch.place = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut mappingNames:mapNames];
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
                else if ([linkMap[@"fromSchema"] isEqualToString:@"user"] && [linkMap[@"type"] isEqualToString:@"like"]) {
                    patch.userLikesId = linkMap[@"_id"];
                    patch.userLikesValue = YES;
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
