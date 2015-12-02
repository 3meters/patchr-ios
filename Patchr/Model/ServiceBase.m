#import "ServiceBase.h"
#import "ModelUtilities.h"
#import "User.h"
#import "Shortcut.h"

@interface ServiceBase ()

// Private interface goes here.

@end

@implementation ServiceBase

/*
 * The routines to fetch an object from the data model are handled here for 
 * all subclasses of ServiceBase.
 */

+ (id)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    /*
     * Fetch this object from the data model. If this object is not in the data model yet then add it.
     */
    ServiceBase *item = [[self class] fetchOneById:id_ inManagedObjectContext:managedObjectContext];
    if (!item) {
        item = [[self class] insertInManagedObjectContext:managedObjectContext];
        item.id_ = id_;
    }
    return item;
}

+ (id)fetchOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    /*
     * Fetch this object instance from the data model using id_ as the predicate key. Sort descriptor is required
     * but we only expect to get back and return one.
     */
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:ServiceBaseAttributes.id_ ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", ServiceBaseAttributes.id_, id_];
    
    NSError *error;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(!error, @"Error fetching MediaItem");
    id item = [results firstObject];
    return item;
}

+ (ServiceBase *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceBase *)base {
    
	base.id_ = (dictionary[@"_id"] != nil) ? dictionary[@"_id"] : dictionary[@"id"];
    base.name = dictionary[@"name"];
    base.schema = dictionary[@"schema"];
    base.type = dictionary[@"type"];
    base.ownerId = dictionary[@"_owner"];
    base.creatorId = dictionary[@"_creator"];
    base.modifierId = dictionary[@"_modifier"];
    
    base.createdDate = nil;
    base.modifiedDate = nil;
    base.activityDate = nil;
    base.sortDate = nil;
    
    if ([dictionary[@"createdDate"] isKindOfClass:[NSNumber class]]) {
        base.createdDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"createdDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"modifiedDate"] isKindOfClass:[NSNumber class]]) {
        base.modifiedDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"modifiedDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"activityDate"] isKindOfClass:[NSNumber class]]) {
        base.activityDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"activityDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"sortDate"] isKindOfClass:[NSNumber class]]) {
        base.sortDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"sortDate"] doubleValue]/1000];
    }
	
	/* Delete the related objects if they exist */
	NSManagedObjectContext *context = [base managedObjectContext];
	if (base.creator != nil) {
		[context deleteObject:base.creator];
	}
	
	if (dictionary[@"creator"]) {
		if ([dictionary[@"creator"] isKindOfClass:[NSDictionary class]]) {
			NSDictionary *linkMap = dictionary[@"creator"];
		
			NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Shortcut" inManagedObjectContext:context];
			Shortcut *shortcut = [[Shortcut alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
			
			NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
			if ([entityId rangeOfString:@"sh."].location == NSNotFound) {
				entityId = [@"sh." stringByAppendingString:entityId];
			}
			shortcut.id_ = entityId;
			base.creator = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut];
		}
	}
	
    return base;
}

@end