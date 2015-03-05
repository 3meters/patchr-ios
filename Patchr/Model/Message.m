#import "Message.h"
#import "User.h"

@interface Message ()

// Private interface goes here.

@end

@implementation Message

+ (Message *)setPropertiesFromDictionary:(NSDictionary *)dictionary
                                onObject:(Message *)message
                            mappingNames:(BOOL)mapNames {

    message = (Message *)[Entity setPropertiesFromDictionary:dictionary onObject:message mappingNames:mapNames];
    message.rootId = mapNames ? dictionary[@"_root"] : dictionary[@"rootId"];
    message.replyToId = mapNames ? dictionary[@"_replyTo"] : dictionary[@"replyToId"];
    
    if ([dictionary[@"_replyTo"] isKindOfClass:[NSString class]]) {
        message.replyTo = [User fetchOrInsertOneById:dictionary[@"_replyTo"] inManagedObjectContext:message.managedObjectContext];
    }

    return message;
}

@end
