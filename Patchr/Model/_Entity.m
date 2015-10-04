// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Entity.m instead.

#import "_Entity.h"

const struct EntityAttributes EntityAttributes = {
	.count = @"count",
	.countLikes = @"countLikes",
	.countPending = @"countPending",
	.countWatching = @"countWatching",
	.description_ = @"description_",
	.image = @"image",
	.linkCounts = @"linkCounts",
	.patchId = @"patchId",
	.rank = @"rank",
	.reason = @"reason",
	.score = @"score",
	.subtitle = @"subtitle",
	.userLikes = @"userLikes",
	.userLikesId = @"userLikesId",
	.userWatchId = @"userWatchId",
	.userWatchJustApproved = @"userWatchJustApproved",
	.userWatchMuted = @"userWatchMuted",
	.userWatchStatus = @"userWatchStatus",
	.visibility = @"visibility",
};

const struct EntityRelationships EntityRelationships = {
	.link = @"link",
	.location = @"location",
	.photo = @"photo",
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
	if ([key isEqualToString:@"countLikesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"countLikes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"countPendingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"countPending"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"countWatchingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"countWatching"];
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
	if ([key isEqualToString:@"userLikesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userLikes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"userWatchJustApprovedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userWatchJustApproved"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"userWatchMutedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userWatchMuted"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"userWatchStatusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userWatchStatus"];
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

@dynamic countLikes;

- (int64_t)countLikesValue {
	NSNumber *result = [self countLikes];
	return [result longLongValue];
}

- (void)setCountLikesValue:(int64_t)value_ {
	[self setCountLikes:@(value_)];
}

- (int64_t)primitiveCountLikesValue {
	NSNumber *result = [self primitiveCountLikes];
	return [result longLongValue];
}

- (void)setPrimitiveCountLikesValue:(int64_t)value_ {
	[self setPrimitiveCountLikes:@(value_)];
}

@dynamic countPending;

- (int64_t)countPendingValue {
	NSNumber *result = [self countPending];
	return [result longLongValue];
}

- (void)setCountPendingValue:(int64_t)value_ {
	[self setCountPending:@(value_)];
}

- (int64_t)primitiveCountPendingValue {
	NSNumber *result = [self primitiveCountPending];
	return [result longLongValue];
}

- (void)setPrimitiveCountPendingValue:(int64_t)value_ {
	[self setPrimitiveCountPending:@(value_)];
}

@dynamic countWatching;

- (int64_t)countWatchingValue {
	NSNumber *result = [self countWatching];
	return [result longLongValue];
}

- (void)setCountWatchingValue:(int64_t)value_ {
	[self setCountWatching:@(value_)];
}

- (int64_t)primitiveCountWatchingValue {
	NSNumber *result = [self primitiveCountWatching];
	return [result longLongValue];
}

- (void)setPrimitiveCountWatchingValue:(int64_t)value_ {
	[self setPrimitiveCountWatching:@(value_)];
}

@dynamic description_;

@dynamic image;

@dynamic linkCounts;

@dynamic patchId;

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

@dynamic userLikes;

- (BOOL)userLikesValue {
	NSNumber *result = [self userLikes];
	return [result boolValue];
}

- (void)setUserLikesValue:(BOOL)value_ {
	[self setUserLikes:@(value_)];
}

- (BOOL)primitiveUserLikesValue {
	NSNumber *result = [self primitiveUserLikes];
	return [result boolValue];
}

- (void)setPrimitiveUserLikesValue:(BOOL)value_ {
	[self setPrimitiveUserLikes:@(value_)];
}

@dynamic userLikesId;

@dynamic userWatchId;

@dynamic userWatchJustApproved;

- (BOOL)userWatchJustApprovedValue {
	NSNumber *result = [self userWatchJustApproved];
	return [result boolValue];
}

- (void)setUserWatchJustApprovedValue:(BOOL)value_ {
	[self setUserWatchJustApproved:@(value_)];
}

- (BOOL)primitiveUserWatchJustApprovedValue {
	NSNumber *result = [self primitiveUserWatchJustApproved];
	return [result boolValue];
}

- (void)setPrimitiveUserWatchJustApprovedValue:(BOOL)value_ {
	[self setPrimitiveUserWatchJustApproved:@(value_)];
}

@dynamic userWatchMuted;

- (BOOL)userWatchMutedValue {
	NSNumber *result = [self userWatchMuted];
	return [result boolValue];
}

- (void)setUserWatchMutedValue:(BOOL)value_ {
	[self setUserWatchMuted:@(value_)];
}

- (BOOL)primitiveUserWatchMutedValue {
	NSNumber *result = [self primitiveUserWatchMuted];
	return [result boolValue];
}

- (void)setPrimitiveUserWatchMutedValue:(BOOL)value_ {
	[self setPrimitiveUserWatchMuted:@(value_)];
}

@dynamic userWatchStatus;

- (PAWatchStatus)userWatchStatusValue {
	NSNumber *result = [self userWatchStatus];
	return [result shortValue];
}

- (void)setUserWatchStatusValue:(PAWatchStatus)value_ {
	[self setUserWatchStatus:@(value_)];
}

- (PAWatchStatus)primitiveUserWatchStatusValue {
	NSNumber *result = [self primitiveUserWatchStatus];
	return [result shortValue];
}

- (void)setPrimitiveUserWatchStatusValue:(PAWatchStatus)value_ {
	[self setPrimitiveUserWatchStatus:@(value_)];
}

@dynamic visibility;

@dynamic link;

@dynamic location;

@dynamic photo;

@end

