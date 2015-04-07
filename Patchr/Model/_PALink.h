// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to PALink.h instead.

@import CoreData;
#import "ServiceBase.h"

extern const struct PALinkAttributes {
	__unsafe_unretained NSString *enabled;
	__unsafe_unretained NSString *fromId;
	__unsafe_unretained NSString *fromSchema;
	__unsafe_unretained NSString *toId;
	__unsafe_unretained NSString *toSchema;
} PALinkAttributes;

@interface PALinkID : ServiceBaseID {}
@end

@interface _PALink : ServiceBase {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PALinkID* objectID;

@property (nonatomic, strong) NSNumber* enabled;

@property (atomic) BOOL enabledValue;
- (BOOL)enabledValue;
- (void)setEnabledValue:(BOOL)value_;

//- (BOOL)validateEnabled:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* fromId;

//- (BOOL)validateFromId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* fromSchema;

//- (BOOL)validateFromSchema:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* toId;

//- (BOOL)validateToId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* toSchema;

//- (BOOL)validateToSchema:(id*)value_ error:(NSError**)error_;

@end

@interface _PALink (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveEnabled;
- (void)setPrimitiveEnabled:(NSNumber*)value;

- (BOOL)primitiveEnabledValue;
- (void)setPrimitiveEnabledValue:(BOOL)value_;

- (NSString*)primitiveFromId;
- (void)setPrimitiveFromId:(NSString*)value;

- (NSString*)primitiveFromSchema;
- (void)setPrimitiveFromSchema:(NSString*)value;

- (NSString*)primitiveToId;
- (void)setPrimitiveToId:(NSString*)value;

- (NSString*)primitiveToSchema;
- (void)setPrimitiveToSchema:(NSString*)value;

@end
