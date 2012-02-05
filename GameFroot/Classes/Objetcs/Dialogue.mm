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
	//text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";	
	//text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";	
	//text = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor.";
	text = [_text retain];	
	read = NO;
	
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];
}

//-(void) remove
-(void) display
{
	//CGSize s = [[CCDirector sharedDirector] winSize];
	
	background = [CCSprite spriteWithFile:@"dialogue_background.png"];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
	
	//CCLabelBMFont *label = [CCLabelBMFont labelWithString:text fntFile:@"Chicago.fnt"];
	
	/*
	CCLabelTTF *label = [CCLabelTTF labelWithString:text
							 dimensions:CGSizeMake(background.contentSize.width - 10, background.contentSize.height - 10)
							  alignment:UITextAlignmentLeft
							   fontName:@"Trebuchet MS"
							   fontSize:14];
	*/
	
	CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Chicago.fnt" width:background.contentSize.width - 20 alignment:LeftAlignment];
	[label.textureAtlas.texture setAliasTexParameters];
	
	if (label.contentSize.height < background.contentSize.height) {
		[label setAnchorPoint:ccp(0,1)];
		[label setPosition: ccp(10, background.contentSize.height - 5)];
		
	} else {
		[label setAnchorPoint:ccp(0,0)];
		[label setPosition: ccp(10, 5)];
		
		// adjust background
		background.scaleY = (label.contentSize.height + 10)/background.contentSize.height;
		label.scaleY = background.contentSize.height/(label.contentSize.height + 10);
	}
	
	//CCLOG(@"%f , %f", background.contentSize.height, label.contentSize.height);
	
	//[label setColor:ccc3(0,0,0)];
	//[label setPosition: ccp(s.width/2, background.contentSize.height/2)];
	
	[background addChild:label z:1];
	
	[[GameLayer getInstance] addOverlay:background];
	
	[[CCDirector sharedDirector] pause];
	[[CCDirector sharedDirector] stopAnimation];
	[[GameLayer getInstance] stopPlayer];
	[[GameLayer getInstance] pause];
	
	read = YES;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (read) {
		[[GameLayer getInstance] removeOverlay:background];
		[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
		
		[[CCDirector sharedDirector] resume];
		[[CCDirector sharedDirector] startAnimation];
		[[GameLayer getInstance] resume];
		
		return YES;
	}
	return NO;
}

- (void)dealloc
{
	[text release];
    [super dealloc];
}

@end
