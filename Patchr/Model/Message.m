#import "Message.h"
#import "Link.h"
#import "Shortcut.h"

@interface Message ()

// Private interface goes here.

@end

@implementation Message

+ (Message *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                onObject:(Message *)message {

    message = (Message *)[Entity setPropertiesFromDictionary:dictionary onObject:message];
	
	/* Delete the related objects if they exist */
	NSManagedObjectContext *context = [message managedObjectContext];
	if (message.patch != nil) {
		[context deleteObject:message.patch];
	}
	if (message.message != nil) {
		[context deleteObject:message.message];
	}
	
	if (dictionary[@"linked"]) {
		for (id linkMap in dictionary[@"linked"]) {
			if ([linkMap isKindOfClass:[NSDictionary class]]) {
				if ([linkMap[@"schema"] isEqualToString: @"patch"]) {
					NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Shortcut" inManagedObjectContext:context];
					Shortcut *shortcut = [[Shortcut alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
					
					NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
					if ([entityId rangeOfString:@"sh."].location == NSNotFound) {
						entityId = [@"sh." stringByAppendingString:entityId];
					}
					shortcut.id_ = entityId;
					message.patch = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut];
				}
				else if ([linkMap[@"schema"] isEqualToString: @"message"]) {
					NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Shortcut" inManagedObjectContext:context];
					Shortcut *shortcut = [[Shortcut alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
					
					NSString *entityId = [[NSString alloc] initWithString:linkMap[@"_id"]];
					if ([entityId rangeOfString:@"sh."].location == NSNotFound) {
						entityId = [@"sh." stringByAppendingString:entityId];
					}
					shortcut.id_ = entityId;
					message.message = [Shortcut setPropertiesFromDictionary:linkMap onObject:shortcut];
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
