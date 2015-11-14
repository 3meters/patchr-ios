#import "Shortcut.h"
#import "Photo.h"

@interface Shortcut ()

// Private interface goes here.

@end

@implementation Shortcut

+ (Shortcut *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                              onObject:(Shortcut *)shortcut {
    
    shortcut = (Shortcut *)[Entity setPropertiesFromDictionary:dictionary onObject:shortcut];
    
    shortcut.entityId = dictionary[@"_id"];
	if ([shortcut.id_ rangeOfString:@"sh."].location == NSNotFound) {
		shortcut.id_ = [@"sh." stringByAppendingString:shortcut.id_];
	}
	
    return shortcut;
}

@end
