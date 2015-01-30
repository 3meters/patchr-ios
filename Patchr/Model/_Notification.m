// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Notification.m instead.

#import "_Notification.h"

const struct NotificationAttributes NotificationAttributes = {
	.event = @"event",
	.parentId = @"parentId",
	.priority = @"priority",
	.sentDate = @"sentDate",
	.summary = @"summary",
	.targetId = @"targetId",
	.ticker = @"ticker",
	.trigger = @"trigger",
	.userId = @"userId",
};

const struct NotificationRelationships NotificationRelationships = {
	.photoBig = @"photoBig",
};

@implementation NotificationID
@end

@implementation _Notification

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Notification";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:moc_];
}

- (NotificationID*)objectID {
	return (NotificationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"priorityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"priority"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic event;

@dynamic parentId;

@dynamic priority;

- (double)priorityValue {
	NSNumber *result = [self priority];
	return [result doubleValue];
}

- (void)setPriorityValue:(double)value_ {
	[self setPriority:@(value_)];
}

- (double)primitivePriorityValue {
	NSNumber *result = [self primitivePriority];
	return [result doubleValue];
}

- (void)setPrimitivePriorityValue:(double)value_ {
	[self setPrimitivePriority:@(value_)];
}

@dynamic sentDate;

@dynamic summary;

@dynamic targetId;

@dynamic ticker;

@dynamic trigger;

@dynamic userId;

@dynamic photoBig;

@end

