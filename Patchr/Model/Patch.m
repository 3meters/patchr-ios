#import "Patch.h"
#import "PACategory.h"
#import "Place.h"

@interface Patch ()

// Private interface goes here.

@end

@implementation Patch

+ (Patch *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Patch *)patch
                          mappingNames:(BOOL)mapNames {
    patch = (Patch *) [Entity setPropertiesFromDictionary:dictionary onObject:patch mappingNames:mapNames];
    
    if (dictionary[@"category"]) {
        patch.category = [PACategory setPropertiesFromDictionary:dictionary[@"category"] onObject:[PACategory insertInManagedObjectContext:patch.managedObjectContext] mappingNames:mapNames];
    }
    
    if (dictionary[@"place"]) {
        patch.place = [Place setPropertiesFromDictionary:dictionary[@"place"] onObject:[Place insertInManagedObjectContext:patch.managedObjectContext] mappingNames:mapNames];
    }
    
    // Note: Doesn't seem like signalFence is currently in use
    
    return patch;
}

@end
