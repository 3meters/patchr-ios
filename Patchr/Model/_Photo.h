// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Photo.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct PhotoAttributes {
	__unsafe_unretained NSString *createdDate;
	__unsafe_unretained NSString *height;
	__unsafe_unretained NSString *prefix;
	__unsafe_unretained NSString *resizerActive;
	__unsafe_unretained NSString *resizerHeight;
	__unsafe_unretained NSString *resizerWidth;
	__unsafe_unretained NSString *source;
	__unsafe_unretained NSString *suffix;
	__unsafe_unretained NSString *usingDefault;
	__unsafe_unretained NSString *width;
} PhotoAttributes;

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

@property (nonatomic, strong) NSNumber* resizerActive;

@property (atomic) BOOL resizerActiveValue;
- (BOOL)resizerActiveValue;
- (void)setResizerActiveValue:(BOOL)value_;

//- (BOOL)validateResizerActive:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* resizerHeight;

@property (atomic) int32_t resizerHeightValue;
- (int32_t)resizerHeightValue;
- (void)setResizerHeightValue:(int32_t)value_;

//- (BOOL)validateResizerHeight:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* resizerWidth;

@property (atomic) int32_t resizerWidthValue;
- (int32_t)resizerWidthValue;
- (void)setResizerWidthValue:(int32_t)value_;

//- (BOOL)validateResizerWidth:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* source;

//- (BOOL)validateSource:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* suffix;

//- (BOOL)validateSuffix:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* usingDefault;

@property (atomic) BOOL usingDefaultValue;
- (BOOL)usingDefaultValue;
- (void)setUsingDefaultValue:(BOOL)value_;

//- (BOOL)validateUsingDefault:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* width;

@property (atomic) int32_t widthValue;
- (int32_t)widthValue;
- (void)setWidthValue:(int32_t)value_;

//- (BOOL)validateWidth:(id*)value_ error:(NSError**)error_;

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

- (NSNumber*)primitiveResizerActive;
- (void)setPrimitiveResizerActive:(NSNumber*)value;

- (BOOL)primitiveResizerActiveValue;
- (void)setPrimitiveResizerActiveValue:(BOOL)value_;

- (NSNumber*)primitiveResizerHeight;
- (void)setPrimitiveResizerHeight:(NSNumber*)value;

- (int32_t)primitiveResizerHeightValue;
- (void)setPrimitiveResizerHeightValue:(int32_t)value_;

- (NSNumber*)primitiveResizerWidth;
- (void)setPrimitiveResizerWidth:(NSNumber*)value;

- (int32_t)primitiveResizerWidthValue;
- (void)setPrimitiveResizerWidthValue:(int32_t)value_;

- (NSString*)primitiveSource;
- (void)setPrimitiveSource:(NSString*)value;

- (NSString*)primitiveSuffix;
- (void)setPrimitiveSuffix:(NSString*)value;

- (NSNumber*)primitiveUsingDefault;
- (void)setPrimitiveUsingDefault:(NSNumber*)value;

- (BOOL)primitiveUsingDefaultValue;
- (void)setPrimitiveUsingDefaultValue:(BOOL)value_;

- (NSNumber*)primitiveWidth;
- (void)setPrimitiveWidth:(NSNumber*)value;

- (int32_t)primitiveWidthValue;
- (void)setPrimitiveWidthValue:(int32_t)value_;

@end
