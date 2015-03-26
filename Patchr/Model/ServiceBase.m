#import "ServiceBase.h"
#import "ModelUtilities.h"

@interface ServiceBase ()

// Private interface goes here.

@end

@implementation ServiceBase

+ (id)fetchOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[[self class] entityName]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:ServiceBaseAttributes.id_ ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", ServiceBaseAttributes.id_, id_];
    
    NSError *error;
    NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(!error, @"Error fetching MediaItem");
    id item = [results firstObject];
    return item;
}

+ (id)fetchOrInsertOneById:(NSString *)id_ inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    ServiceBase *item = [[self class] fetchOneById:id_ inManagedObjectContext:managedObjectContext];
    if (!item) {
        item = [[self class] insertInManagedObjectContext:managedObjectContext];
        item.id_ = id_;
    }
    return item;
}

+ (ServiceBase *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceBase *)base
                                mappingNames:(BOOL)mapNames {
    base.id_ = (mapNames && dictionary[@"_id"]) ? dictionary[@"_id"] : dictionary[@"id"];
    base.name = dictionary[@"name"];
    base.schema = dictionary[@"schema"];
    base.type = dictionary[@"type"];
    base.locked = dictionary[@"locked"];
    base.position = dictionary[@"position"];
    base.ownerId = (mapNames && dictionary[@"_owner"]) ? dictionary[@"_owner"] : dictionary[@"owner"];
    base.creatorId = (mapNames && dictionary[@"_creator"]) ? dictionary[@"_creator"] : dictionary[@"creator"];
    base.modifierId = (mapNames && dictionary[@"_modifier"]) ? dictionary[@"_modifier"] : dictionary[@"modifier"];
    
    if ([dictionary[@"createdDate"] isKindOfClass:[NSNumber class]]) {
        base.createdDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"createdDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"modifiedDate"] isKindOfClass:[NSNumber class]]) {
        base.modifiedDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"modifiedDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"activityDate"] isKindOfClass:[NSNumber class]]) {
        base.activityDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"activityDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"sortDate"] isKindOfClass:[NSNumber class]]) {
        base.sortDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"sortDate"] doubleValue]/1000];
    }
    
    if ([dictionary[@"creator"] isKindOfClass:[NSDictionary class]]) {
        if ([ModelUtilities modelClassForSchema:dictionary[@"creator"][@"schema"]]) {
            Class modelClass = [ModelUtilities modelClassForSchema:dictionary[@"creator"][@"schema"]];
            id creator = [modelClass fetchOrInsertOneById:dictionary[@"creator"][@"_id"] inManagedObjectContext:base.managedObjectContext];
            base.creator = [modelClass setPropertiesFromDictionary:dictionary[@"creator"] onObject:creator mappingNames:mapNames];
        }
    }
    
    if ([dictionary[@"linked"] isKindOfClass:[NSArray class]]) {
        // Configure ServiceBase-specific relationships
        
        for (id link in dictionary[@"linked"]) {
            
            if ([link isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *linkDictionary = link;
                
                if ([ModelUtilities modelClassForSchema:linkDictionary[@"schema"]]) {
                    
                    Class modelClass = [ModelUtilities modelClassForSchema:linkDictionary[@"schema"]];
                    ServiceBase *modelObject = [modelClass fetchOrInsertOneById:linkDictionary[@"_id"] inManagedObjectContext:base.managedObjectContext];
                    [modelClass setPropertiesFromDictionary:linkDictionary onObject:modelObject mappingNames:mapNames];

                    if (base.creatorId == modelObject.id_) {
                        base.creator = modelObject;
                    }
                    
                    if (base.ownerId == modelObject.id_) {
                        base.owner = modelObject;
                    }
                }
            }
        }
    }
    
    return base;
}

@end
