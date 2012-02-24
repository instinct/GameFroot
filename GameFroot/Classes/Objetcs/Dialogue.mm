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
    //CCLOG(@"Dialogue.setupDialogue: %@", _text);
    
	//text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";	
	//text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";	
	//text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor.";
	
    if ([_text length] < 200) text = [_text retain];
    else text = [_text substringToIndex:200];
	
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];

	background = [CCSprite spriteWithFile:@"dialogue_background.png"];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
	
	CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Chicago.fnt" width:background.contentSize.width - 20 alignment:LeftAlignment];
	[label.textureAtlas.texture setAliasTexParameters];
	
	if (label.contentSize.height < background.contentSize.height) {
		[label setAnchorPoint:ccp(0,1)];
		[label setPosition: ccp(20, background.contentSize.height + 5)];
		
	} else {
		[label setAnchorPoint:ccp(0,0)];
		[label setPosition: ccp(20, 15)];
		
		// adjust background
		background.scaleY = (label.contentSize.height + 10)/background.contentSize.height;
	}
	
    [self addChild:background z:1];
	[self addChild:label z:2];
	
	[[GameLayer getInstance] addOverlay:self];
	
	[[CCDirector sharedDirector] pause];
	[[CCDirector sharedDirector] stopAnimation];
	[[GameLayer getInstance] stopPlayer];
	[[GameLayer getInstance] pause];
	[[GameLayer getInstance] resetControls];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
    
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    [[GameLayer getInstance] resume];
    
    [[GameLayer getInstance] removeOverlay:self];
    
    return YES;
}

- (void)dealloc
{
	[text release];
    [super dealloc];
}

@end
