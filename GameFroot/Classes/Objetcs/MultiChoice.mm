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
#import "ButtonLabelItem.h"

#define TOUCH_PRIORITY		-10000

@implementation MultiChoice

-(void) setupChoices:(NSDictionary *)command
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    choices = [command objectForKey:@"choices"];
    
	text = [command objectForKey:@"question"];
    
    CCMenu *optionsMenu = [CCMenu menuWithItems: nil];
    
    int count = [choices count];
    if (count > 4) count = 4;
    
    for (int i=0; i < count; i++) {
        NSDictionary *choice = [choices objectAtIndex:i];
        text = [text stringByAppendingString:[NSString stringWithFormat:@"\n%@", [choice objectForKey:@"choiceText"]]];
        
        //CCSprite *button = [CCSprite spriteWithFile:@"option-btn.png"];
        //CCLabelBMFont *label = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Option %i",i+1] fntFile:@"Chicago.fnt"];
        //ButtonLabelItem *option = [ButtonLabelItem itemFromSprite:button withLabel:label target:self selector:@selector(optionSelected:)];
        
        CCMenuItemFont *option = [CCMenuItemFont itemFromString:[NSString stringWithFormat:@"Option %i",i+1] target:self selector:@selector(optionSelected:)];
        option.tag = i;
        [optionsMenu addChild:option];
    }
    
    if (count == 4) [optionsMenu alignItemsInRows:[NSNumber numberWithInt:2],[NSNumber numberWithInt:2],nil];
    else if (count == 3) [optionsMenu alignItemsInRows:[NSNumber numberWithInt:2],[NSNumber numberWithInt:2],nil];
    else if (count == 2) [optionsMenu alignItemsHorizontally];
    else [optionsMenu alignItemsHorizontally];
        
    [optionsMenu setPosition:ccp(size.width/2, size.height/2 + 60)];
    [self addChild:optionsMenu z:3];
	
	//[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:TOUCH_PRIORITY swallowsTouches:YES];
	
	background = [CCSprite spriteWithFile:@"dialogue_background.png"];
	[background setAnchorPoint:ccp(0,0)];
	[background setPosition:ccp(10, 10)];
	
	CCLabelBMFontMultiline *label = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Chicago.fnt" width:background.contentSize.width - 100 alignment:LeftAlignment];
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

-(void) optionSelected:(id)sender
{
    CCMenuItem *item = (CCMenuItem *)sender;
    CCLOG(@"MultiChoice.optionSelected: %i", item.tag);
    
    [[GameLayer getInstance] answeredMultiChoice:self withAnswer:[[choices objectAtIndex:item.tag] objectForKey:@"message"]];
}

/*
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
		
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    [[GameLayer getInstance] resume];
		
    [[GameLayer getInstance] removeOverlay:self];
        
    return YES;
}
*/

- (void)dealloc
{
	[text release];
    [super dealloc];
}

@end

