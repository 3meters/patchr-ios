// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Patch.h instead.

@import CoreData;
#import "Entity.h"

extern const struct PatchAttributes {
	__unsafe_unretained NSString *signalFence;
} PatchAttributes;

extern const struct PatchRelationships {
	__unsafe_unretained NSString *category;
	__unsafe_unretained NSString *place;
} PatchRelationships;

@class PACategory;
@class Place;

@interface PatchID : EntityID {}
@end

@interface _Patch : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PatchID* objectID;

@property (nonatomic, strong) NSNumber* signalFence;

@property (atomic) double signalFenceValue;
- (double)signalFenceValue;
- (void)setSignalFenceValue:(double)value_;

//- (BOOL)validateSignalFence:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) PACategory *category;

//- (BOOL)validateCategory:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Place *place;

//- (BOOL)validatePlace:(id*)value_ error:(NSError**)error_;

@end

@interface _Patch (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveSignalFence;
- (void)setPrimitiveSignalFence:(NSNumber*)value;

- (double)primitiveSignalFenceValue;
- (void)setPrimitiveSignalFenceValue:(double)value_;

- (PACategory*)primitiveCategory;
- (void)setPrimitiveCategory:(PACategory*)value;

- (Place*)primitivePlace;
- (void)setPrimitivePlace:(Place*)value;

@end
