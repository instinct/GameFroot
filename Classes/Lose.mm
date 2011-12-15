//
//  Lose.m
//  DoubleHappy
//
//  Created by Jose Miguel on 16/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Lose.h"
#import "HomeLayer.h"

@implementation Lose

// on "init" you need to initialize your instance
-(id) init
{	
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super initWithColor:ccc4(119,32,9,128) fadingTo:ccc4(64,13,2,32)])) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		//CCSprite *bg = [CCSprite spriteWithFile:@"loading-bg.png"];
		//[bg setPosition:ccp(size.width*0.5,size.height*0.5)];
		//[self addChild:bg];
		
		CCSprite *title = [CCSprite spriteWithFile:@"title-game-over.png"];
		[title setPosition:ccp(size.width*0.5,size.height*0.8)];
		[title.textureAtlas.texture setAliasTexParameters];
		title.scale = 0.75;
		[self addChild:title];
		
		CCLabelBMFont *score = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Your score: %i out of %i",[GameLayer getInstance].points, [GameLayer getInstance].totalPoints] fntFile:@"Chicago.fnt"];
		[score setPosition:ccp(size.width*0.5,size.height*0.5)];
		[score.textureAtlas.texture setAliasTexParameters];
		[self addChild:score];
		
		CCMenuItemSprite *replayButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-try-again.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-try-again.png"] target:self selector:@selector(replayGame:)];
		CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] target:self selector:@selector(backMenu:)];
		
		CCMenu *menu = [CCMenu menuWithItems:replayButton, backButton, nil];
		menu.scale = 0.75;
		menu.position = ccp(size.width*menu.scaleX*0.5, size.height*menu.scaleY*0.1);
		[menu alignItemsVertically];
		[self addChild:menu];
	}
	
	return self;
}

-(void) replayGame:(id)sender {
	[[GameLayer getInstance] restartGame];
	[[GameLayer getInstance] removeOverlay:self];
}

-(void) backMenu:(id)sender {
	[[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
}

@end
