//
//  Pause.m
//  GameFroot
//
//  Created by Jose Miguel on 08/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Pause.h"
#import "GameLayer.h"
#import "SimpleAudioEngine.h"
#import "Controls.h"

@implementation Pause

// on "init" you need to initialize your instance
-(id) init
{	
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super initWithColor:ccc4(0,0,0,200)])) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];
        
        [[GameLayer getInstance].controls checkSettings];
        
		CCMenuItemSprite *resumeButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-resume.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-resume-off.png"] target:self selector:@selector(pauseGame)];
		CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-main-menu.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-main-menu-off.png"] target:self selector:@selector(quitGame)];
		
		musicButton = [CCMenuItemToggle itemWithTarget:self selector:@selector(music:) items:
					   [CCMenuItemImage itemFromNormalImage:@"btn-music-on.png" selectedImage:@"btn-music-on.png"],
					   [CCMenuItemImage itemFromNormalImage:@"btn-music-off.png" selectedImage:@"btn-music-off.png"],
					   nil];
		
		dpadButton = [CCMenuItemToggle itemWithTarget:self selector:@selector(dpad:) items:
                      [CCMenuItemImage itemFromNormalImage:@"btn-dpad-off.png" selectedImage:@"btn-dpad-off.png"],
                      [CCMenuItemImage itemFromNormalImage:@"btn-dpad-on.png" selectedImage:@"btn-dpad-on.png"],
                      nil];
		
        
        
		// Read saved settings
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		int musicPref = [prefs integerForKey:@"music"];
		//if ([Shared isDebugging]) CCLOG(@"Music preference: %i", musicPref);
		[musicButton setSelectedIndex: musicPref];
		int dpadPref = [prefs integerForKey:@"dpad"];
		//if ([Shared isDebugging]) CCLOG(@"DPad preference: %i", dpadPref);
		[dpadButton setSelectedIndex: dpadPref];
		useDPad = dpadPref == 1;
		
		CCMenu *menuPause = [CCMenu menuWithItems:resumeButton, backButton, musicButton, dpadButton, nil];
		//menuPause.scale = 0.75;
		menuPause.position = ccp(size.width*menuPause.scaleX*0.5, size.height*menuPause.scaleY*0.5);
		[menuPause alignItemsVertically];
		[self addChild:menuPause];
		[self setScale:CC_CONTENT_SCALE_FACTOR()];
        
        CCMenuItemSprite *restartButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-replay.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-replay.png"] target:self selector:@selector(restartGameFromPause)];
		[restartButton setScale:0.75];		
		CCMenu *menuRestart = [CCMenu menuWithItems:restartButton, nil];
		menuRestart.position = ccp(size.width/2, size.height/2 - 130/CC_CONTENT_SCALE_FACTOR());
		[self addChild:menuRestart];
	}
	
	return self;
}

-(void) quitGame
{    
    [[GameLayer getInstance] quitGame];
}

-(void) pauseGame
{
    [[GameLayer getInstance] pauseGame];
}

-(void)music: (id)sender {
	[[GameLayer getInstance] music:sender];
}

-(void)dpad: (id)sender {
	[[GameLayer getInstance] dpad:sender];
}

-(void) restartGameFromPause
{
    [[GameLayer getInstance] restartGameFromPause];
}

@end
