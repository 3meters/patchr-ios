// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ProviderMap.h instead.

@import CoreData;
#import "ServiceObject.h"

extern const struct ProviderMapAttributes {
	__unsafe_unretained NSString *aircandi;
	__unsafe_unretained NSString *factual;
	__unsafe_unretained NSString *foursquare;
	__unsafe_unretained NSString *google;
	__unsafe_unretained NSString *googleReference;
	__unsafe_unretained NSString *yelp;
} ProviderMapAttributes;

extern const struct ProviderMapRelationships {
	__unsafe_unretained NSString *place;
} ProviderMapRelationships;

@class Place;

@interface ProviderMapID : ServiceObjectID {}
@end

@interface _ProviderMap : ServiceObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) ProviderMapID* objectID;

@property (nonatomic, strong) NSString* aircandi;

//- (BOOL)validateAircandi:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* factual;

//- (BOOL)validateFactual:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* foursquare;

//- (BOOL)validateFoursquare:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* google;

//- (BOOL)validateGoogle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* googleReference;

//- (BOOL)validateGoogleReference:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* yelp;

//- (BOOL)validateYelp:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Place *place;

//- (BOOL)validatePlace:(id*)value_ error:(NSError**)error_;

@end

@interface _ProviderMap (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveAircandi;
- (void)setPrimitiveAircandi:(NSString*)value;

- (NSString*)primitiveFactual;
- (void)setPrimitiveFactual:(NSString*)value;

- (NSString*)primitiveFoursquare;
- (void)setPrimitiveFoursquare:(NSString*)value;

- (NSString*)primitiveGoogle;
- (void)setPrimitiveGoogle:(NSString*)value;

- (NSString*)primitiveGoogleReference;
- (void)setPrimitiveGoogleReference:(NSString*)value;

- (NSString*)primitiveYelp;
- (void)setPrimitiveYelp:(NSString*)value;

- (Place*)primitivePlace;
- (void)setPrimitivePlace:(Place*)value;

@end
