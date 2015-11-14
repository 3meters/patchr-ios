// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RichType.m instead.

#import "_RichType.h"

const struct RichTypeAttributes RichTypeAttributes = {
	.id_ = @"id_",
	.name = @"name",
};

const struct RichTypeRelationships RichTypeRelationships = {
	.categoryFor = @"categoryFor",
};

@implementation RichTypeID
@end

@implementation _RichType

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RichType" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RichType";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RichType" inManagedObjectContext:moc_];
}

- (RichTypeID*)objectID {
	return (RichTypeID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic id_;

@dynamic name;

@dynamic categoryFor;

@end

