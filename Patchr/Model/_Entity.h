// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Entity.h instead.

@import CoreData;
#import "ServiceBase.h"

#import "PAEnums.h"

extern const struct EntityAttributes {
	__unsafe_unretained NSString *countLikes;
	__unsafe_unretained NSString *countPending;
	__unsafe_unretained NSString *countWatching;
	__unsafe_unretained NSString *description_;
	__unsafe_unretained NSString *linkCounts;
	__unsafe_unretained NSString *locked;
	__unsafe_unretained NSString *patchId;
	__unsafe_unretained NSString *reason;
	__unsafe_unretained NSString *score;
	__unsafe_unretained NSString *subtitle;
	__unsafe_unretained NSString *userLikes;
	__unsafe_unretained NSString *userLikesId;
	__unsafe_unretained NSString *userWatchId;
	__unsafe_unretained NSString *userWatchJustApproved;
	__unsafe_unretained NSString *userWatchMuted;
	__unsafe_unretained NSString *userWatchStatus;
	__unsafe_unretained NSString *visibility;
} EntityAttributes;

extern const struct EntityRelationships {
	__unsafe_unretained NSString *link;
	__unsafe_unretained NSString *location;
	__unsafe_unretained NSString *photo;
} EntityRelationships;

extern const struct EntityUserInfo {
	__unsafe_unretained NSString *additionalHeaderFileName;
} EntityUserInfo;

@class Link;
@class Location;
@class Photo;

@class NSDictionary;

@interface EntityID : ServiceBaseID {}
@end

@interface _Entity : ServiceBase {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EntityID* objectID;

@property (nonatomic, strong) NSNumber* countLikes;

@property (atomic) int64_t countLikesValue;
- (int64_t)countLikesValue;
- (void)setCountLikesValue:(int64_t)value_;

//- (BOOL)validateCountLikes:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* countPending;

@property (atomic) int64_t countPendingValue;
- (int64_t)countPendingValue;
- (void)setCountPendingValue:(int64_t)value_;

//- (BOOL)validateCountPending:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* countWatching;

@property (atomic) int64_t countWatchingValue;
- (int64_t)countWatchingValue;
- (void)setCountWatchingValue:(int64_t)value_;

//- (BOOL)validateCountWatching:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* description_;

//- (BOOL)validateDescription_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDictionary* linkCounts;

//- (BOOL)validateLinkCounts:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* locked;

@property (atomic) BOOL lockedValue;
- (BOOL)lockedValue;
- (void)setLockedValue:(BOOL)value_;

//- (BOOL)validateLocked:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* patchId;

//- (BOOL)validatePatchId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* reason;

//- (BOOL)validateReason:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* score;

@property (atomic) int64_t scoreValue;
- (int64_t)scoreValue;
- (void)setScoreValue:(int64_t)value_;

//- (BOOL)validateScore:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* subtitle;

//- (BOOL)validateSubtitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* userLikes;

@property (atomic) BOOL userLikesValue;
- (BOOL)userLikesValue;
- (void)setUserLikesValue:(BOOL)value_;

//- (BOOL)validateUserLikes:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* userLikesId;

//- (BOOL)validateUserLikesId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* userWatchId;

//- (BOOL)validateUserWatchId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* userWatchJustApproved;

@property (atomic) BOOL userWatchJustApprovedValue;
- (BOOL)userWatchJustApprovedValue;
- (void)setUserWatchJustApprovedValue:(BOOL)value_;

//- (BOOL)validateUserWatchJustApproved:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* userWatchMuted;

@property (atomic) BOOL userWatchMutedValue;
- (BOOL)userWatchMutedValue;
- (void)setUserWatchMutedValue:(BOOL)value_;

//- (BOOL)validateUserWatchMuted:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* userWatchStatus;

@property (atomic) PAWatchStatus userWatchStatusValue;
- (PAWatchStatus)userWatchStatusValue;
- (void)setUserWatchStatusValue:(PAWatchStatus)value_;

//- (BOOL)validateUserWatchStatus:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* visibility;

//- (BOOL)validateVisibility:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Link *link;

//- (BOOL)validateLink:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Location *location;

//- (BOOL)validateLocation:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Photo *photo;

//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;

@end

@interface _Entity (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCountLikes;
- (void)setPrimitiveCountLikes:(NSNumber*)value;

- (int64_t)primitiveCountLikesValue;
- (void)setPrimitiveCountLikesValue:(int64_t)value_;

- (NSNumber*)primitiveCountPending;
- (void)setPrimitiveCountPending:(NSNumber*)value;

- (int64_t)primitiveCountPendingValue;
- (void)setPrimitiveCountPendingValue:(int64_t)value_;

- (NSNumber*)primitiveCountWatching;
- (void)setPrimitiveCountWatching:(NSNumber*)value;

- (int64_t)primitiveCountWatchingValue;
- (void)setPrimitiveCountWatchingValue:(int64_t)value_;

- (NSString*)primitiveDescription_;
- (void)setPrimitiveDescription_:(NSString*)value;

- (NSDictionary*)primitiveLinkCounts;
- (void)setPrimitiveLinkCounts:(NSDictionary*)value;

- (NSNumber*)primitiveLocked;
- (void)setPrimitiveLocked:(NSNumber*)value;

- (BOOL)primitiveLockedValue;
- (void)setPrimitiveLockedValue:(BOOL)value_;

- (NSString*)primitivePatchId;
- (void)setPrimitivePatchId:(NSString*)value;

- (NSString*)primitiveReason;
- (void)setPrimitiveReason:(NSString*)value;

- (NSNumber*)primitiveScore;
- (void)setPrimitiveScore:(NSNumber*)value;

- (int64_t)primitiveScoreValue;
- (void)setPrimitiveScoreValue:(int64_t)value_;

- (NSString*)primitiveSubtitle;
- (void)setPrimitiveSubtitle:(NSString*)value;

- (NSNumber*)primitiveUserLikes;
- (void)setPrimitiveUserLikes:(NSNumber*)value;

- (BOOL)primitiveUserLikesValue;
- (void)setPrimitiveUserLikesValue:(BOOL)value_;

- (NSString*)primitiveUserLikesId;
- (void)setPrimitiveUserLikesId:(NSString*)value;

- (NSString*)primitiveUserWatchId;
- (void)setPrimitiveUserWatchId:(NSString*)value;

- (NSNumber*)primitiveUserWatchJustApproved;
- (void)setPrimitiveUserWatchJustApproved:(NSNumber*)value;

- (BOOL)primitiveUserWatchJustApprovedValue;
- (void)setPrimitiveUserWatchJustApprovedValue:(BOOL)value_;

- (NSNumber*)primitiveUserWatchMuted;
- (void)setPrimitiveUserWatchMuted:(NSNumber*)value;

- (BOOL)primitiveUserWatchMutedValue;
- (void)setPrimitiveUserWatchMutedValue:(BOOL)value_;

- (NSNumber*)primitiveUserWatchStatus;
- (void)setPrimitiveUserWatchStatus:(NSNumber*)value;

- (PAWatchStatus)primitiveUserWatchStatusValue;
- (void)setPrimitiveUserWatchStatusValue:(PAWatchStatus)value_;

- (NSString*)primitiveVisibility;
- (void)setPrimitiveVisibility:(NSString*)value;

- (Link*)primitiveLink;
- (void)setPrimitiveLink:(Link*)value;

- (Location*)primitiveLocation;
- (void)setPrimitiveLocation:(Location*)value;

- (Photo*)primitivePhoto;
- (void)setPrimitivePhoto:(Photo*)value;

@end
