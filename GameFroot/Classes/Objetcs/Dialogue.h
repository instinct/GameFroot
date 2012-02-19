//
//  Dialogue.h
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface Dialogue : CCNode <CCTargetedTouchDelegate> {
	NSString *text;
	CCSprite *background;
}

-(void) setupDialogue:(NSString *)_text;

@end
