#import "Entity.h"
#import "Photo.h"
#import "Location.h"
#import "Statistic.h"

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
    
    if ([dictionary[@"linksInCounts"] isKindOfClass:[NSArray class]]) {
        for (id object in dictionary[@"linksInCounts"]) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                Statistic *stat = [Statistic setPropertiesFromDictionary:object onObject:[Statistic insertInManagedObjectContext:entity.managedObjectContext] mappingNames:mapNames];
                [entity addLinksInCountsObject:stat];
            }
        }
    }
    
    if ([dictionary[@"linksOutCounts"] isKindOfClass:[NSArray class]]) {
        for (id object in dictionary[@"linksOutCounts"]) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                Statistic *stat = [Statistic setPropertiesFromDictionary:object onObject:[Statistic insertInManagedObjectContext:entity.managedObjectContext] mappingNames:mapNames];
                [entity addLinksOutCountsObject:stat];
            }
        }
    }
    
    entity.reason = dictionary[@"reason"];
    entity.score = dictionary[@"score"];
    entity.count = dictionary[@"count"];
    entity.rank = dictionary[@"rank"];
    
    return entity;
}

- (NSNumber *)numberOfLikes {
    return [self countForStatWithType:@"like" schema:@"user"];
}

- (NSNumber *)numberOfWatchers {
    return [self countForStatWithType:@"watch" schema:@"user"];
}

- (NSNumber *)numberOfMessages {
    return [self countForStatWithType:@"content" schema:@"message"];
}

- (NSNumber *)countForStatWithType:(NSString *)type schema:(NSString *)schema {
    for (Statistic *stat in self.linksInCounts) {
        if ([stat.type isEqualToString:type] && [stat.schema isEqualToString:schema]) {
            return stat.count;
        }
    }
    return nil;
}

@end
