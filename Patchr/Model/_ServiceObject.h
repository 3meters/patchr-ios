// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServiceObject.h instead.

@import CoreData;

extern const struct ServiceObjectAttributes {
	__unsafe_unretained NSString *updateScope;
} ServiceObjectAttributes;

@interface ServiceObjectID : NSManagedObjectID {}
@end

@interface _ServiceObject : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ServiceObjectID* objectID;

@property (nonatomic, strong) NSString* updateScope;

//- (BOOL)validateUpdateScope:(id*)value_ error:(NSError**)error_;

@end

@interface _ServiceObject (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveUpdateScope;
- (void)setPrimitiveUpdateScope:(NSString*)value;

@end
