// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QueryItem.h instead.

@import CoreData;

extern const struct QueryItemAttributes {
	__unsafe_unretained NSString *distance;
	__unsafe_unretained NSString *modifiedDate;
	__unsafe_unretained NSString *position;
	__unsafe_unretained NSString *sortDate;
} QueryItemAttributes;

extern const struct QueryItemRelationships {
	__unsafe_unretained NSString *object;
	__unsafe_unretained NSString *query;
} QueryItemRelationships;

@class ServiceBase;
@class Query;

@interface QueryItemID : NSManagedObjectID {}
@end

@interface _QueryItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QueryItemID* objectID;

@property (nonatomic, strong) NSNumber* distance;

@property (atomic) float distanceValue;
- (float)distanceValue;
- (void)setDistanceValue:(float)value_;

//- (BOOL)validateDistance:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* modifiedDate;

//- (BOOL)validateModifiedDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* position;

@property (atomic) int64_t positionValue;
- (int64_t)positionValue;
- (void)setPositionValue:(int64_t)value_;

//- (BOOL)validatePosition:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* sortDate;

//- (BOOL)validateSortDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) ServiceBase *object;

//- (BOOL)validateObject:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Query *query;

//- (BOOL)validateQuery:(id*)value_ error:(NSError**)error_;

@end

@interface _QueryItem (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveDistance;
- (void)setPrimitiveDistance:(NSNumber*)value;

- (float)primitiveDistanceValue;
- (void)setPrimitiveDistanceValue:(float)value_;

- (NSDate*)primitiveModifiedDate;
- (void)setPrimitiveModifiedDate:(NSDate*)value;

- (NSNumber*)primitivePosition;
- (void)setPrimitivePosition:(NSNumber*)value;

- (int64_t)primitivePositionValue;
- (void)setPrimitivePositionValue:(int64_t)value_;

- (NSDate*)primitiveSortDate;
- (void)setPrimitiveSortDate:(NSDate*)value;

- (ServiceBase*)primitiveObject;
- (void)setPrimitiveObject:(ServiceBase*)value;

- (Query*)primitiveQuery;
- (void)setPrimitiveQuery:(Query*)value;

@end
