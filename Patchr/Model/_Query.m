// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.m instead.

#import "_Query.h"

const struct QueryAttributes QueryAttributes = {
	.activityDate = @"activityDate",
	.entityId = @"entityId",
	.executed = @"executed",
	.id_ = @"id_",
	.more = @"more",
	.name = @"name",
	.offset = @"offset",
	.offsetDate = @"offsetDate",
	.pageSize = @"pageSize",
	.sidecar = @"sidecar",
};

const struct QueryRelationships QueryRelationships = {
	.contextEntity = @"contextEntity",
	.queryItems = @"queryItems",
};

@implementation QueryID
@end

@implementation _Query

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Query" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Query";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Query" inManagedObjectContext:moc_];
}

- (QueryID*)objectID {
	return (QueryID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"activityDateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"activityDate"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"executedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"executed"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"moreValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"more"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"offsetValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"offset"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"pageSizeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"pageSize"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic activityDate;

- (int64_t)activityDateValue {
	NSNumber *result = [self activityDate];
	return [result longLongValue];
}

- (void)setActivityDateValue:(int64_t)value_ {
	[self setActivityDate:@(value_)];
}

- (int64_t)primitiveActivityDateValue {
	NSNumber *result = [self primitiveActivityDate];
	return [result longLongValue];
}

- (void)setPrimitiveActivityDateValue:(int64_t)value_ {
	[self setPrimitiveActivityDate:@(value_)];
}

@dynamic entityId;

@dynamic executed;

- (BOOL)executedValue {
	NSNumber *result = [self executed];
	return [result boolValue];
}

- (void)setExecutedValue:(BOOL)value_ {
	[self setExecuted:@(value_)];
}

- (BOOL)primitiveExecutedValue {
	NSNumber *result = [self primitiveExecuted];
	return [result boolValue];
}

- (void)setPrimitiveExecutedValue:(BOOL)value_ {
	[self setPrimitiveExecuted:@(value_)];
}

@dynamic id_;

@dynamic more;

- (BOOL)moreValue {
	NSNumber *result = [self more];
	return [result boolValue];
}

- (void)setMoreValue:(BOOL)value_ {
	[self setMore:@(value_)];
}

- (BOOL)primitiveMoreValue {
	NSNumber *result = [self primitiveMore];
	return [result boolValue];
}

- (void)setPrimitiveMoreValue:(BOOL)value_ {
	[self setPrimitiveMore:@(value_)];
}

@dynamic name;

@dynamic offset;

- (int32_t)offsetValue {
	NSNumber *result = [self offset];
	return [result intValue];
}

- (void)setOffsetValue:(int32_t)value_ {
	[self setOffset:@(value_)];
}

- (int32_t)primitiveOffsetValue {
	NSNumber *result = [self primitiveOffset];
	return [result intValue];
}

- (void)setPrimitiveOffsetValue:(int32_t)value_ {
	[self setPrimitiveOffset:@(value_)];
}

@dynamic offsetDate;

@dynamic pageSize;

- (int32_t)pageSizeValue {
	NSNumber *result = [self pageSize];
	return [result intValue];
}

- (void)setPageSizeValue:(int32_t)value_ {
	[self setPageSize:@(value_)];
}

- (int32_t)primitivePageSizeValue {
	NSNumber *result = [self primitivePageSize];
	return [result intValue];
}

- (void)setPrimitivePageSizeValue:(int32_t)value_ {
	[self setPrimitivePageSize:@(value_)];
}

@dynamic sidecar;

@dynamic contextEntity;

@dynamic queryItems;

- (NSMutableSet*)queryItemsSet {
	[self willAccessValueForKey:@"queryItems"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"queryItems"];

	[self didAccessValueForKey:@"queryItems"];
	return result;
}

@end

