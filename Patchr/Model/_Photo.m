// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Photo.m instead.

#import "_Photo.h"

const struct PhotoAttributes PhotoAttributes = {
	.createdDate = @"createdDate",
	.height = @"height",
	.prefix = @"prefix",
	.source = @"source",
	.suffix = @"suffix",
	.usingDefault = @"usingDefault",
	.width = @"width",
};

@implementation PhotoID
@end

@implementation _Photo

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Photo";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:moc_];
}

- (PhotoID*)objectID {
	return (PhotoID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"heightValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"height"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"usingDefaultValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"usingDefault"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"widthValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"width"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic createdDate;

@dynamic height;

- (int32_t)heightValue {
	NSNumber *result = [self height];
	return [result intValue];
}

- (void)setHeightValue:(int32_t)value_ {
	[self setHeight:@(value_)];
}

- (int32_t)primitiveHeightValue {
	NSNumber *result = [self primitiveHeight];
	return [result intValue];
}

- (void)setPrimitiveHeightValue:(int32_t)value_ {
	[self setPrimitiveHeight:@(value_)];
}

@dynamic prefix;

@dynamic source;

@dynamic suffix;

@dynamic usingDefault;

- (BOOL)usingDefaultValue {
	NSNumber *result = [self usingDefault];
	return [result boolValue];
}

- (void)setUsingDefaultValue:(BOOL)value_ {
	[self setUsingDefault:@(value_)];
}

- (BOOL)primitiveUsingDefaultValue {
	NSNumber *result = [self primitiveUsingDefault];
	return [result boolValue];
}

- (void)setPrimitiveUsingDefaultValue:(BOOL)value_ {
	[self setPrimitiveUsingDefault:@(value_)];
}

@dynamic width;

- (int32_t)widthValue {
	NSNumber *result = [self width];
	return [result intValue];
}

- (void)setWidthValue:(int32_t)value_ {
	[self setWidth:@(value_)];
}

- (int32_t)primitiveWidthValue {
	NSNumber *result = [self primitiveWidth];
	return [result intValue];
}

- (void)setPrimitiveWidthValue:(int32_t)value_ {
	[self setPrimitiveWidth:@(value_)];
}

@end

