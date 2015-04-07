// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QueryResult.h instead.

@import CoreData;

extern const struct QueryResultAttributes {
	__unsafe_unretained NSString *modificationDate;
	__unsafe_unretained NSString *position;
	__unsafe_unretained NSString *sortDate;
} QueryResultAttributes;

extern const struct QueryResultRelationships {
	__unsafe_unretained NSString *query;
	__unsafe_unretained NSString *result;
} QueryResultRelationships;

@class Query;
@class ServiceBase;

@interface QueryResultID : NSManagedObjectID {}
@end

@interface _QueryResult : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QueryResultID* objectID;

@property (nonatomic, strong) NSDate* modificationDate;

//- (BOOL)validateModificationDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* position;

@property (atomic) int64_t positionValue;
- (int64_t)positionValue;
- (void)setPositionValue:(int64_t)value_;

//- (BOOL)validatePosition:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* sortDate;

//- (BOOL)validateSortDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Query *query;

//- (BOOL)validateQuery:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) ServiceBase *result;

//- (BOOL)validateResult:(id*)value_ error:(NSError**)error_;

@end

@interface _QueryResult (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveModificationDate;
- (void)setPrimitiveModificationDate:(NSDate*)value;

- (NSNumber*)primitivePosition;
- (void)setPrimitivePosition:(NSNumber*)value;

- (int64_t)primitivePositionValue;
- (void)setPrimitivePositionValue:(int64_t)value_;

- (NSDate*)primitiveSortDate;
- (void)setPrimitiveSortDate:(NSDate*)value;

- (Query*)primitiveQuery;
- (void)setPrimitiveQuery:(Query*)value;

- (ServiceBase*)primitiveResult;
- (void)setPrimitiveResult:(ServiceBase*)value;

@end
