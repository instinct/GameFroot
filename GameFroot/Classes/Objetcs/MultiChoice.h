//
//  MultiChoice.h
//  GameFroot
//
//  Created by Jose Miguel on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface MultiChoice : CCNode { //<CCTargetedTouchDelegate> {
	NSString *text;
	CCSprite *background;
    NSArray *choices;
}

-(void) setupChoices:(NSDictionary *)command;

@end

