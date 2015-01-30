// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ProviderMap.m instead.

#import "_ProviderMap.h"

const struct ProviderMapAttributes ProviderMapAttributes = {
	.aircandi = @"aircandi",
	.factual = @"factual",
	.foursquare = @"foursquare",
	.google = @"google",
	.googleReference = @"googleReference",
	.yelp = @"yelp",
};

const struct ProviderMapRelationships ProviderMapRelationships = {
	.place = @"place",
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

@dynamic aircandi;

@dynamic factual;

@dynamic foursquare;

@dynamic google;

@dynamic googleReference;

@dynamic yelp;

@dynamic place;

@end

