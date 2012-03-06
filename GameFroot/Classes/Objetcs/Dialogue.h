//
//  Dialogue.h
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "SimpleAudioEngine.h"

@class CCLabelBMFontMultiline;

@interface Dialogue : CCNode <CCTargetedTouchDelegate> {
    NSString *text;
	CCSprite *background;
    int numPages;
    int selectPage;
    CCLabelBMFontMultiline *label;
}

-(void) setupDialogue:(NSString *)_text;

@end
