// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ProviderMap.m instead.

#import "_ProviderMap.h"

const struct ProviderMapAttributes ProviderMapAttributes = {
	.google = @"google",
	.googleReference = @"googleReference",
};

const struct ProviderMapRelationships ProviderMapRelationships = {
	.providerMapFor = @"providerMapFor",
};

@implementation ProviderMapID
@end

@implementation _ProviderMap

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ProviderMap" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ProviderMap";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ProviderMap" inManagedObjectContext:moc_];
}

- (ProviderMapID*)objectID {
	return (ProviderMapID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic google;

@dynamic googleReference;

@dynamic providerMapFor;

@end

