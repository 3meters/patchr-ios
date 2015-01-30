// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to PACategory.m instead.

#import "_PACategory.h"

const struct PACategoryAttributes PACategoryAttributes = {
	.id_ = @"id_",
	.name = @"name",
};

const struct PACategoryRelationships PACategoryRelationships = {
	.categories = @"categories",
	.patches = @"patches",
	.photo = @"photo",
};

@implementation PACategoryID
@end

@implementation _PACategory

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"PACategory" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"PACategory";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"PACategory" inManagedObjectContext:moc_];
}

- (PACategoryID*)objectID {
	return (PACategoryID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic id_;

@dynamic name;

@dynamic categories;

- (NSMutableSet*)categoriesSet {
	[self willAccessValueForKey:@"categories"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"categories"];

	[self didAccessValueForKey:@"categories"];
	return result;
}

@dynamic patches;

- (NSMutableSet*)patchesSet {
	[self willAccessValueForKey:@"patches"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"patches"];

	[self didAccessValueForKey:@"patches"];
	return result;
}

@dynamic photo;

@end

