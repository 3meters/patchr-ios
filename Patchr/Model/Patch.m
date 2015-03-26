#import "Patch.h"
#import "PACategory.h"
#import "Place.h"
#import "Message.h"

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
    
    if ([dictionary[@"linked"] isKindOfClass:[NSArray class]]) {
        // Configure patch-specific relationships
        
        for (id link in dictionary[@"linked"]) {
            if ([link isKindOfClass:[NSDictionary class]]) {
                NSDictionary *linkDictionary = link;
                if ([linkDictionary[@"schema"] isEqualToString:@"message"]) {
                    Message *message = [Message fetchOrInsertOneById:linkDictionary[@"_id"] inManagedObjectContext:patch.managedObjectContext];
                    message = [Message setPropertiesFromDictionary:linkDictionary onObject:message mappingNames:mapNames];
                    [patch.messagesSet addObject:message];
                } else {
                    NSLog(@"WARNING: Unhandled linked object schema: %@", linkDictionary[@"schema"]);
                }
            }
        }
    }
    
    // Note: Doesn't seem like signalFence is currently in use
    
    return patch;
}

@end
