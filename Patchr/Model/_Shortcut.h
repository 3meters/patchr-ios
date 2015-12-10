// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Shortcut.h instead.

@import CoreData;
#import "Entity.h"

extern const struct ShortcutAttributes {
	__unsafe_unretained NSString *entityId;
} ShortcutAttributes;

extern const struct ShortcutRelationships {
	__unsafe_unretained NSString *creatorFor;
	__unsafe_unretained NSString *messageFor;
	__unsafe_unretained NSString *modifierFor;
	__unsafe_unretained NSString *ownerFor;
	__unsafe_unretained NSString *patchFor;
	__unsafe_unretained NSString *placeFor;
	__unsafe_unretained NSString *recipientFor;
} ShortcutRelationships;

@class ServiceBase;
@class Message;
@class ServiceBase;
@class ServiceBase;
@class Message;
@class Patch;
@class Message;

@interface ShortcutID : EntityID {}
@end

@interface _Shortcut : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ShortcutID* objectID;

@property (nonatomic, strong) NSString* entityId;

//- (BOOL)validateEntityId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) ServiceBase *creatorFor;

//- (BOOL)validateCreatorFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Message *messageFor;

//- (BOOL)validateMessageFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) ServiceBase *modifierFor;

//- (BOOL)validateModifierFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) ServiceBase *ownerFor;

//- (BOOL)validateOwnerFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Message *patchFor;

//- (BOOL)validatePatchFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Patch *placeFor;

//- (BOOL)validatePlaceFor:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Message *recipientFor;

//- (BOOL)validateRecipientFor:(id*)value_ error:(NSError**)error_;

@end

@interface _Shortcut (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveEntityId;
- (void)setPrimitiveEntityId:(NSString*)value;

- (ServiceBase*)primitiveCreatorFor;
- (void)setPrimitiveCreatorFor:(ServiceBase*)value;

- (Message*)primitiveMessageFor;
- (void)setPrimitiveMessageFor:(Message*)value;

- (ServiceBase*)primitiveModifierFor;
- (void)setPrimitiveModifierFor:(ServiceBase*)value;

- (ServiceBase*)primitiveOwnerFor;
- (void)setPrimitiveOwnerFor:(ServiceBase*)value;

- (Message*)primitivePatchFor;
- (void)setPrimitivePatchFor:(Message*)value;

- (Patch*)primitivePlaceFor;
- (void)setPrimitivePlaceFor:(Patch*)value;

- (Message*)primitiveRecipientFor;
- (void)setPrimitiveRecipientFor:(Message*)value;

@end
