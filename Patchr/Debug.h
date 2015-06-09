//
//  NSObject+Debug.h
//  Patchr
//
//  Created by Jay Massena on 6/1/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG

@interface NSObject (LongDescription)

- (NSString *)longDescription;

@end

#endif
