// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Photo.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct PhotoAttributes {
	__unsafe_unretained NSString *createdDate;
	__unsafe_unretained NSString *height;
	__unsafe_unretained NSString *prefix;
	__unsafe_unretained NSString *source;
	__unsafe_unretained NSString *suffix;
	__unsafe_unretained NSString *width;
} PhotoAttributes;

extern const struct PhotoRelationships {
	__unsafe_unretained NSString *category;
	__unsafe_unretained NSString *entity_;
	__unsafe_unretained NSString *notification;
} PhotoRelationships;

@class PACategory;
@class Entity;
@class Notification;

@interface PhotoID : ServiceObjectID {}
@end

@interface _Photo : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PhotoID* objectID;

@property (nonatomic, strong) NSDate* createdDate;

//- (BOOL)validateCreatedDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* height;

@property (atomic) int32_t heightValue;
- (int32_t)heightValue;
- (void)setHeightValue:(int32_t)value_;

//- (BOOL)validateHeight:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* prefix;

//- (BOOL)validatePrefix:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* source;

//- (BOOL)validateSource:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* suffix;

//- (BOOL)validateSuffix:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* width;

@property (atomic) int32_t widthValue;
- (int32_t)widthValue;
- (void)setWidthValue:(int32_t)value_;

//- (BOOL)validateWidth:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) PACategory *category;

//- (BOOL)validateCategory:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Entity *entity_;

//- (BOOL)validateEntity_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Notification *notification;

//- (BOOL)validateNotification:(id*)value_ error:(NSError**)error_;

@end

@interface _Photo (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCreatedDate;
- (void)setPrimitiveCreatedDate:(NSDate*)value;

- (NSNumber*)primitiveHeight;
- (void)setPrimitiveHeight:(NSNumber*)value;

- (int32_t)primitiveHeightValue;
- (void)setPrimitiveHeightValue:(int32_t)value_;

- (NSString*)primitivePrefix;
- (void)setPrimitivePrefix:(NSString*)value;

- (NSString*)primitiveSource;
- (void)setPrimitiveSource:(NSString*)value;

- (NSString*)primitiveSuffix;
- (void)setPrimitiveSuffix:(NSString*)value;

- (NSNumber*)primitiveWidth;
- (void)setPrimitiveWidth:(NSNumber*)value;

- (int32_t)primitiveWidthValue;
- (void)setPrimitiveWidthValue:(int32_t)value_;

- (PACategory*)primitiveCategory;
- (void)setPrimitiveCategory:(PACategory*)value;

- (Entity*)primitiveEntity_;
- (void)setPrimitiveEntity_:(Entity*)value;

- (Notification*)primitiveNotification;
- (void)setPrimitiveNotification:(Notification*)value;

@end
