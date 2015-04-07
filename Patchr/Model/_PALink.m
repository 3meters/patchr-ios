// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to PALink.m instead.

#import "_PALink.h"

const struct PALinkAttributes PALinkAttributes = {
	.enabled = @"enabled",
	.fromId = @"fromId",
	.fromSchema = @"fromSchema",
	.toId = @"toId",
	.toSchema = @"toSchema",
};

@implementation PALinkID
@end

@implementation _PALink

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"PALink" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"PALink";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"PALink" inManagedObjectContext:moc_];
}

- (PALinkID*)objectID {
	return (PALinkID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"enabledValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"enabled"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic enabled;

- (BOOL)enabledValue {
	NSNumber *result = [self enabled];
	return [result boolValue];
}

- (void)setEnabledValue:(BOOL)value_ {
	[self setEnabled:@(value_)];
}

- (BOOL)primitiveEnabledValue {
	NSNumber *result = [self primitiveEnabled];
	return [result boolValue];
}

- (void)setPrimitiveEnabledValue:(BOOL)value_ {
	[self setPrimitiveEnabled:@(value_)];
}

@dynamic fromId;

@dynamic fromSchema;

@dynamic toId;

@dynamic toSchema;

@end

