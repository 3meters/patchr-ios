#import "PACategory.h"
#import "Photo.h"

@interface PACategory ()

// Private interface goes here.

@end

@implementation PACategory

+ (PACategory *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                   onObject:(PACategory *)category
                               mappingNames:(BOOL)mapNames {
    category.name = dictionary[@"name"];
    category.id_ = dictionary[@"id"];
    
    if (dictionary[@"photo"]) {
        category.photo = [Photo setPropertiesFromDictionary:dictionary[@"photo"] onObject:[Photo insertInManagedObjectContext:category.managedObjectContext] mappingNames:mapNames];
    }
    
    if ([dictionary[@"categories"] isKindOfClass:[NSArray class]]) {
        NSArray *categories = dictionary[@"categories"];
        for (id categoryDict in categories) {
            if ([categoryDict isKindOfClass:[NSDictionary class]]) {
                PACategory *subCategory = [PACategory setPropertiesFromDictionary:categoryDict onObject:[PACategory insertInManagedObjectContext:category.managedObjectContext] mappingNames:mapNames];
                [category addCategoriesObject:subCategory];
            }
        }
    }
    
    return category;
}

@end
