#import "ServiceObject.h"
#import <objc/runtime.h>

@interface ServiceObject ()

// Private interface goes here.

@end

@implementation ServiceObject

// Auto property descriptions
// http://iosdevelopertips.com/debugging/creating-custom-object-descriptions-debugging.html
- (NSArray *)describablePropertyNames
{
    // Loop through our superclasses until we hit NSObject
    NSMutableArray *array = [NSMutableArray array];
    Class subclass = [self class];
    while (subclass != [NSObject class])
    {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(subclass,&propertyCount);
        for (int i = 0; i < propertyCount; i++)
        {
            // Add property name to array
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            [array addObject:@(propertyName)];
        }
        free(properties);
        subclass = [subclass superclass];
    }
    
    // Return array of property names
    return array;
}

//- (NSString *)description
//{
//    NSMutableString *propertyDescriptions = [NSMutableString new];
//    for (NSString *key in [self describablePropertyNames])
//    {
//        id value = [self valueForKey:key];
//        [propertyDescriptions appendFormat:@"; %@ = %@", key, value];
//    }
//    return [NSString stringWithFormat:@"<%@: 0x%lx%@>", [self class],
//            (unsigned long)self, propertyDescriptions];
//}

@end
