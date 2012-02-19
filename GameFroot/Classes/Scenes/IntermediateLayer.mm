//
//  IntermediateLayer.m
//  GameFroot
//
//  Created by Jose Miguel on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IntermediateLayer.h"
#import "GameLayer.h"

@implementation IntermediateLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	IntermediateLayer *layer = [IntermediateLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

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
        
        // Loading progress bar assets
        CCSprite *_loadingTitle = [CCSprite spriteWithFile:@"loading-title.png"];
        [_loadingTitle setScale:CC_CONTENT_SCALE_FACTOR()];
        [_loadingTitle setPosition:ccp(size.width*0.5,size.height/2 + 35)];
        
        CCSprite *_progressBarBack = [CCSprite spriteWithFile:@"loading-bar-bg.png"];
        [_progressBarBack setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBarBack setPosition:ccp(size.width*0.5,size.height/2 - 10)];
        
        [self addChild:_loadingTitle];
        [self addChild:_progressBarBack];
        
        [self scheduleOnce:@selector(_loadLevel) delay:1.0/60.0];
	}
	
	return self;
}

-(void) _loadLevel {
    [[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
}

@end

