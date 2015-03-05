// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.h instead.

@import CoreData;

extern const struct QueryAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *parameters;
} QueryAttributes;

extern const struct QueryRelationships {
	__unsafe_unretained NSString *queryResults;
} QueryRelationships;

@class QueryResult;

@class NSDictionary;

@interface QueryID : NSManagedObjectID {}
@end

@interface _Query : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) QueryID* objectID;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDictionary* parameters;

//- (BOOL)validateParameters:(id*)value_ error:(NSError**)error_;

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

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSDictionary*)primitiveParameters;
- (void)setPrimitiveParameters:(NSDictionary*)value;

- (NSMutableSet*)primitiveQueryResults;
- (void)setPrimitiveQueryResults:(NSMutableSet*)value;

@end
