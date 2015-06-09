// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.h instead.

@import CoreData;

extern const struct QueryAttributes {
	__unsafe_unretained NSString *criteria;
	__unsafe_unretained NSString *executed;
	__unsafe_unretained NSString *more;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *offset;
	__unsafe_unretained NSString *pageSize;
	__unsafe_unretained NSString *parameters;
	__unsafe_unretained NSString *valid;
} QueryAttributes;

extern const struct QueryRelationships {
	__unsafe_unretained NSString *queryItems;
} QueryRelationships;

@class QueryItem;

@class NSDictionary;

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

@property (nonatomic, strong) NSNumber* executed;

@property (atomic) BOOL executedValue;
- (BOOL)executedValue;
- (void)setExecutedValue:(BOOL)value_;

//- (BOOL)validateExecuted:(id*)value_ error:(NSError**)error_;

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

@property (nonatomic, strong) NSNumber* pageSize;

@property (atomic) int32_t pageSizeValue;
- (int32_t)pageSizeValue;
- (void)setPageSizeValue:(int32_t)value_;

//- (BOOL)validatePageSize:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDictionary* parameters;

//- (BOOL)validateParameters:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* valid;

@property (atomic) BOOL validValue;
- (BOOL)validValue;
- (void)setValidValue:(BOOL)value_;

//- (BOOL)validateValid:(id*)value_ error:(NSError**)error_;

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

- (NSNumber*)primitiveExecuted;
- (void)setPrimitiveExecuted:(NSNumber*)value;

- (BOOL)primitiveExecutedValue;
- (void)setPrimitiveExecutedValue:(BOOL)value_;

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

- (NSNumber*)primitivePageSize;
- (void)setPrimitivePageSize:(NSNumber*)value;

- (int32_t)primitivePageSizeValue;
- (void)setPrimitivePageSizeValue:(int32_t)value_;

- (NSDictionary*)primitiveParameters;
- (void)setPrimitiveParameters:(NSDictionary*)value;

- (NSNumber*)primitiveValid;
- (void)setPrimitiveValid:(NSNumber*)value;

- (BOOL)primitiveValidValue;
- (void)setPrimitiveValidValue:(BOOL)value_;

- (NSMutableSet*)primitiveQueryItems;
- (void)setPrimitiveQueryItems:(NSMutableSet*)value;

@end
