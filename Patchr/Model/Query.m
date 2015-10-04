#import "Query.h"

@interface Query ()

// Private interface goes here.

@end

@implementation Query

/*
 * The routines to fetch an object from the data model are handled here for
 * all subclasses of ServiceBase.
 */

+ (id)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    /*
     * Fetch this object from the data model. If this object is not in the data model yet then add it.
     */
    Query *item = [[self class] fetchOneById:id_ inManagedObjectContext:managedObjectContext];
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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:QueryAttributes.id_ ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", QueryAttributes.id_, id_];
    
    NSError *error;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(!error, @"Error fetching Query managed object");
    id item = [results firstObject];
    return item;
}

@end
