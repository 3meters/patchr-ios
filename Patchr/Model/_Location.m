// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Location.m instead.

#import "_Location.h"

const struct LocationAttributes LocationAttributes = {
	.accuracy = @"accuracy",
	.altitude = @"altitude",
	.bearing = @"bearing",
	.lat = @"lat",
	.lng = @"lng",
	.provider = @"provider",
	.speed = @"speed",
};

@implementation LocationID
@end

@implementation _Location

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Location";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Location" inManagedObjectContext:moc_];
}

- (LocationID*)objectID {
	return (LocationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"accuracyValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"accuracy"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"altitudeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"altitude"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"bearingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"bearing"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"latValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lat"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lngValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lng"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"speedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"speed"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic accuracy;

- (double)accuracyValue {
	NSNumber *result = [self accuracy];
	return [result doubleValue];
}

- (void)setAccuracyValue:(double)value_ {
	[self setAccuracy:@(value_)];
}

- (double)primitiveAccuracyValue {
	NSNumber *result = [self primitiveAccuracy];
	return [result doubleValue];
}

- (void)setPrimitiveAccuracyValue:(double)value_ {
	[self setPrimitiveAccuracy:@(value_)];
}

@dynamic altitude;

- (double)altitudeValue {
	NSNumber *result = [self altitude];
	return [result doubleValue];
}

- (void)setAltitudeValue:(double)value_ {
	[self setAltitude:@(value_)];
}

- (double)primitiveAltitudeValue {
	NSNumber *result = [self primitiveAltitude];
	return [result doubleValue];
}

- (void)setPrimitiveAltitudeValue:(double)value_ {
	[self setPrimitiveAltitude:@(value_)];
}

@dynamic bearing;

- (double)bearingValue {
	NSNumber *result = [self bearing];
	return [result doubleValue];
}

- (void)setBearingValue:(double)value_ {
	[self setBearing:@(value_)];
}

- (double)primitiveBearingValue {
	NSNumber *result = [self primitiveBearing];
	return [result doubleValue];
}

- (void)setPrimitiveBearingValue:(double)value_ {
	[self setPrimitiveBearing:@(value_)];
}

@dynamic lat;

- (double)latValue {
	NSNumber *result = [self lat];
	return [result doubleValue];
}

- (void)setLatValue:(double)value_ {
	[self setLat:@(value_)];
}

- (double)primitiveLatValue {
	NSNumber *result = [self primitiveLat];
	return [result doubleValue];
}

- (void)setPrimitiveLatValue:(double)value_ {
	[self setPrimitiveLat:@(value_)];
}

@dynamic lng;

- (double)lngValue {
	NSNumber *result = [self lng];
	return [result doubleValue];
}

- (void)setLngValue:(double)value_ {
	[self setLng:@(value_)];
}

- (double)primitiveLngValue {
	NSNumber *result = [self primitiveLng];
	return [result doubleValue];
}

- (void)setPrimitiveLngValue:(double)value_ {
	[self setPrimitiveLng:@(value_)];
}

@dynamic provider;

@dynamic speed;

- (double)speedValue {
	NSNumber *result = [self speed];
	return [result doubleValue];
}

- (void)setSpeedValue:(double)value_ {
	[self setSpeed:@(value_)];
}

- (double)primitiveSpeedValue {
	NSNumber *result = [self primitiveSpeed];
	return [result doubleValue];
}

- (void)setPrimitiveSpeedValue:(double)value_ {
	[self setPrimitiveSpeed:@(value_)];
}

@end

