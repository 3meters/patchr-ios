// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Patch.h instead.

@import CoreData;
#import "Entity.h"

extern const struct PatchAttributes {
	__unsafe_unretained NSString *countMessages;
	__unsafe_unretained NSString *userHasMessaged;
} PatchAttributes;

@interface PatchID : EntityID {}
@end

@interface _Patch : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PatchID* objectID;

@property (nonatomic, strong) NSNumber* countMessages;

@property (atomic) int64_t countMessagesValue;
- (int64_t)countMessagesValue;
- (void)setCountMessagesValue:(int64_t)value_;

//- (BOOL)validateCountMessages:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* userHasMessaged;

@property (atomic) BOOL userHasMessagedValue;
- (BOOL)userHasMessagedValue;
- (void)setUserHasMessagedValue:(BOOL)value_;

//- (BOOL)validateUserHasMessaged:(id*)value_ error:(NSError**)error_;

@end

@interface _Patch (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCountMessages;
- (void)setPrimitiveCountMessages:(NSNumber*)value;

- (int64_t)primitiveCountMessagesValue;
- (void)setPrimitiveCountMessagesValue:(int64_t)value_;

- (NSNumber*)primitiveUserHasMessaged;
- (void)setPrimitiveUserHasMessaged:(NSNumber*)value;

- (BOOL)primitiveUserHasMessagedValue;
- (void)setPrimitiveUserHasMessagedValue:(BOOL)value_;

@end
