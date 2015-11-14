// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServiceObject.m instead.

#import "_ServiceObject.h"

@implementation ServiceObjectID
@end

@implementation _ServiceObject

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ServiceObject" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ServiceObject";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ServiceObject" inManagedObjectContext:moc_];
}

- (ServiceObjectID*)objectID {
	return (ServiceObjectID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@end

