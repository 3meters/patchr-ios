// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.h instead.

@import CoreData;
#import "Entity.h"

extern const struct UserAttributes {
	__unsafe_unretained NSString *area;
	__unsafe_unretained NSString *authSource;
	__unsafe_unretained NSString *bio;
	__unsafe_unretained NSString *developer;
	__unsafe_unretained NSString *email;
	__unsafe_unretained NSString *facebookId;
	__unsafe_unretained NSString *googleId;
	__unsafe_unretained NSString *lastSignedInDate;
	__unsafe_unretained NSString *oauthData;
	__unsafe_unretained NSString *oauthId;
	__unsafe_unretained NSString *oauthSecret;
	__unsafe_unretained NSString *oauthToken;
	__unsafe_unretained NSString *password;
	__unsafe_unretained NSString *role;
	__unsafe_unretained NSString *twitterId;
	__unsafe_unretained NSString *validationDate;
	__unsafe_unretained NSString *validationNotifyDate;
	__unsafe_unretained NSString *webUri;
} UserAttributes;

extern const struct UserRelationships {
	__unsafe_unretained NSString *replies;
} UserRelationships;

@class Message;

@interface UserID : EntityID {}
@end

@interface _User : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) UserID* objectID;

@property (nonatomic, strong) NSString* area;

//- (BOOL)validateArea:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* authSource;

//- (BOOL)validateAuthSource:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* bio;

//- (BOOL)validateBio:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* developer;

@property (atomic) BOOL developerValue;
- (BOOL)developerValue;
- (void)setDeveloperValue:(BOOL)value_;

//- (BOOL)validateDeveloper:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* email;

//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* facebookId;

//- (BOOL)validateFacebookId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* googleId;

//- (BOOL)validateGoogleId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* lastSignedInDate;

//- (BOOL)validateLastSignedInDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* oauthData;

//- (BOOL)validateOauthData:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* oauthId;

//- (BOOL)validateOauthId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* oauthSecret;

//- (BOOL)validateOauthSecret:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* oauthToken;

//- (BOOL)validateOauthToken:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* password;

//- (BOOL)validatePassword:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* role;

//- (BOOL)validateRole:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* twitterId;

//- (BOOL)validateTwitterId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* validationDate;

//- (BOOL)validateValidationDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* validationNotifyDate;

//- (BOOL)validateValidationNotifyDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* webUri;

//- (BOOL)validateWebUri:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *replies;

- (NSMutableSet*)repliesSet;

@end

@interface _User (RepliesCoreDataGeneratedAccessors)
- (void)addReplies:(NSSet*)value_;
- (void)removeReplies:(NSSet*)value_;
- (void)addRepliesObject:(Message*)value_;
- (void)removeRepliesObject:(Message*)value_;

@end

@interface _User (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveArea;
- (void)setPrimitiveArea:(NSString*)value;

- (NSString*)primitiveAuthSource;
- (void)setPrimitiveAuthSource:(NSString*)value;

- (NSString*)primitiveBio;
- (void)setPrimitiveBio:(NSString*)value;

- (NSNumber*)primitiveDeveloper;
- (void)setPrimitiveDeveloper:(NSNumber*)value;

- (BOOL)primitiveDeveloperValue;
- (void)setPrimitiveDeveloperValue:(BOOL)value_;

- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;

- (NSString*)primitiveFacebookId;
- (void)setPrimitiveFacebookId:(NSString*)value;

- (NSString*)primitiveGoogleId;
- (void)setPrimitiveGoogleId:(NSString*)value;

- (NSDate*)primitiveLastSignedInDate;
- (void)setPrimitiveLastSignedInDate:(NSDate*)value;

- (NSString*)primitiveOauthData;
- (void)setPrimitiveOauthData:(NSString*)value;

- (NSString*)primitiveOauthId;
- (void)setPrimitiveOauthId:(NSString*)value;

- (NSString*)primitiveOauthSecret;
- (void)setPrimitiveOauthSecret:(NSString*)value;

- (NSString*)primitiveOauthToken;
- (void)setPrimitiveOauthToken:(NSString*)value;

- (NSString*)primitivePassword;
- (void)setPrimitivePassword:(NSString*)value;

- (NSString*)primitiveRole;
- (void)setPrimitiveRole:(NSString*)value;

- (NSString*)primitiveTwitterId;
- (void)setPrimitiveTwitterId:(NSString*)value;

- (NSDate*)primitiveValidationDate;
- (void)setPrimitiveValidationDate:(NSDate*)value;

- (NSDate*)primitiveValidationNotifyDate;
- (void)setPrimitiveValidationNotifyDate:(NSDate*)value;

- (NSString*)primitiveWebUri;
- (void)setPrimitiveWebUri:(NSString*)value;

- (NSMutableSet*)primitiveReplies;
- (void)setPrimitiveReplies:(NSMutableSet*)value;

@end
