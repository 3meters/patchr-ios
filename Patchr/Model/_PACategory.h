// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to PACategory.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct PACategoryAttributes {
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *name;
} PACategoryAttributes;

extern const struct PACategoryRelationships {
	__unsafe_unretained NSString *categories;
	__unsafe_unretained NSString *patches;
	__unsafe_unretained NSString *photo;
} PACategoryRelationships;

@class PACategory;
@class Patch;
@class Photo;

@interface PACategoryID : ServiceObjectID {}
@end

@interface _PACategory : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PACategoryID* objectID;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *categories;

- (NSMutableSet*)categoriesSet;

@property (nonatomic, strong) NSSet *patches;

- (NSMutableSet*)patchesSet;

@property (nonatomic, strong) Photo *photo;

//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;

@end

@interface _PACategory (CategoriesCoreDataGeneratedAccessors)
- (void)addCategories:(NSSet*)value_;
- (void)removeCategories:(NSSet*)value_;
- (void)addCategoriesObject:(PACategory*)value_;
- (void)removeCategoriesObject:(PACategory*)value_;

@end

@interface _PACategory (PatchesCoreDataGeneratedAccessors)
- (void)addPatches:(NSSet*)value_;
- (void)removePatches:(NSSet*)value_;
- (void)addPatchesObject:(Patch*)value_;
- (void)removePatchesObject:(Patch*)value_;

@end

@interface _PACategory (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSMutableSet*)primitiveCategories;
- (void)setPrimitiveCategories:(NSMutableSet*)value;

- (NSMutableSet*)primitivePatches;
- (void)setPrimitivePatches:(NSMutableSet*)value;

- (Photo*)primitivePhoto;
- (void)setPrimitivePhoto:(Photo*)value;

@end
