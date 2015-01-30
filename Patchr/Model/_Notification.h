// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Notification.h instead.

@import CoreData;
#import "Entity.h"

extern const struct NotificationAttributes {
	__unsafe_unretained NSString *event;
	__unsafe_unretained NSString *parentId;
	__unsafe_unretained NSString *priority;
	__unsafe_unretained NSString *sentDate;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *targetId;
	__unsafe_unretained NSString *ticker;
	__unsafe_unretained NSString *trigger;
	__unsafe_unretained NSString *userId;
} NotificationAttributes;

extern const struct NotificationRelationships {
	__unsafe_unretained NSString *photoBig;
} NotificationRelationships;

@class Photo;

@interface NotificationID : EntityID {}
@end

@interface _Notification : Entity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) NotificationID* objectID;

@property (nonatomic, strong) NSString* event;

//- (BOOL)validateEvent:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* parentId;

//- (BOOL)validateParentId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* priority;

@property (atomic) double priorityValue;
- (double)priorityValue;
- (void)setPriorityValue:(double)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* sentDate;

//- (BOOL)validateSentDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* summary;

//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* targetId;

//- (BOOL)validateTargetId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* ticker;

//- (BOOL)validateTicker:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* trigger;

//- (BOOL)validateTrigger:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* userId;

//- (BOOL)validateUserId:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Photo *photoBig;

//- (BOOL)validatePhotoBig:(id*)value_ error:(NSError**)error_;

@end

@interface _Notification (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveEvent;
- (void)setPrimitiveEvent:(NSString*)value;

- (NSString*)primitiveParentId;
- (void)setPrimitiveParentId:(NSString*)value;

- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (double)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(double)value_;

- (NSDate*)primitiveSentDate;
- (void)setPrimitiveSentDate:(NSDate*)value;

- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;

- (NSString*)primitiveTargetId;
- (void)setPrimitiveTargetId:(NSString*)value;

- (NSString*)primitiveTicker;
- (void)setPrimitiveTicker:(NSString*)value;

- (NSString*)primitiveTrigger;
- (void)setPrimitiveTrigger:(NSString*)value;

- (NSString*)primitiveUserId;
- (void)setPrimitiveUserId:(NSString*)value;

- (Photo*)primitivePhotoBig;
- (void)setPrimitivePhotoBig:(Photo*)value;

@end
