// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Place.m instead.

#import "_Place.h"

const struct PlaceAttributes PlaceAttributes = {
	.address = @"address",
	.categoryId = @"categoryId",
	.categoryName = @"categoryName",
	.city = @"city",
	.country = @"country",
	.phone = @"phone",
	.postalCode = @"postalCode",
	.region = @"region",
};

@implementation PlaceID
@end

@implementation _Place

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Place" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Place";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Place" inManagedObjectContext:moc_];
}

- (PlaceID*)objectID {
	return (PlaceID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic address;

@dynamic categoryId;

@dynamic categoryName;

@dynamic city;

@dynamic country;

@dynamic phone;

@dynamic postalCode;

@dynamic region;

@end

