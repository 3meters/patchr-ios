// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Query.m instead.

#import "_Query.h"

const struct QueryAttributes QueryAttributes = {
	.name = @"name",
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

	return keyPaths;
}

@dynamic name;

@dynamic queryResults;

- (NSMutableSet*)queryResultsSet {
	[self willAccessValueForKey:@"queryResults"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"queryResults"];

	[self didAccessValueForKey:@"queryResults"];
	return result;
}

@end

