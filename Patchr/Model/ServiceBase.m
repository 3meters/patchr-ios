#import "ServiceBase.h"

@interface ServiceBase ()

// Private interface goes here.

@end

@implementation ServiceBase

+ (ServiceBase *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                    onObject:(ServiceBase *)base
                                mappingNames:(BOOL)mapNames {
    base.id_ = (mapNames && dictionary[@"_id"]) ? dictionary[@"_id"] : dictionary[@"id"];
    base.name = dictionary[@"name"];
    base.schema = dictionary[@"schema"];
    base.type = dictionary[@"type"];
    base.locked = dictionary[@"locked"];
    base.position = dictionary[@"position"];
    // base.data = dictionary[@"data"]; // TODO
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
    
    // TODO it looks like creator, owner, and modifier objects are sometimes returned too, but we'll do indirect
    // lookups using their IDs for now
    
    return base;
}

@end
