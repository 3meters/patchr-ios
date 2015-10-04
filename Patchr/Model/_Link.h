// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Link.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct LinkAttributes {
	__unsafe_unretained NSString *enabled;
	__unsafe_unretained NSString *fromId;
	__unsafe_unretained NSString *fromSchema;
	__unsafe_unretained NSString *id_;
	__unsafe_unretained NSString *mute;
	__unsafe_unretained NSString *toId;
	__unsafe_unretained NSString *toSchema;
	__unsafe_unretained NSString *type;
} LinkAttributes;

@interface LinkID : ServiceObjectID {}
@end

@interface _Link : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) LinkID* objectID;

@property (nonatomic, strong) NSNumber* enabled;

@property (atomic) BOOL enabledValue;
- (BOOL)enabledValue;
- (void)setEnabledValue:(BOOL)value_;

//- (BOOL)validateEnabled:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* fromId;

//- (BOOL)validateFromId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* fromSchema;

//- (BOOL)validateFromSchema:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* id_;

//- (BOOL)validateId_:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* mute;

@property (atomic) BOOL muteValue;
- (BOOL)muteValue;
- (void)setMuteValue:(BOOL)value_;

//- (BOOL)validateMute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* toId;

//- (BOOL)validateToId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* toSchema;

//- (BOOL)validateToSchema:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;

@end

@interface _Link (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveEnabled;
- (void)setPrimitiveEnabled:(NSNumber*)value;

- (BOOL)primitiveEnabledValue;
- (void)setPrimitiveEnabledValue:(BOOL)value_;

- (NSString*)primitiveFromId;
- (void)setPrimitiveFromId:(NSString*)value;

- (NSString*)primitiveFromSchema;
- (void)setPrimitiveFromSchema:(NSString*)value;

- (NSString*)primitiveId_;
- (void)setPrimitiveId_:(NSString*)value;

- (NSNumber*)primitiveMute;
- (void)setPrimitiveMute:(NSNumber*)value;

- (BOOL)primitiveMuteValue;
- (void)setPrimitiveMuteValue:(BOOL)value_;

- (NSString*)primitiveToId;
- (void)setPrimitiveToId:(NSString*)value;

- (NSString*)primitiveToSchema;
- (void)setPrimitiveToSchema:(NSString*)value;

@end
