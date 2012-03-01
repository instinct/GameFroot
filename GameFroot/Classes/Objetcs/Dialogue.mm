//
//  Dialogue.m
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Dialogue.h"
#import "GameLayer.h"
#import "CCLabelBMFontMultiline.h"

#define TOUCH_PRIORITY		-10000

@implementation Dialogue


-(void) setupDialogue:(NSString *)_text
{
    text = [_text retain];
    
    background = [CCSprite spriteWithFile:@"dialogue_background.png"];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
    
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];
	
	label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Chicago.fnt" width:background.contentSize.width - 30 alignment:LeftAlignment];
	[label.textureAtlas.texture setAliasTexParameters];
    
    [label setAnchorPoint:ccp(0,1)];
    [label setPosition: ccp(25, background.contentSize.height + 8)];
    
    selectPage = 0;
    numPages = label.contentSize.height / background.contentSize.height;
    float exact = label.contentSize.height / background.contentSize.height;
    if (exact > (float)numPages) numPages++;
    
    //CCLOG(@"Dialogue.setupDialogue: %@, pages: %i", _text, numPages);
        
    [self addChild:background z:1];
	[self addChild:label z:2];
	
	[[GameLayer getInstance] addOverlay:self];
	
    if (![[GameLayer getInstance] isPaused]) {
        [[CCDirector sharedDirector] pause];
        //[[CCDirector sharedDirector] stopAnimation];
        [[GameLayer getInstance] stopPlayer];
        [[GameLayer getInstance] pause];
        [[GameLayer getInstance] resetControls];
    }
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (selectPage < numPages - 1) {
        // Display next page
        selectPage++;
        [label setPosition:ccp(label.position.x, label.position.y + background.contentSize.height - 6)];
        
    } else if ([[GameLayer getInstance] isPaused]) {
        [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
        
        [[CCDirector sharedDirector] resume];
        //[[CCDirector sharedDirector] startAnimation];
        [[GameLayer getInstance] resume];
        
        [[GameLayer getInstance] removeOverlay:self];
        
    } else {
        [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
        [[GameLayer getInstance] removeOverlay:self];
        
    }
    
    return YES;
}

- (void) visit 
{
	glEnable(GL_SCISSOR_TEST);
	glScissor(10*CC_CONTENT_SCALE_FACTOR(), 10*CC_CONTENT_SCALE_FACTOR(), background.contentSize.height*CC_CONTENT_SCALE_FACTOR(), background.contentSize.width*CC_CONTENT_SCALE_FACTOR());
	[super visit];
	glDisable(GL_SCISSOR_TEST);
    
}

- (void)dealloc
{
    [text release];
    [super dealloc];
}

@end
