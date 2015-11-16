// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Photo.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct PhotoAttributes {
	__unsafe_unretained NSString *height;
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *prefix;
	__unsafe_unretained NSString *source;
	__unsafe_unretained NSString *width;
} PhotoAttributes;

extern const struct PhotoRelationships {
	__unsafe_unretained NSString *photoBigFor;
	__unsafe_unretained NSString *photoFor;
} PhotoRelationships;

@class Notification;
@class Entity;

@interface PhotoID : ServiceObjectID {}
@end

@interface _Photo : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PhotoID* objectID;

@property (nonatomic, strong) NSNumber* height;

@property (atomic) int32_t heightValue;
- (int32_t)heightValue;
- (void)setHeightValue:(int32_t)value_;

//- (BOOL)validateHeight:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* prefix;

//- (BOOL)validatePrefix:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* source;

//- (BOOL)validateSource:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* width;

@property (atomic) int32_t widthValue;
- (int32_t)widthValue;
- (void)setWidthValue:(int32_t)value_;

//- (BOOL)validateWidth:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Notification *photoBigFor;

//- (BOOL)validatePhotoBigFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Entity *photoFor;

//- (BOOL)validatePhotoFor:(id*)value_ error:(NSError**)error_;

@end

@interface _Photo (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveHeight;
- (void)setPrimitiveHeight:(NSNumber*)value;

- (int32_t)primitiveHeightValue;
- (void)setPrimitiveHeightValue:(int32_t)value_;

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSString*)primitivePrefix;
- (void)setPrimitivePrefix:(NSString*)value;

- (NSString*)primitiveSource;
- (void)setPrimitiveSource:(NSString*)value;

- (NSNumber*)primitiveWidth;
- (void)setPrimitiveWidth:(NSNumber*)value;

- (int32_t)primitiveWidthValue;
- (void)setPrimitiveWidthValue:(int32_t)value_;

- (Notification*)primitivePhotoBigFor;
- (void)setPrimitivePhotoBigFor:(Notification*)value;

- (Entity*)primitivePhotoFor;
- (void)setPrimitivePhotoFor:(Entity*)value;

@end
