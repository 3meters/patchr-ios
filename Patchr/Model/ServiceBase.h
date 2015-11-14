#import "_ServiceBase.h"

@interface ServiceBase : _ServiceBase {}

+ (instancetype)fetchOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (instancetype)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (ServiceBase *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceBase *)base;

@end
