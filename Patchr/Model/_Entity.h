// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Entity.h instead.

@import CoreData;
#import "ServiceBase.h"

#import "PAEnums.h"

extern const struct EntityAttributes {
	__unsafe_unretained NSString *count;
	__unsafe_unretained NSString *description_;
	__unsafe_unretained NSString *linkedCounts;
	__unsafe_unretained NSString *numberOfLikes;
	__unsafe_unretained NSString *numberOfWatchers;
	__unsafe_unretained NSString *patchId;
	__unsafe_unretained NSString *privacy;
	__unsafe_unretained NSString *rank;
	__unsafe_unretained NSString *reason;
	__unsafe_unretained NSString *score;
	__unsafe_unretained NSString *subtitle;
	__unsafe_unretained NSString *visibility;
} EntityAttributes;

extern const struct EntityRelationships {
	__unsafe_unretained NSString *location;
	__unsafe_unretained NSString *photo;
	__unsafe_unretained NSString *queryResults;
} EntityRelationships;

extern const struct EntityUserInfo {
	__unsafe_unretained NSString *additionalHeaderFileName;
} EntityUserInfo;

@class Location;
@class Photo;
@class QueryResult;

@class NSDictionary;

@interface EntityID : ServiceBaseID {}
@end

@interface _Entity : ServiceBase {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EntityID* objectID;

@property (nonatomic, strong) NSNumber* count;

@property (atomic) int64_t countValue;
- (int64_t)countValue;
- (void)setCountValue:(int64_t)value_;

//- (BOOL)validateCount:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* description_;

//- (BOOL)validateDescription_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDictionary* linkedCounts;

//- (BOOL)validateLinkedCounts:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* numberOfLikes;

@property (atomic) int64_t numberOfLikesValue;
- (int64_t)numberOfLikesValue;
- (void)setNumberOfLikesValue:(int64_t)value_;

//- (BOOL)validateNumberOfLikes:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* numberOfWatchers;

@property (atomic) int64_t numberOfWatchersValue;
- (int64_t)numberOfWatchersValue;
- (void)setNumberOfWatchersValue:(int64_t)value_;

//- (BOOL)validateNumberOfWatchers:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* patchId;

//- (BOOL)validatePatchId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* privacy;

//- (BOOL)validatePrivacy:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* rank;

@property (atomic) int64_t rankValue;
- (int64_t)rankValue;
- (void)setRankValue:(int64_t)value_;

//- (BOOL)validateRank:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* reason;

//- (BOOL)validateReason:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* score;

@property (atomic) int64_t scoreValue;
- (int64_t)scoreValue;
- (void)setScoreValue:(int64_t)value_;

//- (BOOL)validateScore:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* subtitle;

//- (BOOL)validateSubtitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* visibility;

@property (atomic) PAVisibilityLevel visibilityValue;
- (PAVisibilityLevel)visibilityValue;
- (void)setVisibilityValue:(PAVisibilityLevel)value_;

//- (BOOL)validateVisibility:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Location *location;

//- (BOOL)validateLocation:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Photo *photo;

//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *queryResults;

- (NSMutableSet*)queryResultsSet;

@end

@interface _Entity (QueryResultsCoreDataGeneratedAccessors)
- (void)addQueryResults:(NSSet*)value_;
- (void)removeQueryResults:(NSSet*)value_;
- (void)addQueryResultsObject:(QueryResult*)value_;
- (void)removeQueryResultsObject:(QueryResult*)value_;

@end

@interface _Entity (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCount;
- (void)setPrimitiveCount:(NSNumber*)value;

- (int64_t)primitiveCountValue;
- (void)setPrimitiveCountValue:(int64_t)value_;

- (NSString*)primitiveDescription_;
- (void)setPrimitiveDescription_:(NSString*)value;

- (NSDictionary*)primitiveLinkedCounts;
- (void)setPrimitiveLinkedCounts:(NSDictionary*)value;

- (NSNumber*)primitiveNumberOfLikes;
- (void)setPrimitiveNumberOfLikes:(NSNumber*)value;

- (int64_t)primitiveNumberOfLikesValue;
- (void)setPrimitiveNumberOfLikesValue:(int64_t)value_;

- (NSNumber*)primitiveNumberOfWatchers;
- (void)setPrimitiveNumberOfWatchers:(NSNumber*)value;

- (int64_t)primitiveNumberOfWatchersValue;
- (void)setPrimitiveNumberOfWatchersValue:(int64_t)value_;

- (NSString*)primitivePatchId;
- (void)setPrimitivePatchId:(NSString*)value;

- (NSString*)primitivePrivacy;
- (void)setPrimitivePrivacy:(NSString*)value;

- (NSNumber*)primitiveRank;
- (void)setPrimitiveRank:(NSNumber*)value;

- (int64_t)primitiveRankValue;
- (void)setPrimitiveRankValue:(int64_t)value_;

- (NSString*)primitiveReason;
- (void)setPrimitiveReason:(NSString*)value;

- (NSNumber*)primitiveScore;
- (void)setPrimitiveScore:(NSNumber*)value;

- (int64_t)primitiveScoreValue;
- (void)setPrimitiveScoreValue:(int64_t)value_;

- (NSString*)primitiveSubtitle;
- (void)setPrimitiveSubtitle:(NSString*)value;

- (NSNumber*)primitiveVisibility;
- (void)setPrimitiveVisibility:(NSNumber*)value;

- (PAVisibilityLevel)primitiveVisibilityValue;
- (void)setPrimitiveVisibilityValue:(PAVisibilityLevel)value_;

- (Location*)primitiveLocation;
- (void)setPrimitiveLocation:(Location*)value;

- (Photo*)primitivePhoto;
- (void)setPrimitivePhoto:(Photo*)value;

- (NSMutableSet*)primitiveQueryResults;
- (void)setPrimitiveQueryResults:(NSMutableSet*)value;

@end
