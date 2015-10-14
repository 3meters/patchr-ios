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
                                    onObject:(ServiceBase *)base
                                mappingNames:(BOOL)mapNames {
    
    base.id_ = (mapNames && dictionary[@"_id"]) ? dictionary[@"_id"] : dictionary[@"id"];
    base.name = dictionary[@"name"];
    base.schema = dictionary[@"schema"];
    base.type = dictionary[@"type"];
    base.locked = dictionary[@"locked"];
    base.position = dictionary[@"position"];
    base.ownerId = (mapNames && dictionary[@"_owner"]) ? dictionary[@"_owner"] : dictionary[@"owner"];
    base.creatorId = (mapNames && dictionary[@"_creator"]) ? dictionary[@"_creator"] : dictionary[@"creator"];
    base.modifierId = (mapNames && dictionary[@"_modifier"]) ? dictionary[@"_modifier"] : dictionary[@"modifier"];
    
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
    
    base.creator = nil;
    if (dictionary[@"linked"]) {
        for (id linkMap in dictionary[@"linked"]) {
            if ([linkMap isKindOfClass:[NSDictionary class]]) {
                if ([linkMap[@"schema"] isEqual: @"user"] && [linkMap[@"_id"] isEqual: base.creatorId]) {
					NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
					if ([entityId rangeOfString:@"sh."].location == NSNotFound) {
						entityId = [@"sh." stringByAppendingString:entityId];
					}
					id shortcut = [Shortcut fetchOrInsertOneById:entityId inManagedObjectContext:base.managedObjectContext];
					base.creator = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut mappingNames:mapNames];
                }
            }
        }
    }
    
    return base;
}

@end