// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Link.m instead.

#import "_Link.h"

const struct LinkAttributes LinkAttributes = {
	.enabled = @"enabled",
	.fromId = @"fromId",
	.fromSchema = @"fromSchema",
	.id_ = @"id_",
	.toId = @"toId",
	.toSchema = @"toSchema",
	.type = @"type",
};

@implementation LinkID
@end

@implementation _Link

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Link" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Link";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Link" inManagedObjectContext:moc_];
}

- (LinkID*)objectID {
	return (LinkID*)[super objectID];
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

@dynamic id_;

@dynamic toId;

@dynamic toSchema;

@dynamic type;

@end

