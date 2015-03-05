#import "_ServiceBase.h"

@interface ServiceBase : _ServiceBase {}

+ (id)fetchOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (id)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (ServiceBase *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceBase *)base
                                mappingNames:(BOOL)mapNames;

@end
