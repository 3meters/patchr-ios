// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.h instead.

@import CoreData;
#import "Entity.h"

extern const struct MessageAttributes {
	__unsafe_unretained NSString *replyToId;
	__unsafe_unretained NSString *rootId;
} MessageAttributes;

extern const struct MessageRelationships {
	__unsafe_unretained NSString *patch;
	__unsafe_unretained NSString *replyTo;
} MessageRelationships;

@class Patch;
@class User;

@interface MessageID : EntityID {}
@end

@interface _Message : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) MessageID* objectID;

@property (nonatomic, strong) NSString* replyToId;

//- (BOOL)validateReplyToId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* rootId;

//- (BOOL)validateRootId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Patch *patch;

//- (BOOL)validatePatch:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) User *replyTo;

//- (BOOL)validateReplyTo:(id*)value_ error:(NSError**)error_;

@end

@interface _Message (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveReplyToId;
- (void)setPrimitiveReplyToId:(NSString*)value;

- (NSString*)primitiveRootId;
- (void)setPrimitiveRootId:(NSString*)value;

- (Patch*)primitivePatch;
- (void)setPrimitivePatch:(Patch*)value;

- (User*)primitiveReplyTo;
- (void)setPrimitiveReplyTo:(User*)value;

@end
