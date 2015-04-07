// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServiceBase.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct ServiceBaseAttributes {
	__unsafe_unretained NSString *activityDate;
	__unsafe_unretained NSString *createdDate;
	__unsafe_unretained NSString *creatorId;
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *locked;
	__unsafe_unretained NSString *modifiedDate;
	__unsafe_unretained NSString *modifierId;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *namelc;
	__unsafe_unretained NSString *ownerId;
	__unsafe_unretained NSString *position;
	__unsafe_unretained NSString *schema;
	__unsafe_unretained NSString *sortDate;
	__unsafe_unretained NSString *type;
} ServiceBaseAttributes;

extern const struct ServiceBaseRelationships {
	__unsafe_unretained NSString *created;
	__unsafe_unretained NSString *creator;
	__unsafe_unretained NSString *owned;
	__unsafe_unretained NSString *owner;
	__unsafe_unretained NSString *queryResults;
} ServiceBaseRelationships;

@class ServiceBase;
@class ServiceBase;
@class ServiceBase;
@class ServiceBase;
@class QueryResult;

@interface ServiceBaseID : ServiceObjectID {}
@end

@interface _ServiceBase : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ServiceBaseID* objectID;

@property (nonatomic, strong) NSDate* activityDate;

//- (BOOL)validateActivityDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* createdDate;

//- (BOOL)validateCreatedDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* creatorId;

//- (BOOL)validateCreatorId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* locked;

@property (atomic) BOOL lockedValue;
- (BOOL)lockedValue;
- (void)setLockedValue:(BOOL)value_;

//- (BOOL)validateLocked:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* modifiedDate;

//- (BOOL)validateModifiedDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* modifierId;

//- (BOOL)validateModifierId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* namelc;

//- (BOOL)validateNamelc:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* ownerId;

//- (BOOL)validateOwnerId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* position;

@property (atomic) int32_t positionValue;
- (int32_t)positionValue;
- (void)setPositionValue:(int32_t)value_;

//- (BOOL)validatePosition:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* schema;

//- (BOOL)validateSchema:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* sortDate;

//- (BOOL)validateSortDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *created;

- (NSMutableSet*)createdSet;

@property (nonatomic, strong) ServiceBase *creator;

//- (BOOL)validateCreator:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *owned;

- (NSMutableSet*)ownedSet;

@property (nonatomic, strong) ServiceBase *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *queryResults;

- (NSMutableSet*)queryResultsSet;

@end

@interface _ServiceBase (CreatedCoreDataGeneratedAccessors)
- (void)addCreated:(NSSet*)value_;
- (void)removeCreated:(NSSet*)value_;
- (void)addCreatedObject:(ServiceBase*)value_;
- (void)removeCreatedObject:(ServiceBase*)value_;

@end

@interface _ServiceBase (OwnedCoreDataGeneratedAccessors)
- (void)addOwned:(NSSet*)value_;
- (void)removeOwned:(NSSet*)value_;
- (void)addOwnedObject:(ServiceBase*)value_;
- (void)removeOwnedObject:(ServiceBase*)value_;

@end

@interface _ServiceBase (QueryResultsCoreDataGeneratedAccessors)
- (void)addQueryResults:(NSSet*)value_;
- (void)removeQueryResults:(NSSet*)value_;
- (void)addQueryResultsObject:(QueryResult*)value_;
- (void)removeQueryResultsObject:(QueryResult*)value_;

@end

@interface _ServiceBase (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveActivityDate;
- (void)setPrimitiveActivityDate:(NSDate*)value;

- (NSDate*)primitiveCreatedDate;
- (void)setPrimitiveCreatedDate:(NSDate*)value;

- (NSString*)primitiveCreatorId;
- (void)setPrimitiveCreatorId:(NSString*)value;

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSNumber*)primitiveLocked;
- (void)setPrimitiveLocked:(NSNumber*)value;

- (BOOL)primitiveLockedValue;
- (void)setPrimitiveLockedValue:(BOOL)value_;

- (NSDate*)primitiveModifiedDate;
- (void)setPrimitiveModifiedDate:(NSDate*)value;

- (NSString*)primitiveModifierId;
- (void)setPrimitiveModifierId:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSString*)primitiveNamelc;
- (void)setPrimitiveNamelc:(NSString*)value;

- (NSString*)primitiveOwnerId;
- (void)setPrimitiveOwnerId:(NSString*)value;

- (NSNumber*)primitivePosition;
- (void)setPrimitivePosition:(NSNumber*)value;

- (int32_t)primitivePositionValue;
- (void)setPrimitivePositionValue:(int32_t)value_;

- (NSString*)primitiveSchema;
- (void)setPrimitiveSchema:(NSString*)value;

- (NSDate*)primitiveSortDate;
- (void)setPrimitiveSortDate:(NSDate*)value;

- (NSMutableSet*)primitiveCreated;
- (void)setPrimitiveCreated:(NSMutableSet*)value;

- (ServiceBase*)primitiveCreator;
- (void)setPrimitiveCreator:(ServiceBase*)value;

- (NSMutableSet*)primitiveOwned;
- (void)setPrimitiveOwned:(NSMutableSet*)value;

- (ServiceBase*)primitiveOwner;
- (void)setPrimitiveOwner:(ServiceBase*)value;

- (NSMutableSet*)primitiveQueryResults;
- (void)setPrimitiveQueryResults:(NSMutableSet*)value;

@end
