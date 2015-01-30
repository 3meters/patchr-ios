// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.h instead.

@import CoreData;

extern const struct QueryAttributes {
	__unsafe_unretained NSString *limit;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *offset;
	__unsafe_unretained NSString *path;
} QueryAttributes;

extern const struct QueryRelationships {
	__unsafe_unretained NSString *queryResults;
} QueryRelationships;

@class QueryResult;

@interface QueryID : NSManagedObjectID {}
@end

@interface _Query : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QueryID* objectID;

@property (nonatomic, strong) NSNumber* limit;

@property (atomic) int64_t limitValue;
- (int64_t)limitValue;
- (void)setLimitValue:(int64_t)value_;

//- (BOOL)validateLimit:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* offset;

@property (atomic) int64_t offsetValue;
- (int64_t)offsetValue;
- (void)setOffsetValue:(int64_t)value_;

//- (BOOL)validateOffset:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* path;

//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *queryResults;

- (NSMutableSet*)queryResultsSet;

@end

@interface _Query (QueryResultsCoreDataGeneratedAccessors)
- (void)addQueryResults:(NSSet*)value_;
- (void)removeQueryResults:(NSSet*)value_;
- (void)addQueryResultsObject:(QueryResult*)value_;
- (void)removeQueryResultsObject:(QueryResult*)value_;

@end

@interface _Query (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveLimit;
- (void)setPrimitiveLimit:(NSNumber*)value;

- (int64_t)primitiveLimitValue;
- (void)setPrimitiveLimitValue:(int64_t)value_;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSNumber*)primitiveOffset;
- (void)setPrimitiveOffset:(NSNumber*)value;

- (int64_t)primitiveOffsetValue;
- (void)setPrimitiveOffsetValue:(int64_t)value_;

- (NSString*)primitivePath;
- (void)setPrimitivePath:(NSString*)value;

- (NSMutableSet*)primitiveQueryResults;
- (void)setPrimitiveQueryResults:(NSMutableSet*)value;

@end
