// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServiceBase.m instead.

#import "_ServiceBase.h"

const struct ServiceBaseAttributes ServiceBaseAttributes = {
	.activityDate = @"activityDate",
	.createdDate = @"createdDate",
	.creatorId = @"creatorId",
	.decorated = @"decorated",
	.id_ = @"id_",
	.modifiedDate = @"modifiedDate",
	.modifierId = @"modifierId",
	.name = @"name",
	.namelc = @"namelc",
	.ownerId = @"ownerId",
	.refreshed = @"refreshed",
	.schema = @"schema",
	.sortDate = @"sortDate",
	.type = @"type",
};

const struct ServiceBaseRelationships ServiceBaseRelationships = {
	.creator = @"creator",
	.modifier = @"modifier",
	.owner = @"owner",
	.queriesContextFor = @"queriesContextFor",
	.queryItems = @"queryItems",
};

@implementation ServiceBaseID
@end

@implementation _ServiceBase

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ServiceBase" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ServiceBase";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ServiceBase" inManagedObjectContext:moc_];
}

- (ServiceBaseID*)objectID {
	return (ServiceBaseID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"decoratedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"decorated"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"refreshedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"refreshed"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic activityDate;

@dynamic createdDate;

@dynamic creatorId;

@dynamic decorated;

- (BOOL)decoratedValue {
	NSNumber *result = [self decorated];
	return [result boolValue];
}

- (void)setDecoratedValue:(BOOL)value_ {
	[self setDecorated:@(value_)];
}

- (BOOL)primitiveDecoratedValue {
	NSNumber *result = [self primitiveDecorated];
	return [result boolValue];
}

- (void)setPrimitiveDecoratedValue:(BOOL)value_ {
	[self setPrimitiveDecorated:@(value_)];
}

@dynamic id_;

@dynamic modifiedDate;

@dynamic modifierId;

@dynamic name;

@dynamic namelc;

@dynamic ownerId;

@dynamic refreshed;

- (BOOL)refreshedValue {
	NSNumber *result = [self refreshed];
	return [result boolValue];
}

- (void)setRefreshedValue:(BOOL)value_ {
	[self setRefreshed:@(value_)];
}

- (BOOL)primitiveRefreshedValue {
	NSNumber *result = [self primitiveRefreshed];
	return [result boolValue];
}

- (void)setPrimitiveRefreshedValue:(BOOL)value_ {
	[self setPrimitiveRefreshed:@(value_)];
}

@dynamic schema;

@dynamic sortDate;

@dynamic type;

@dynamic creator;

@dynamic modifier;

@dynamic owner;

@dynamic queriesContextFor;

- (NSMutableSet*)queriesContextForSet {
	[self willAccessValueForKey:@"queriesContextFor"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"queriesContextFor"];

	[self didAccessValueForKey:@"queriesContextFor"];
	return result;
}

@dynamic queryItems;

- (NSMutableSet*)queryItemsSet {
	[self willAccessValueForKey:@"queryItems"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"queryItems"];

	[self didAccessValueForKey:@"queryItems"];
	return result;
}

@end

