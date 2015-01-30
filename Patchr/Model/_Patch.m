// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Patch.m instead.

#import "_Patch.h"

const struct PatchAttributes PatchAttributes = {
	.signalFence = @"signalFence",
};

const struct PatchRelationships PatchRelationships = {
	.category = @"category",
	.place = @"place",
};

@implementation PatchID
@end

@implementation _Patch

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Patch" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Patch";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Patch" inManagedObjectContext:moc_];
}

- (PatchID*)objectID {
	return (PatchID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"signalFenceValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"signalFence"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic signalFence;

- (double)signalFenceValue {
	NSNumber *result = [self signalFence];
	return [result doubleValue];
}

- (void)setSignalFenceValue:(double)value_ {
	[self setSignalFence:@(value_)];
}

- (double)primitiveSignalFenceValue {
	NSNumber *result = [self primitiveSignalFence];
	return [result doubleValue];
}

- (void)setPrimitiveSignalFenceValue:(double)value_ {
	[self setPrimitiveSignalFence:@(value_)];
}

@dynamic category;

@dynamic place;

@end

