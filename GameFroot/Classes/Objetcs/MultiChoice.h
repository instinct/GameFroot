//
//  MultiChoice.h
//  GameFroot
//
//  Created by Jose Miguel on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class Robot;

@interface MultiChoice : CCNode <CCTargetedTouchDelegate> {
	NSString *text;
	BOOL read;
	CCSprite *background;
    Robot *robot;
    NSArray *choices;
}

-(void) setupChoices:(NSDictionary *)command robot:(Robot *)_robot;

@end

