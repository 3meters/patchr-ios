// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Category.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct CategoryAttributes {
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *name;
} CategoryAttributes;

extern const struct CategoryRelationships {
	__unsafe_unretained NSString *categoryFor;
} CategoryRelationships;

@class Place;

@interface CategoryID : ServiceObjectID {}
@end

@interface _Category : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) CategoryID* objectID;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Place *categoryFor;

//- (BOOL)validateCategoryFor:(id*)value_ error:(NSError**)error_;

@end

@interface _Category (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (Place*)primitiveCategoryFor;
- (void)setPrimitiveCategoryFor:(Place*)value;

@end
