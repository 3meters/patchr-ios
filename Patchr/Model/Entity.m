#import "Entity.h"
#import "Photo.h"
#import "Location.h"

@interface Entity ()

// Private interface goes here.

@end

@implementation Entity

+ (Entity *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                               onObject:(Entity *)entity
                           mappingNames:(BOOL)mapNames {
    entity = (Entity *)[ServiceBase setPropertiesFromDictionary:dictionary onObject:entity mappingNames:mapNames];
    entity.subtitle = dictionary[@"subtitle"];
    entity.description_ = dictionary[@"description"];
    entity.privacy = mapNames ? dictionary[@"visibility"] : dictionary[@"privacy"];
    entity.patchId = mapNames ? dictionary[@"_acl"] : dictionary[@"patchId"];
    
    if (dictionary[@"photo"]) {
        entity.photo = [Photo setPropertiesFromDictionary:dictionary[@"photo"] onObject:[Photo insertInManagedObjectContext:entity.managedObjectContext] mappingNames:mapNames];
    }
    
    if (dictionary[@"location"]) {
        entity.location = [Location setPropertiesFromDictionary:dictionary[@"location"] onObject:[Location insertInManagedObjectContext:entity.managedObjectContext] mappingNames:mapNames];
    }
    
    if ([dictionary[@"linkedCount"] isKindOfClass:[NSDictionary class]]) {
        entity.linkedCounts = dictionary[@"linkedCount"];
        entity.numberOfLikes = [Entity countForStatWithType:@"like" schema:@"users" inLinkedCounts:entity.linkedCounts];
        entity.numberOfWatchersValue = [[Entity countForStatWithType:@"watch" schema:@"users" inLinkedCounts:entity.linkedCounts] integerValue];
    }
    
    entity.reason = dictionary[@"reason"];
    entity.score = dictionary[@"score"];
    entity.count = dictionary[@"count"];
    entity.rank = dictionary[@"rank"];
    
    if ([dictionary[@"visibility"] isEqual:@"public"]) {
        entity.visibilityValue = PAVisibilityLevelPublic;
    } else if ([dictionary[@"visibility"] isEqual:@"private"]){
        entity.visibilityValue = PAVisibilityLevelPrivate;
    } else {
        if (!entity.visibility) {
            entity.visibilityValue = PAVisibilityLevelUnknown;
        }
    }
    
    return entity;
}

- (NSNumber *)numberOfMessages {
    return [self countForStatWithType:@"content" schema:@"messages"];
}

- (NSNumber *)countForStatWithType:(NSString *)type schema:(NSString *)schema {
    return [Entity countForStatWithType:type schema:schema inLinkedCounts:self.linkedCounts];
}

+ (NSNumber *)countForStatWithType:(NSString *)type schema:(NSString *)schema inLinkedCounts:(NSDictionary *)linkedCounts {
    if ([linkedCounts[@"from"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *fromLinkedCounts = linkedCounts[@"from"];
        for (NSObject *key in fromLinkedCounts.allKeys) {
            if ([key isEqual:schema] && [fromLinkedCounts[key] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *schemaDict = fromLinkedCounts[key];
                if ([schemaDict[type] isKindOfClass:[NSNumber class]]) {
                    return schemaDict[type];
                }
            }
        }
    }
    return nil; // Not found
}

@end
