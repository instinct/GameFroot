//
//  IntermediateLayer.m
//  GameFroot
//
//  Created by Jose Miguel on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IntermediateLayer.h"
#import "GameLayer.h"
#import "Shared.h"

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
		
        CCSprite *bg;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *background = [prefs valueForKey:@"nextBackground"];
        
        if (background == nil) 
        {
            CCLOG(@"IntermediateLayer: Error, loading default one");
            bg = [CCSprite spriteWithFile:@"loading-bg.png"];
        }
        
        /*
        else if ( ([background rangeOfString:@"http://"].location != NSNotFound) ||
            ([background rangeOfString:@"https://"].location != NSNotFound) )
        {
            CCLOG(@"IntermediateLayer: Load custom background: %@", background);
            
            // Load Custom background
            @try
            {
                bg = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:background ignoreCache:NO]];
            }
            @catch (NSException * e)
            {
                CCLOG(@"IntermediateLayer: Error, loading default one");
                bg = [CCSprite spriteWithFile:@"loading-bg.png"];
            }
            
        } 
        else 
        {
            CCLOG(@"IntermediateLayer: Load embedded background: %@", [NSString stringWithFormat:@"%@.png", background]);
            bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@.png", background]];
        }
         */
        
        // PNG is 768x512
        bg.scale = 0.625 * CC_CONTENT_SCALE_FACTOR();
        [bg setPosition:ccp(size.width/2, size.height/2)];
        
        [self addChild:bg];
        
        [self scheduleOnce:@selector(_loadLevel) delay:1.0/60.0];
	}
	
	return self;
}

-(void) _loadLevel {
    [[CCDirector sharedDirector] replaceScene:[GameLayer scene]];
}

@end

