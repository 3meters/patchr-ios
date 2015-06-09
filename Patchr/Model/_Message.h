// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.h instead.

@import CoreData;
#import "Entity.h"

extern const struct MessageRelationships {
	__unsafe_unretained NSString *patch;
} MessageRelationships;

@class Shortcut;

@interface MessageID : EntityID {}
@end

@interface _Message : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) MessageID* objectID;

@property (nonatomic, strong) Shortcut *patch;

//- (BOOL)validatePatch:(id*)value_ error:(NSError**)error_;

@end

@interface _Message (CoreDataGeneratedPrimitiveAccessors)

- (Shortcut*)primitivePatch;
- (void)setPrimitivePatch:(Shortcut*)value;

@end
