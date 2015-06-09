// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Photo.m instead.

#import "_Photo.h"

const struct PhotoAttributes PhotoAttributes = {
	.createdDate = @"createdDate",
	.height = @"height",
	.prefix = @"prefix",
	.resizerActive = @"resizerActive",
	.resizerHeight = @"resizerHeight",
	.resizerWidth = @"resizerWidth",
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
	if ([key isEqualToString:@"resizerActiveValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"resizerActive"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"resizerHeightValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"resizerHeight"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"resizerWidthValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"resizerWidth"];
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

@dynamic resizerActive;

- (BOOL)resizerActiveValue {
	NSNumber *result = [self resizerActive];
	return [result boolValue];
}

- (void)setResizerActiveValue:(BOOL)value_ {
	[self setResizerActive:@(value_)];
}

- (BOOL)primitiveResizerActiveValue {
	NSNumber *result = [self primitiveResizerActive];
	return [result boolValue];
}

- (void)setPrimitiveResizerActiveValue:(BOOL)value_ {
	[self setPrimitiveResizerActive:@(value_)];
}

@dynamic resizerHeight;

- (int32_t)resizerHeightValue {
	NSNumber *result = [self resizerHeight];
	return [result intValue];
}

- (void)setResizerHeightValue:(int32_t)value_ {
	[self setResizerHeight:@(value_)];
}

- (int32_t)primitiveResizerHeightValue {
	NSNumber *result = [self primitiveResizerHeight];
	return [result intValue];
}

- (void)setPrimitiveResizerHeightValue:(int32_t)value_ {
	[self setPrimitiveResizerHeight:@(value_)];
}

@dynamic resizerWidth;

- (int32_t)resizerWidthValue {
	NSNumber *result = [self resizerWidth];
	return [result intValue];
}

- (void)setResizerWidthValue:(int32_t)value_ {
	[self setResizerWidth:@(value_)];
}

- (int32_t)primitiveResizerWidthValue {
	NSNumber *result = [self primitiveResizerWidth];
	return [result intValue];
}

- (void)setPrimitiveResizerWidthValue:(int32_t)value_ {
	[self setPrimitiveResizerWidth:@(value_)];
}

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

