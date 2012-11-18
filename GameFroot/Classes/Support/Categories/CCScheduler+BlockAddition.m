//
//  CCScheduler+BlockAddition.m
//  GameFroot
//
//  Created by Jose Miguel on 19/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

/*
Usage:

[[CCScheduler sharedScheduler] scheduleAfterDelay:1.0 block:^(ccTime dt) {
    CCLOG(@"your scheduled code here");
}];
 
*/

#import "CCScheduler+BlockAddition.h"

@implementation NSObject (BlockAddition)

- (void)cc_invokeBlock:(ccTime)dt {
    void(^block)(ccTime dt) = (id)self;
    block(dt);
}

@end

@implementation CCScheduler (BlockAddition)

- (id)scheduleAfterDelay:(ccTime)delay block:(void(^)(ccTime dt))block {
    block = [block copy];
    [self scheduleSelector:@selector(cc_invokeBlock:) forTarget:block interval:0 paused:NO repeat:0 delay:delay];
    return [block autorelease];
}

- (void)pause {
    [self pauseTarget:self];
}

- (void)resume {
    [self resumeTarget:self];
}

@end
