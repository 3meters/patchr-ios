// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Location.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct LocationAttributes {
	__unsafe_unretained NSString *accuracy;
	__unsafe_unretained NSString *altitude;
	__unsafe_unretained NSString *bearing;
	__unsafe_unretained NSString *lat;
	__unsafe_unretained NSString *lng;
	__unsafe_unretained NSString *provider;
	__unsafe_unretained NSString *speed;
} LocationAttributes;

extern const struct LocationRelationships {
	__unsafe_unretained NSString *locationFor;
} LocationRelationships;

@class Entity;

@interface LocationID : ServiceObjectID {}
@end

@interface _Location : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) LocationID* objectID;

@property (nonatomic, strong) NSNumber* accuracy;

@property (atomic) double accuracyValue;
- (double)accuracyValue;
- (void)setAccuracyValue:(double)value_;

//- (BOOL)validateAccuracy:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* altitude;

@property (atomic) double altitudeValue;
- (double)altitudeValue;
- (void)setAltitudeValue:(double)value_;

//- (BOOL)validateAltitude:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* bearing;

@property (atomic) double bearingValue;
- (double)bearingValue;
- (void)setBearingValue:(double)value_;

//- (BOOL)validateBearing:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* lat;

@property (atomic) double latValue;
- (double)latValue;
- (void)setLatValue:(double)value_;

//- (BOOL)validateLat:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* lng;

@property (atomic) double lngValue;
- (double)lngValue;
- (void)setLngValue:(double)value_;

//- (BOOL)validateLng:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* provider;

//- (BOOL)validateProvider:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* speed;

@property (atomic) double speedValue;
- (double)speedValue;
- (void)setSpeedValue:(double)value_;

//- (BOOL)validateSpeed:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Entity *locationFor;

//- (BOOL)validateLocationFor:(id*)value_ error:(NSError**)error_;

@end

@interface _Location (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveAccuracy;
- (void)setPrimitiveAccuracy:(NSNumber*)value;

- (double)primitiveAccuracyValue;
- (void)setPrimitiveAccuracyValue:(double)value_;

- (NSNumber*)primitiveAltitude;
- (void)setPrimitiveAltitude:(NSNumber*)value;

- (double)primitiveAltitudeValue;
- (void)setPrimitiveAltitudeValue:(double)value_;

- (NSNumber*)primitiveBearing;
- (void)setPrimitiveBearing:(NSNumber*)value;

- (double)primitiveBearingValue;
- (void)setPrimitiveBearingValue:(double)value_;

- (NSNumber*)primitiveLat;
- (void)setPrimitiveLat:(NSNumber*)value;

- (double)primitiveLatValue;
- (void)setPrimitiveLatValue:(double)value_;

- (NSNumber*)primitiveLng;
- (void)setPrimitiveLng:(NSNumber*)value;

- (double)primitiveLngValue;
- (void)setPrimitiveLngValue:(double)value_;

- (NSString*)primitiveProvider;
- (void)setPrimitiveProvider:(NSString*)value;

- (NSNumber*)primitiveSpeed;
- (void)setPrimitiveSpeed:(NSNumber*)value;

- (double)primitiveSpeedValue;
- (void)setPrimitiveSpeedValue:(double)value_;

- (Entity*)primitiveLocationFor;
- (void)setPrimitiveLocationFor:(Entity*)value;

@end
