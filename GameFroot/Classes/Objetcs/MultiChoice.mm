//
//  MultiChoice.m
//  GameFroot
//
//  Created by Jose Miguel on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MultiChoice.h"
#import "GameLayer.h"
#import "Robot.h"
#import "CCLabelBMFontMultiline.h"

#define TOUCH_PRIORITY		-10000

@implementation MultiChoice

-(void) setupChoices:(NSDictionary *)command robot:(Robot *)_robot
{
    choices = [command objectForKey:@"choices"];
    robot = _robot;
    
	text = [command objectForKey:@"question"];
    
    for (int i=0; i < [choices count]; i++) {
        NSDictionary *choice = [choices objectAtIndex:i];
        text = [text stringByAppendingString:[NSString stringWithFormat:@"\n%@", [choice objectForKey:@"choiceText"]]];
    }
    
	read = NO;
	
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];

	//CGSize s = [[CCDirector sharedDirector] winSize];
	
	background = [CCSprite spriteWithFile:@"dialogue_background.png"];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
	
	CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Chicago.fnt" width:background.contentSize.width - 100 alignment:LeftAlignment];
	[label.textureAtlas.texture setAliasTexParameters];
	
	if (label.contentSize.height < background.contentSize.height) {
		[label setAnchorPoint:ccp(0,1)];
		[label setPosition: ccp(90, background.contentSize.height - 5)];
		
	} else {
		[label setAnchorPoint:ccp(0,0)];
		[label setPosition: ccp(90, 5)];
		
		// adjust background
		background.scaleY = (label.contentSize.height + 10)/background.contentSize.height;
		label.scaleY = background.contentSize.height/(label.contentSize.height + 10);
	}
	
	[background addChild:label z:1];
	
	[[GameLayer getInstance] addOverlay:background];
	
	[[CCDirector sharedDirector] pause];
	[[CCDirector sharedDirector] stopAnimation];
	[[GameLayer getInstance] stopPlayer];
	[[GameLayer getInstance] pause];
	[[GameLayer getInstance] resetControls];
    
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

