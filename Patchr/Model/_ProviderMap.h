// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ProviderMap.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct ProviderMapAttributes {
	__unsafe_unretained NSString *google;
	__unsafe_unretained NSString *googleReference;
} ProviderMapAttributes;

extern const struct ProviderMapRelationships {
	__unsafe_unretained NSString *providerMapFor;
} ProviderMapRelationships;

@class Place;

@interface ProviderMapID : ServiceObjectID {}
@end

@interface _ProviderMap : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ProviderMapID* objectID;

@property (nonatomic, strong) NSString* google;

//- (BOOL)validateGoogle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* googleReference;

//- (BOOL)validateGoogleReference:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Place *providerMapFor;

//- (BOOL)validateProviderMapFor:(id*)value_ error:(NSError**)error_;

@end

@interface _ProviderMap (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveGoogle;
- (void)setPrimitiveGoogle:(NSString*)value;

- (NSString*)primitiveGoogleReference;
- (void)setPrimitiveGoogleReference:(NSString*)value;

- (Place*)primitiveProviderMapFor;
- (void)setPrimitiveProviderMapFor:(Place*)value;

@end
