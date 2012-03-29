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
    CCSprite *arrow;
    int numPages;
    int selectPage;
    
    //CCLabelBMFontMultiline *label;
    CCLabelTTF *label;
    
    float speed;
    CCArray *speechSpeeds;
    BOOL animating;
    int numCharacters;
    int currentCharacter;
}

-(void) setupDialogue:(NSString *)_text;
-(void) prepareText;
-(void) animate;

@end
