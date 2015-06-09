#import "Entity.h"
#import "Photo.h"
#import "Location.h"
#import "Link.h"
#import "Patchr-Swift.h"
#import <CoreLocation/CoreLocation.h>

@interface Entity ()

// Private interface goes here.

@end

@implementation Entity

+ (Entity *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                               onObject:(Entity *)entity
                           mappingNames:(BOOL)mapNames {
    
    entity = (Entity *)[ServiceBase setPropertiesFromDictionary:dictionary onObject:entity mappingNames:mapNames];
    
    entity.subtitle = dictionary[@"subtitle"];
    entity.description_ = dictionary[@"description"];
    entity.patchId = mapNames ? dictionary[@"_acl"] : dictionary[@"patchId"];
    
    entity.photo = nil;
    entity.location = nil;
    entity.countLikesValue = 0;
    entity.countWatchingValue = 0;
    entity.link = nil;
    
    if (dictionary[@"photo"]) {
        entity.photo = [Photo setPropertiesFromDictionary:dictionary[@"photo"] onObject:[Photo insertInManagedObjectContext:entity.managedObjectContext] mappingNames:mapNames];
    }

    if (dictionary[@"location"]) {
        entity.location = [Location setPropertiesFromDictionary:dictionary[@"location"] onObject:[Location insertInManagedObjectContext:entity.managedObjectContext] mappingNames:mapNames];
        CLLocation *currentLocation = [LocationController.instance getLocation];
        if (currentLocation != NULL){
            CLLocation *location = [[CLLocation alloc] initWithLatitude:entity.location.latValue longitude:entity.location.lngValue];
            entity.distanceValue = [currentLocation distanceFromLocation:location];
        }
    }
    
    entity.linkCounts = dictionary[@"linkCount"];
    
    if ([dictionary[@"linkCount"] isKindOfClass:[NSDictionary class]]) {
        entity.countLikes = [Entity countForStatWithType:@"like" schema:@"users" enabled:@"true" direction:@"from" inLinkCounts:entity.linkCounts];
        entity.countWatching = [Entity countForStatWithType:@"watch" schema:@"users" enabled:@"true" direction:@"from" inLinkCounts:entity.linkCounts];
        entity.countPending = [Entity countForStatWithType:@"watch" schema:@"users" enabled:@"false" direction:@"from" inLinkCounts:entity.linkCounts];
    }
    
    entity.reason = dictionary[@"reason"];
    entity.score = dictionary[@"score"];
    entity.count = dictionary[@"count"];
    entity.rank = dictionary[@"rank"];
    entity.visibility = dictionary[@"visibility"];
    
    if (dictionary[@"link"]) {
        entity.link = [Link setPropertiesFromDictionary:dictionary[@"link"]
                                                 onObject:[Link insertInManagedObjectContext:entity.managedObjectContext]
                                             mappingNames:mapNames];
    }
    
    return entity;
}

- (NSNumber *)numberOfMessages {
    return [self countForStatWithType:@"content" schema:@"messages"];
}

// Internal only
- (NSNumber *)countForStatWithType:(NSString *)type schema:(NSString *)schema {
    return [Entity countForStatWithType:type schema:schema enabled:@"true" direction:@"from" inLinkCounts:self.linkCounts];
}

// Internal only
+ (NSNumber *)countForStatWithType:(NSString *)type
                            schema:(NSString *)schema
                           enabled:(NSString *)enabled
                         direction:(NSString *)direction
                      inLinkCounts:(NSDictionary *)linkCounts {
    
    if ([linkCounts[direction] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *fromLinkCounts = linkCounts[direction];
        for (NSObject *key in fromLinkCounts.allKeys) {
            if ([key isEqual:schema] && [fromLinkCounts[key] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *schemaDict = fromLinkCounts[key];
                if ([schemaDict[type] isKindOfClass:[NSNumber class]]) {
                    return schemaDict[type];
                }
                else if ([schemaDict[type] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *typeDict = schemaDict[type];
                    if ([enabled isEqualToString:@"true"]) {
                        return typeDict[@"enabled"];
                    }
                    else if ([enabled isEqualToString:@"false"]) {
                        return typeDict[@"disabled"];
                    }
                }
            }
        }
    }
    return nil; // Not found
}

@end
