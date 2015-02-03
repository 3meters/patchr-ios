// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to User.m instead.

#import "_User.h"

const struct UserAttributes UserAttributes = {
	.area = @"area",
	.authSource = @"authSource",
	.bio = @"bio",
	.developer = @"developer",
	.email = @"email",
	.facebookId = @"facebookId",
	.googleId = @"googleId",
	.lastSignedInDate = @"lastSignedInDate",
	.oauthData = @"oauthData",
	.oauthId = @"oauthId",
	.oauthSecret = @"oauthSecret",
	.oauthToken = @"oauthToken",
	.password = @"password",
	.role = @"role",
	.twitterId = @"twitterId",
	.validationDate = @"validationDate",
	.validationNotifyDate = @"validationNotifyDate",
	.webUri = @"webUri",
};

const struct UserRelationships UserRelationships = {
	.replies = @"replies",
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

	return keyPaths;
}

@dynamic area;

@dynamic authSource;

@dynamic bio;

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

@dynamic facebookId;

@dynamic googleId;

@dynamic lastSignedInDate;

@dynamic oauthData;

@dynamic oauthId;

@dynamic oauthSecret;

@dynamic oauthToken;

@dynamic password;

@dynamic role;

@dynamic twitterId;

@dynamic validationDate;

@dynamic validationNotifyDate;

@dynamic webUri;

@dynamic replies;

- (NSMutableSet*)repliesSet {
	[self willAccessValueForKey:@"replies"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"replies"];

	[self didAccessValueForKey:@"replies"];
	return result;
}

@end

