// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Place.h instead.

@import CoreData;
#import "Patch.h"

extern const struct PlaceAttributes {
	__unsafe_unretained NSString *address;
	__unsafe_unretained NSString *applinkDate;
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *country;
	__unsafe_unretained NSString *phone;
	__unsafe_unretained NSString *postalCode;
	__unsafe_unretained NSString *region;
} PlaceAttributes;

extern const struct PlaceRelationships {
	__unsafe_unretained NSString *patch;
	__unsafe_unretained NSString *provider;
} PlaceRelationships;

@class Patch;
@class ProviderMap;

@interface PlaceID : PatchID {}
@end

@interface _Place : Patch {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) PlaceID* objectID;

@property (nonatomic, strong) NSString* address;

//- (BOOL)validateAddress:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* applinkDate;

//- (BOOL)validateApplinkDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* city;

//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* country;

//- (BOOL)validateCountry:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* phone;

//- (BOOL)validatePhone:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* postalCode;

//- (BOOL)validatePostalCode:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* region;

//- (BOOL)validateRegion:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Patch *patch;

//- (BOOL)validatePatch:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) ProviderMap *provider;

//- (BOOL)validateProvider:(id*)value_ error:(NSError**)error_;

@end

@interface _Place (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveAddress;
- (void)setPrimitiveAddress:(NSString*)value;

- (NSDate*)primitiveApplinkDate;
- (void)setPrimitiveApplinkDate:(NSDate*)value;

- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;

- (NSString*)primitiveCountry;
- (void)setPrimitiveCountry:(NSString*)value;

- (NSString*)primitivePhone;
- (void)setPrimitivePhone:(NSString*)value;

- (NSString*)primitivePostalCode;
- (void)setPrimitivePostalCode:(NSString*)value;

- (NSString*)primitiveRegion;
- (void)setPrimitiveRegion:(NSString*)value;

- (Patch*)primitivePatch;
- (void)setPrimitivePatch:(Patch*)value;

- (ProviderMap*)primitiveProvider;
- (void)setPrimitiveProvider:(ProviderMap*)value;

@end
