#import "_Query.h"

@interface Query : _Query {}

+ (instancetype)fetchOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (instancetype)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
