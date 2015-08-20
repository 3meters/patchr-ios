// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.h instead.

@import CoreData;
#import "Entity.h"

extern const struct UserAttributes {
	__unsafe_unretained NSString *area;
	__unsafe_unretained NSString *developer;
	__unsafe_unretained NSString *email;
	__unsafe_unretained NSString *password;
	__unsafe_unretained NSString *patchesLikes;
	__unsafe_unretained NSString *patchesOwned;
	__unsafe_unretained NSString *patchesWatching;
	__unsafe_unretained NSString *role;
} UserAttributes;

@interface UserID : EntityID {}
@end

@interface _User : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) UserID* objectID;

@property (nonatomic, strong) NSString* area;

//- (BOOL)validateArea:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* developer;

@property (atomic) BOOL developerValue;
- (BOOL)developerValue;
- (void)setDeveloperValue:(BOOL)value_;

//- (BOOL)validateDeveloper:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* email;

//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* password;

//- (BOOL)validatePassword:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* patchesLikes;

@property (atomic) int64_t patchesLikesValue;
- (int64_t)patchesLikesValue;
- (void)setPatchesLikesValue:(int64_t)value_;

//- (BOOL)validatePatchesLikes:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* patchesOwned;

@property (atomic) int64_t patchesOwnedValue;
- (int64_t)patchesOwnedValue;
- (void)setPatchesOwnedValue:(int64_t)value_;

//- (BOOL)validatePatchesOwned:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* patchesWatching;

@property (atomic) int64_t patchesWatchingValue;
- (int64_t)patchesWatchingValue;
- (void)setPatchesWatchingValue:(int64_t)value_;

//- (BOOL)validatePatchesWatching:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* role;

//- (BOOL)validateRole:(id*)value_ error:(NSError**)error_;

@end

@interface _User (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveArea;
- (void)setPrimitiveArea:(NSString*)value;

- (NSNumber*)primitiveDeveloper;
- (void)setPrimitiveDeveloper:(NSNumber*)value;

- (BOOL)primitiveDeveloperValue;
- (void)setPrimitiveDeveloperValue:(BOOL)value_;

- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;

- (NSString*)primitivePassword;
- (void)setPrimitivePassword:(NSString*)value;

- (NSNumber*)primitivePatchesLikes;
- (void)setPrimitivePatchesLikes:(NSNumber*)value;

- (int64_t)primitivePatchesLikesValue;
- (void)setPrimitivePatchesLikesValue:(int64_t)value_;

- (NSNumber*)primitivePatchesOwned;
- (void)setPrimitivePatchesOwned:(NSNumber*)value;

- (int64_t)primitivePatchesOwnedValue;
- (void)setPrimitivePatchesOwnedValue:(int64_t)value_;

- (NSNumber*)primitivePatchesWatching;
- (void)setPrimitivePatchesWatching:(NSNumber*)value;

- (int64_t)primitivePatchesWatchingValue;
- (void)setPrimitivePatchesWatchingValue:(int64_t)value_;

- (NSString*)primitiveRole;
- (void)setPrimitiveRole:(NSString*)value;

@end
