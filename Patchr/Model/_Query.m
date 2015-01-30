// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.m instead.

#import "_Query.h"

const struct QueryAttributes QueryAttributes = {
	.limit = @"limit",
	.name = @"name",
	.offset = @"offset",
	.path = @"path",
};

const struct QueryRelationships QueryRelationships = {
	.queryResults = @"queryResults",
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

	if ([key isEqualToString:@"limitValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"limit"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"offsetValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"offset"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic limit;

- (int64_t)limitValue {
	NSNumber *result = [self limit];
	return [result longLongValue];
}

- (void)setLimitValue:(int64_t)value_ {
	[self setLimit:@(value_)];
}

- (int64_t)primitiveLimitValue {
	NSNumber *result = [self primitiveLimit];
	return [result longLongValue];
}

- (void)setPrimitiveLimitValue:(int64_t)value_ {
	[self setPrimitiveLimit:@(value_)];
}

@dynamic name;

@dynamic offset;

- (int64_t)offsetValue {
	NSNumber *result = [self offset];
	return [result longLongValue];
}

- (void)setOffsetValue:(int64_t)value_ {
	[self setOffset:@(value_)];
}

- (int64_t)primitiveOffsetValue {
	NSNumber *result = [self primitiveOffset];
	return [result longLongValue];
}

- (void)setPrimitiveOffsetValue:(int64_t)value_ {
	[self setPrimitiveOffset:@(value_)];
}

@dynamic path;

@dynamic queryResults;

- (NSMutableSet*)queryResultsSet {
	[self willAccessValueForKey:@"queryResults"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"queryResults"];

	[self didAccessValueForKey:@"queryResults"];
	return result;
}

@end

