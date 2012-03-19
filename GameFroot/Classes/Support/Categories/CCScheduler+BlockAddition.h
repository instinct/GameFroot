//
//  CCScheduler+BlockAddition.h
//  GameFroot
//
//  Created by Jose Miguel on 19/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface CCScheduler (BlockAddition)

- (id)scheduleAfterDelay:(ccTime)delay block:(void(^)(ccTime dt))block;
- (void)pause;
- (void)resume;

@end

@interface NSObject (BlockAddition)

- (void)cc_invokeBlock:(ccTime)dt;

@end
