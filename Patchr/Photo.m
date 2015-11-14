#import "Photo.h"

@interface Photo ()

// Private interface goes here.

@end

@implementation Photo

+ (id)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	/*
	 * Fetch this object from the data model. If this object is not in the data model yet then add it.
	 */
	Photo *item = [[self class] fetchOneById:id_ inManagedObjectContext:managedObjectContext];
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
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:PhotoAttributes.id_ ascending:NO];
	fetchRequest.sortDescriptors = @[sortDescriptor];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", PhotoAttributes.id_, id_];
	
	NSError *error;
	NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	NSAssert(!error, @"Error fetching Photo managed object");
	id item = [results firstObject];
	return item;
}

+ (Photo *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Photo *)photo
                          mappingNames:(BOOL)mapNames {
    
	photo.id_ = dictionary[@"prefix"];
    photo.prefix = dictionary[@"prefix"];
    photo.suffix = dictionary[@"suffix"];
    photo.width = dictionary[@"width"];
    photo.height = dictionary[@"height"];
    photo.source = dictionary[@"source"];
    
    photo.createdDate = nil;
    if (dictionary[@"createdDate"]) {
        photo.createdDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"createdDate"] doubleValue]/1000];
    }
    
    return photo;
}

@end
