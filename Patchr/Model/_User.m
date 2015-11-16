// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.m instead.

#import "_User.h"

const struct UserAttributes UserAttributes = {
	.area = @"area",
	.developer = @"developer",
	.email = @"email",
	.password = @"password",
	.patchesOwned = @"patchesOwned",
	.patchesWatching = @"patchesWatching",
	.role = @"role",
};

@implementation UserID
@end

@implementation _User

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"User";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"User" inManagedObjectContext:moc_];
}

- (UserID*)objectID {
	return (UserID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"developerValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"developer"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"patchesOwnedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"patchesOwned"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"patchesWatchingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"patchesWatching"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic area;

@dynamic developer;

- (BOOL)developerValue {
	NSNumber *result = [self developer];
	return [result boolValue];
}

- (void)setDeveloperValue:(BOOL)value_ {
	[self setDeveloper:@(value_)];
}

- (BOOL)primitiveDeveloperValue {
	NSNumber *result = [self primitiveDeveloper];
	return [result boolValue];
}

- (void)setPrimitiveDeveloperValue:(BOOL)value_ {
	[self setPrimitiveDeveloper:@(value_)];
}

@dynamic email;

@dynamic password;

@dynamic patchesOwned;

- (int64_t)patchesOwnedValue {
	NSNumber *result = [self patchesOwned];
	return [result longLongValue];
}

- (void)setPatchesOwnedValue:(int64_t)value_ {
	[self setPatchesOwned:@(value_)];
}

- (int64_t)primitivePatchesOwnedValue {
	NSNumber *result = [self primitivePatchesOwned];
	return [result longLongValue];
}

- (void)setPrimitivePatchesOwnedValue:(int64_t)value_ {
	[self setPrimitivePatchesOwned:@(value_)];
}

@dynamic patchesWatching;

- (int64_t)patchesWatchingValue {
	NSNumber *result = [self patchesWatching];
	return [result longLongValue];
}

- (void)setPatchesWatchingValue:(int64_t)value_ {
	[self setPatchesWatching:@(value_)];
}

- (int64_t)primitivePatchesWatchingValue {
	NSNumber *result = [self primitivePatchesWatching];
	return [result longLongValue];
}

- (void)setPrimitivePatchesWatchingValue:(int64_t)value_ {
	[self setPrimitivePatchesWatching:@(value_)];
}

@dynamic role;

@end

