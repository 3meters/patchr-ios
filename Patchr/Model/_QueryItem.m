// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to QueryItem.m instead.

#import "_QueryItem.h"

const struct QueryItemAttributes QueryItemAttributes = {
	.modifiedDate = @"modifiedDate",
	.position = @"position",
	.sortDate = @"sortDate",
};

const struct QueryItemRelationships QueryItemRelationships = {
	.query = @"query",
	.serviceBase = @"serviceBase",
};

@implementation QueryItemID
@end

@implementation _QueryItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"QueryItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"QueryItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"QueryItem" inManagedObjectContext:moc_];
}

- (QueryItemID*)objectID {
	return (QueryItemID*)[super objectID];
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

@dynamic modifiedDate;

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

@dynamic query;

@dynamic serviceBase;

@end

