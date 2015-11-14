#import "_Photo.h"

@interface Photo : _Photo {}

+ (instancetype)fetchOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (instancetype)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (Photo *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Photo *)photo;

@end
