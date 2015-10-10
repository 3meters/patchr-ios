#import "Shortcut.h"
#import "Photo.h"

@interface Shortcut ()

// Private interface goes here.

@end

@implementation Shortcut

+ (Shortcut *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Shortcut *)shortcut
                          mappingNames:(BOOL)mapNames {
    
    shortcut = (Shortcut *)[Entity setPropertiesFromDictionary:dictionary onObject:shortcut mappingNames:mapNames];    
    
    shortcut.entityId = (mapNames && dictionary[@"_id"]) ? dictionary[@"_id"] : dictionary[@"id"];
	if ([shortcut.id_ rangeOfString:@"sh."].location == NSNotFound) {
		shortcut.id_ = [@"sh." stringByAppendingString:shortcut.id_];
	}
	
    return shortcut;
}

@end
