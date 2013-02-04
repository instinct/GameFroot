//
//  SplashLayer.m
//  GameFroot
//
//  Created by Jose Miguel on 13/12/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SplashLayer.h"
#import "HomeLayer.h"
#import "Loader.h"
#import "Shared.h"
#import "Constants.h"

@implementation SplashLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SplashLayer *layer = [SplashLayer node];
	
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
		
		CCSprite *splash;
        if (IS_IPHONE5()) splash = [CCSprite spriteWithFile:@"Default-568h@2x.png"];
        else splash = [CCSprite spriteWithFile:@"Default.png"];
        
		[splash setPosition:ccp(size.width/2, size.height/2)];
		[self addChild:splash];
		
		[Loader showAsynchronousLoaderWithDelayedActionAtPoint:ccp(size.width/2, size.height/2 + 150) delay:2.0f target:self selector:@selector(_loadGame)];
	}
	
	return self;
}

-(void) _loadGame {
	[[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
}

@end
