// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QueryResult.m instead.

#import "_QueryResult.h"

const struct QueryResultAttributes QueryResultAttributes = {
	.position = @"position",
	.sortDate = @"sortDate",
};

const struct QueryResultRelationships QueryResultRelationships = {
	.entity_ = @"entity_",
	.query = @"query",
};

@implementation QueryResultID
@end

@implementation _QueryResult

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QueryResult" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QueryResult";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QueryResult" inManagedObjectContext:moc_];
}

- (QueryResultID*)objectID {
	return (QueryResultID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"positionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"position"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic position;

- (int64_t)positionValue {
	NSNumber *result = [self position];
	return [result longLongValue];
}

- (void)setPositionValue:(int64_t)value_ {
	[self setPosition:@(value_)];
}

- (int64_t)primitivePositionValue {
	NSNumber *result = [self primitivePosition];
	return [result longLongValue];
}

- (void)setPrimitivePositionValue:(int64_t)value_ {
	[self setPrimitivePosition:@(value_)];
}

@dynamic sortDate;

@dynamic entity_;

@dynamic query;

@end

