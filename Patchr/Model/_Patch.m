// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Patch.m instead.

#import "_Patch.h"

const struct PatchAttributes PatchAttributes = {
	.countMessages = @"countMessages",
	.userHasMessaged = @"userHasMessaged",
};

@implementation PatchID
@end

@implementation _Patch

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Patch" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Patch";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Patch" inManagedObjectContext:moc_];
}

- (PatchID*)objectID {
	return (PatchID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"countMessagesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"countMessages"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"userHasMessagedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userHasMessaged"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic countMessages;

- (int64_t)countMessagesValue {
	NSNumber *result = [self countMessages];
	return [result longLongValue];
}

- (void)setCountMessagesValue:(int64_t)value_ {
	[self setCountMessages:@(value_)];
}

- (int64_t)primitiveCountMessagesValue {
	NSNumber *result = [self primitiveCountMessages];
	return [result longLongValue];
}

- (void)setPrimitiveCountMessagesValue:(int64_t)value_ {
	[self setPrimitiveCountMessages:@(value_)];
}

@dynamic userHasMessaged;

- (BOOL)userHasMessagedValue {
	NSNumber *result = [self userHasMessaged];
	return [result boolValue];
}

- (void)setUserHasMessagedValue:(BOOL)value_ {
	[self setUserHasMessaged:@(value_)];
}

- (BOOL)primitiveUserHasMessagedValue {
	NSNumber *result = [self primitiveUserHasMessaged];
	return [result boolValue];
}

- (void)setPrimitiveUserHasMessagedValue:(BOOL)value_ {
	[self setPrimitiveUserHasMessaged:@(value_)];
}

@end

