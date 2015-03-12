// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Entity.m instead.

#import "_Entity.h"

const struct EntityAttributes EntityAttributes = {
	.count = @"count",
	.description_ = @"description_",
	.linkedCounts = @"linkedCounts",
	.patchId = @"patchId",
	.privacy = @"privacy",
	.rank = @"rank",
	.reason = @"reason",
	.score = @"score",
	.subtitle = @"subtitle",
	.visibility = @"visibility",
};

const struct EntityRelationships EntityRelationships = {
	.location = @"location",
	.photo = @"photo",
	.queryResults = @"queryResults",
};

const struct EntityUserInfo EntityUserInfo = {
	.additionalHeaderFileName = @"PAEnums.h",
};

@implementation EntityID
@end

@implementation _Entity

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Entity";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Entity" inManagedObjectContext:moc_];
}

- (EntityID*)objectID {
	return (EntityID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"countValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"count"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"rankValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"rank"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"scoreValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"score"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"visibilityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"visibility"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic count;

- (int64_t)countValue {
	NSNumber *result = [self count];
	return [result longLongValue];
}

- (void)setCountValue:(int64_t)value_ {
	[self setCount:@(value_)];
}

- (int64_t)primitiveCountValue {
	NSNumber *result = [self primitiveCount];
	return [result longLongValue];
}

- (void)setPrimitiveCountValue:(int64_t)value_ {
	[self setPrimitiveCount:@(value_)];
}

@dynamic description_;

@dynamic linkedCounts;

@dynamic patchId;

@dynamic privacy;

@dynamic rank;

- (int64_t)rankValue {
	NSNumber *result = [self rank];
	return [result longLongValue];
}

- (void)setRankValue:(int64_t)value_ {
	[self setRank:@(value_)];
}

- (int64_t)primitiveRankValue {
	NSNumber *result = [self primitiveRank];
	return [result longLongValue];
}

- (void)setPrimitiveRankValue:(int64_t)value_ {
	[self setPrimitiveRank:@(value_)];
}

@dynamic reason;

@dynamic score;

- (int64_t)scoreValue {
	NSNumber *result = [self score];
	return [result longLongValue];
}

- (void)setScoreValue:(int64_t)value_ {
	[self setScore:@(value_)];
}

- (int64_t)primitiveScoreValue {
	NSNumber *result = [self primitiveScore];
	return [result longLongValue];
}

- (void)setPrimitiveScoreValue:(int64_t)value_ {
	[self setPrimitiveScore:@(value_)];
}

@dynamic subtitle;

@dynamic visibility;

- (PAVisibilityLevel)visibilityValue {
	NSNumber *result = [self visibility];
	return [result shortValue];
}

- (void)setVisibilityValue:(PAVisibilityLevel)value_ {
	[self setVisibility:@(value_)];
}

- (PAVisibilityLevel)primitiveVisibilityValue {
	NSNumber *result = [self primitiveVisibility];
	return [result shortValue];
}

- (void)setPrimitiveVisibilityValue:(PAVisibilityLevel)value_ {
	[self setPrimitiveVisibility:@(value_)];
}

@dynamic location;

@dynamic photo;

@dynamic queryResults;

- (NSMutableSet*)queryResultsSet {
	[self willAccessValueForKey:@"queryResults"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"queryResults"];

	[self didAccessValueForKey:@"queryResults"];
	return result;
}

@end

