#import "Entity.h"
#import "Photo.h"
#import "Location.h"
#import "Link.h"
#import <CoreLocation/CoreLocation.h>

@interface Entity ()

// Private interface goes here.

@end

@implementation Entity



+ (Entity *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                               onObject:(Entity *)entity {
    
    entity = (Entity *)[ServiceBase setPropertiesFromDictionary:dictionary onObject:entity];
    
    entity.subtitle = dictionary[@"subtitle"];
    entity.description_ = dictionary[@"description"];
    entity.patchId = dictionary[@"_acl"];
	
	/* Delete the related objects if they exist */
	NSManagedObjectContext *context = [entity managedObjectContext];
	if (entity.photo != nil) {
		[context deleteObject:entity.photo];
	}
	if (entity.location != nil) {
		[context deleteObject:entity.location];
	}
	if (entity.link != nil) {
		[context deleteObject:entity.link];
	}

    entity.countLikesValue = 0;
    entity.countWatchingValue = 0;
	
    if (dictionary[@"photo"]) {
		/* We always replace the previous photo object if one existed */
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
		Photo *photo = [[Photo alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
		entity.photo = [Photo setPropertiesFromDictionary:dictionary[@"photo"] onObject:photo];	// Sets id_
    }

    if (dictionary[@"location"]) {
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:context];
		Location *location = [[Location alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        entity.location = [Location setPropertiesFromDictionary:dictionary[@"location"] onObject:location];
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
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Link" inManagedObjectContext:context];
		Link *link = [[Link alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
		entity.link = [Link setPropertiesFromDictionary:dictionary[@"link"] onObject:link];
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
