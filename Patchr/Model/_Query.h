// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.h instead.

@import CoreData;

extern const struct QueryAttributes {
	__unsafe_unretained NSString *criteria;
	__unsafe_unretained NSString *enabled;
	__unsafe_unretained NSString *executed;
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *more;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *offset;
	__unsafe_unretained NSString *offsetDate;
	__unsafe_unretained NSString *pageSize;
	__unsafe_unretained NSString *parameters;
	__unsafe_unretained NSString *sidecar;
} QueryAttributes;

extern const struct QueryRelationships {
	__unsafe_unretained NSString *queryItems;
} QueryRelationships;

@class QueryItem;

@class NSDictionary;

@class NSArray;

@interface QueryID : NSManagedObjectID {}
@end

@interface _Query : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QueryID* objectID;

@property (nonatomic, strong) NSNumber* criteria;

@property (atomic) BOOL criteriaValue;
- (BOOL)criteriaValue;
- (void)setCriteriaValue:(BOOL)value_;

//- (BOOL)validateCriteria:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* enabled;

@property (atomic) BOOL enabledValue;
- (BOOL)enabledValue;
- (void)setEnabledValue:(BOOL)value_;

//- (BOOL)validateEnabled:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* executed;

@property (atomic) BOOL executedValue;
- (BOOL)executedValue;
- (void)setExecutedValue:(BOOL)value_;

//- (BOOL)validateExecuted:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* more;

@property (atomic) BOOL moreValue;
- (BOOL)moreValue;
- (void)setMoreValue:(BOOL)value_;

//- (BOOL)validateMore:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* offset;

@property (atomic) int32_t offsetValue;
- (int32_t)offsetValue;
- (void)setOffsetValue:(int32_t)value_;

//- (BOOL)validateOffset:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* offsetDate;

//- (BOOL)validateOffsetDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* pageSize;

@property (atomic) int32_t pageSizeValue;
- (int32_t)pageSizeValue;
- (void)setPageSizeValue:(int32_t)value_;

//- (BOOL)validatePageSize:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDictionary* parameters;

//- (BOOL)validateParameters:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSArray* sidecar;

//- (BOOL)validateSidecar:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *queryItems;

- (NSMutableSet*)queryItemsSet;

@end

@interface _Query (QueryItemsCoreDataGeneratedAccessors)
- (void)addQueryItems:(NSSet*)value_;
- (void)removeQueryItems:(NSSet*)value_;
- (void)addQueryItemsObject:(QueryItem*)value_;
- (void)removeQueryItemsObject:(QueryItem*)value_;

@end

@interface _Query (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCriteria;
- (void)setPrimitiveCriteria:(NSNumber*)value;

- (BOOL)primitiveCriteriaValue;
- (void)setPrimitiveCriteriaValue:(BOOL)value_;

- (NSNumber*)primitiveEnabled;
- (void)setPrimitiveEnabled:(NSNumber*)value;

- (BOOL)primitiveEnabledValue;
- (void)setPrimitiveEnabledValue:(BOOL)value_;

- (NSNumber*)primitiveExecuted;
- (void)setPrimitiveExecuted:(NSNumber*)value;

- (BOOL)primitiveExecutedValue;
- (void)setPrimitiveExecutedValue:(BOOL)value_;

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSNumber*)primitiveMore;
- (void)setPrimitiveMore:(NSNumber*)value;

- (BOOL)primitiveMoreValue;
- (void)setPrimitiveMoreValue:(BOOL)value_;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSNumber*)primitiveOffset;
- (void)setPrimitiveOffset:(NSNumber*)value;

- (int32_t)primitiveOffsetValue;
- (void)setPrimitiveOffsetValue:(int32_t)value_;

- (NSDate*)primitiveOffsetDate;
- (void)setPrimitiveOffsetDate:(NSDate*)value;

- (NSNumber*)primitivePageSize;
- (void)setPrimitivePageSize:(NSNumber*)value;

- (int32_t)primitivePageSizeValue;
- (void)setPrimitivePageSizeValue:(int32_t)value_;

- (NSDictionary*)primitiveParameters;
- (void)setPrimitiveParameters:(NSDictionary*)value;

- (NSArray*)primitiveSidecar;
- (void)setPrimitiveSidecar:(NSArray*)value;

- (NSMutableSet*)primitiveQueryItems;
- (void)setPrimitiveQueryItems:(NSMutableSet*)value;

@end
