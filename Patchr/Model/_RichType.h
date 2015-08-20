// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RichType.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct RichTypeAttributes {
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *name;
} RichTypeAttributes;

@interface RichTypeID : ServiceObjectID {}
@end

@interface _RichType : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) RichTypeID* objectID;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@end

@interface _RichType (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

@end
