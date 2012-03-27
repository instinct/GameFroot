//
//  EnemyBehaviourState.m
//  GameFroot
//
//  Created by Sam Win-Mason on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EnemyBehaviourState.h"

@implementation EnemyBehaviourState

@synthesize mode;
@synthesize minDuration;
@synthesize maxDuration;
@synthesize update;
@synthesize init;

- (id)initWithMode:(int)_mode minDuration:(float)_minDuration maxDuration:(float)_maxDuration updateSelString:(NSString*)_update initSelString:(NSString*)_init {
    self = [super init];
    if (self) {
        self.mode = _mode;
        self.minDuration = _minDuration;
        self.maxDuration = _maxDuration;
        self.update = _update;
        self.init = _init;
    }
    return self;
}


- (void)dealloc {
    [super dealloc];
}

@end
