// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Shortcut.m instead.

#import "_Shortcut.h"

const struct ShortcutAttributes ShortcutAttributes = {
	.entityId = @"entityId",
};

@implementation ShortcutID
@end

@implementation _Shortcut

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Shortcut" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Shortcut";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Shortcut" inManagedObjectContext:moc_];
}

- (ShortcutID*)objectID {
	return (ShortcutID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic entityId;

@end

