// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServiceBase.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct ServiceBaseAttributes {
	__unsafe_unretained NSString *activityDate;
	__unsafe_unretained NSString *createdDate;
	__unsafe_unretained NSString *creatorId;
	__unsafe_unretained NSString *decorated;
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *modifiedDate;
	__unsafe_unretained NSString *modifierId;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *namelc;
	__unsafe_unretained NSString *ownerId;
	__unsafe_unretained NSString *refreshed;
	__unsafe_unretained NSString *schema;
	__unsafe_unretained NSString *sortDate;
	__unsafe_unretained NSString *type;
} ServiceBaseAttributes;

extern const struct ServiceBaseRelationships {
	__unsafe_unretained NSString *creator;
	__unsafe_unretained NSString *modifier;
	__unsafe_unretained NSString *owner;
	__unsafe_unretained NSString *queriesContextFor;
	__unsafe_unretained NSString *queryItems;
} ServiceBaseRelationships;

@class Shortcut;
@class Shortcut;
@class Shortcut;
@class Query;
@class QueryItem;

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

@property (nonatomic, strong) NSNumber* decorated;

@property (atomic) BOOL decoratedValue;
- (BOOL)decoratedValue;
- (void)setDecoratedValue:(BOOL)value_;

//- (BOOL)validateDecorated:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

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

@property (nonatomic, strong) NSNumber* refreshed;

@property (atomic) BOOL refreshedValue;
- (BOOL)refreshedValue;
- (void)setRefreshedValue:(BOOL)value_;

//- (BOOL)validateRefreshed:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* schema;

//- (BOOL)validateSchema:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* sortDate;

//- (BOOL)validateSortDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Shortcut *creator;

//- (BOOL)validateCreator:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Shortcut *modifier;

//- (BOOL)validateModifier:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Shortcut *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *queriesContextFor;

- (NSMutableSet*)queriesContextForSet;

@property (nonatomic, strong) NSSet *queryItems;

- (NSMutableSet*)queryItemsSet;

@end

@interface _ServiceBase (QueriesContextForCoreDataGeneratedAccessors)
- (void)addQueriesContextFor:(NSSet*)value_;
- (void)removeQueriesContextFor:(NSSet*)value_;
- (void)addQueriesContextForObject:(Query*)value_;
- (void)removeQueriesContextForObject:(Query*)value_;

@end

@interface _ServiceBase (QueryItemsCoreDataGeneratedAccessors)
- (void)addQueryItems:(NSSet*)value_;
- (void)removeQueryItems:(NSSet*)value_;
- (void)addQueryItemsObject:(QueryItem*)value_;
- (void)removeQueryItemsObject:(QueryItem*)value_;

@end

@interface _ServiceBase (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveActivityDate;
- (void)setPrimitiveActivityDate:(NSDate*)value;

- (NSDate*)primitiveCreatedDate;
- (void)setPrimitiveCreatedDate:(NSDate*)value;

- (NSString*)primitiveCreatorId;
- (void)setPrimitiveCreatorId:(NSString*)value;

- (NSNumber*)primitiveDecorated;
- (void)setPrimitiveDecorated:(NSNumber*)value;

- (BOOL)primitiveDecoratedValue;
- (void)setPrimitiveDecoratedValue:(BOOL)value_;

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

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

- (NSNumber*)primitiveRefreshed;
- (void)setPrimitiveRefreshed:(NSNumber*)value;

- (BOOL)primitiveRefreshedValue;
- (void)setPrimitiveRefreshedValue:(BOOL)value_;

- (NSString*)primitiveSchema;
- (void)setPrimitiveSchema:(NSString*)value;

- (NSDate*)primitiveSortDate;
- (void)setPrimitiveSortDate:(NSDate*)value;

- (Shortcut*)primitiveCreator;
- (void)setPrimitiveCreator:(Shortcut*)value;

- (Shortcut*)primitiveModifier;
- (void)setPrimitiveModifier:(Shortcut*)value;

- (Shortcut*)primitiveOwner;
- (void)setPrimitiveOwner:(Shortcut*)value;

- (NSMutableSet*)primitiveQueriesContextFor;
- (void)setPrimitiveQueriesContextFor:(NSMutableSet*)value;

- (NSMutableSet*)primitiveQueryItems;
- (void)setPrimitiveQueryItems:(NSMutableSet*)value;

@end
