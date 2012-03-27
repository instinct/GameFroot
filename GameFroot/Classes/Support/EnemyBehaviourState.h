//
//  EnemyBehaviourState.h
//  GameFroot
//
//  Created by Sam Win-Mason on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EnemyBehaviourState : NSObject {
    int mode;
    float minDuration;
    float maxDuration;
    NSString *update;
    NSString *init;
}

@property int mode;
@property float minDuration;
@property float maxDuration;
@property (nonatomic, assign) NSString *update;
@property (nonatomic, assign) NSString *init;

- (id)initWithMode:(int)mode minDuration:(float)minDuration maxDuration:(float)maxDuration updateSelString:(NSString*)update initSelString:(NSString*)init;

@end
