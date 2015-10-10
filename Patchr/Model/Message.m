#import "Message.h"
#import "Link.h"
#import "Shortcut.h"

@interface Message ()

// Private interface goes here.

@end

@implementation Message

+ (Message *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                onObject:(Message *)message
                            mappingNames:(BOOL)mapNames {

    message = (Message *)[Entity setPropertiesFromDictionary:dictionary onObject:message mappingNames:mapNames];
    
    message.patch = nil;
    if (dictionary[@"linked"]) {
        for (id linkMap in dictionary[@"linked"]) {
            if ([linkMap isKindOfClass:[NSDictionary class]]) {
                if ([linkMap[@"schema"] isEqualToString: @"patch"]) {
                    NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
					if ([entityId rangeOfString:@"sh."].location == NSNotFound) {
						entityId = [@"sh." stringByAppendingString:entityId];
					}
                    id shortcut = [Shortcut fetchOrInsertOneById:entityId inManagedObjectContext:message.managedObjectContext];
                    message.patch = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut mappingNames:mapNames];
                }
                else if ([linkMap[@"schema"] isEqualToString: @"message"]) {
                    NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
					if ([entityId rangeOfString:@"sh."].location == NSNotFound) {
						entityId = [@"sh." stringByAppendingString:entityId];
					}
                    id shortcut = [Shortcut fetchOrInsertOneById:entityId inManagedObjectContext:message.managedObjectContext];
                    message.message = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut mappingNames:mapNames];
                }
            }
        }
    }
    
    message.userLikesValue = NO;
    message.userLikesId = nil;
    
    if ([dictionary[@"links"] isKindOfClass:[NSArray class]]) {
        for (id linkMap in dictionary[@"links"]) {
            if ([linkMap isKindOfClass:[NSDictionary class]]) {
                
                if ([linkMap[@"fromSchema"] isEqualToString:@"user"] && [linkMap[@"type"] isEqualToString:@"like"]) {
                    message.userLikesId = linkMap[@"_id"];
                    message.userLikesValue = YES;
                }
            }
        }
    }

    return message;
}

@end
