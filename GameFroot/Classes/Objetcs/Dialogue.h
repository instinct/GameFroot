//
//  Dialogue.h
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class CCLabelBMFontMultiline;

@interface Dialogue : CCNode <CCTargetedTouchDelegate> {
	CCSprite *background;
    NSArray *pages;
    int numPages;
    int selectPage;
    CCLabelBMFontMultiline *label;
}

+(NSArray *) findPageSplits:(NSString*)string size:(CGSize)size font:(UIFont*)font;
-(void) setupDialogue:(NSString *)_text;

@end
