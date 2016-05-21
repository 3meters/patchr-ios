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
	entity.countPendingValue = 0;
	
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
    
	if ([dictionary[@"linkCounts"] isKindOfClass:[NSArray class]]) {
		for (id linkMap in dictionary[@"linkCounts"]) {
			if ([linkMap isKindOfClass:[NSDictionary class]]) {
				
				if ([linkMap[@"from"] isEqualToString:@"users"] && [linkMap[@"type"] isEqualToString:@"like"]) {
					entity.countLikes = linkMap[@"count"];
				}
				if ([linkMap[@"from"] isEqualToString:@"users"] && [linkMap[@"type"] isEqualToString:@"watch"] && [linkMap[@"enabled"] isEqual:@YES]) {
					entity.countWatching = linkMap[@"count"];
				}
				if ([linkMap[@"from"] isEqualToString:@"users"] && [linkMap[@"type"] isEqualToString:@"watch"] && [linkMap[@"enabled"] isEqual:@NO]) {
					entity.countPending = linkMap[@"count"];
				}
			}
		}
	}
    
    entity.reason = dictionary[@"reason"];
    entity.score = dictionary[@"score"];
    entity.visibility = dictionary[@"visibility"];
	entity.locked = dictionary[@"locked"];
    
    if (dictionary[@"link"]) {
		/* 
		 * This is the only place that uses the Link object. We use it to support watch link state and management.
		 * Will get pulled in on a user for a list of users watching a patch and on patches when showing patches a
		 * user is watching (let's us show that a watch request is pending/approved).
		 */
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Link" inManagedObjectContext:context];
		Link *link = [[Link alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
		entity.link = [Link setPropertiesFromDictionary:dictionary[@"link"] onObject:link];
    }
    
    return entity;
}

@end
