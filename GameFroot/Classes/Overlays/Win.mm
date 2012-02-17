//
//  Win.m
//  DoubleHappy
//
//  Created by Jose Miguel on 16/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Win.h"
#import "HomeLayer.h"

@implementation Win

// on "init" you need to initialize your instance
-(id) init
{	
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		CCSprite *bg = [CCSprite spriteWithFile:@"loading-bg.png"];
		[bg setScale:CC_CONTENT_SCALE_FACTOR()];
		[bg setPosition:ccp(size.width*0.5,size.height*0.5)];
		[self addChild:bg];
		
		CCSprite *title = [CCSprite spriteWithFile:@"title-you-win.png"];
		[title setPosition:ccp(size.width*0.5,size.height*0.8)];
		[title.textureAtlas.texture setAliasTexParameters];
		title.scale = 0.75;
		[self addChild:title];
		
		CCLabelBMFont *score = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Your score: %i out of %i",[GameLayer getInstance].points, [GameLayer getInstance].totalPoints] fntFile:@"Chicago.fnt"];
		[score setPosition:ccp(size.width*0.5,size.height*0.5)];
		[score.textureAtlas.texture setAliasTexParameters];
		[self addChild:score];
		
		CCMenuItemSprite *replayButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-replay.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-replay.png"] target:self selector:@selector(replayGame:)];
		CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] target:self selector:@selector(backMenu:)];
		
		[replayButton setScale:0.75];
		[backButton setScale:0.75];
		
		CCMenu *menu = [CCMenu menuWithItems:replayButton, backButton, nil];
		menu.position = ccp(size.width/2, size.height/2 - 80);
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
	[[GameLayer getInstance] quitGame];
    [[GameLayer getInstance] removeOverlay:self];
}

@end
