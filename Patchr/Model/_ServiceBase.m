// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServiceBase.m instead.

#import "_ServiceBase.h"

const struct ServiceBaseAttributes ServiceBaseAttributes = {
	.activityDate = @"activityDate",
	.createdDate = @"createdDate",
	.creatorId = @"creatorId",
	.id_ = @"id_",
	.locked = @"locked",
	.modifiedDate = @"modifiedDate",
	.modifierId = @"modifierId",
	.name = @"name",
	.namelc = @"namelc",
	.ownerId = @"ownerId",
	.position = @"position",
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

	if ([key isEqualToString:@"lockedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"locked"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"positionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"position"];
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

@dynamic id_;

@dynamic locked;

- (BOOL)lockedValue {
	NSNumber *result = [self locked];
	return [result boolValue];
}

- (void)setLockedValue:(BOOL)value_ {
	[self setLocked:@(value_)];
}

- (BOOL)primitiveLockedValue {
	NSNumber *result = [self primitiveLocked];
	return [result boolValue];
}

- (void)setPrimitiveLockedValue:(BOOL)value_ {
	[self setPrimitiveLocked:@(value_)];
}

@dynamic modifiedDate;

@dynamic modifierId;

@dynamic name;

@dynamic namelc;

@dynamic ownerId;

@dynamic position;

- (int32_t)positionValue {
	NSNumber *result = [self position];
	return [result intValue];
}

- (void)setPositionValue:(int32_t)value_ {
	[self setPosition:@(value_)];
}

- (int32_t)primitivePositionValue {
	NSNumber *result = [self primitivePosition];
	return [result intValue];
}

- (void)setPrimitivePositionValue:(int32_t)value_ {
	[self setPrimitivePosition:@(value_)];
}

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

