// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Statistic.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct StatisticAttributes {
	__unsafe_unretained NSString *count;
	__unsafe_unretained NSString *enabled;
	__unsafe_unretained NSString *schema;
	__unsafe_unretained NSString *type;
} StatisticAttributes;

extern const struct StatisticRelationships {
	__unsafe_unretained NSString *entityIn;
	__unsafe_unretained NSString *entityOut;
} StatisticRelationships;

@class Entity;
@class Entity;

@interface StatisticID : ServiceObjectID {}
@end

@interface _Statistic : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) StatisticID* objectID;

@property (nonatomic, strong) NSNumber* count;

@property (atomic) int64_t countValue;
- (int64_t)countValue;
- (void)setCountValue:(int64_t)value_;

//- (BOOL)validateCount:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* enabled;

@property (atomic) BOOL enabledValue;
- (BOOL)enabledValue;
- (void)setEnabledValue:(BOOL)value_;

//- (BOOL)validateEnabled:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* schema;

//- (BOOL)validateSchema:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Entity *entityIn;

//- (BOOL)validateEntityIn:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Entity *entityOut;

//- (BOOL)validateEntityOut:(id*)value_ error:(NSError**)error_;

@end

@interface _Statistic (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCount;
- (void)setPrimitiveCount:(NSNumber*)value;

- (int64_t)primitiveCountValue;
- (void)setPrimitiveCountValue:(int64_t)value_;

- (NSNumber*)primitiveEnabled;
- (void)setPrimitiveEnabled:(NSNumber*)value;

- (BOOL)primitiveEnabledValue;
- (void)setPrimitiveEnabledValue:(BOOL)value_;

- (NSString*)primitiveSchema;
- (void)setPrimitiveSchema:(NSString*)value;

- (Entity*)primitiveEntityIn;
- (void)setPrimitiveEntityIn:(Entity*)value;

- (Entity*)primitiveEntityOut;
- (void)setPrimitiveEntityOut:(Entity*)value;

@end
