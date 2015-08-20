// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Shortcut.h instead.

@import CoreData;
#import "Entity.h"

extern const struct ShortcutAttributes {
	__unsafe_unretained NSString *entityId;
} ShortcutAttributes;

@interface ShortcutID : EntityID {}
@end

@interface _Shortcut : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ShortcutID* objectID;

@property (nonatomic, strong) NSString* entityId;

//- (BOOL)validateEntityId:(id*)value_ error:(NSError**)error_;

@end

@interface _Shortcut (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveEntityId;
- (void)setPrimitiveEntityId:(NSString*)value;

@end
