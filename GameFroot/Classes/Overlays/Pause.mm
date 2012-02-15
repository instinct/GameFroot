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
		
		
        // Create controls menu
        
        CCSprite *controlsLabel = [CCSprite spriteWithFile:@"label-controls.png"];
        controlsLabel.position = ccp(size.width/2 - 90, size.height/2-70/CC_CONTENT_SCALE_FACTOR());
        
        control_option1 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-controls_ps.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-controls_ps_sel.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option2 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-controls_dp.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-controls_dp_sel.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option3 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-controls_hz.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-controls_hz_sel.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option1.tag = (int)controlProSwipe;
        control_option2.tag = (int)controlDpad;
        control_option3.tag = (int)controlNoDpad;
        
        CCMenu *controlsMenu = [CCMenu menuWithItems:control_option1, control_option2, control_option3, nil];
        [controlsMenu alignItemsHorizontally];
        controlsMenu.position = ccp(size.width/2, size.height/2 - 80);
        [self addChild:controlsMenu];
        
		// Read saved settings
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		int musicPref = [prefs integerForKey:@"music"];
        //if ([Shared isDebugging]) CCLOG(@"Music preference: %i", musicPref);
		[musicButton setSelectedIndex: musicPref];

		//int dpadPref = [prefs integerForKey:@"dpad"];
        //if ([Shared isDebugging]) CCLOG(@"DPad preference: %i", dpadPref);
		
		CCMenu *menuPause = [CCMenu menuWithItems:resumeButton, backButton, musicButton, nil];
		
        //menuPause.scale = 0.75;
		menuPause.position = ccp(size.width*menuPause.scaleX*0.5, size.height*menuPause.scaleY*0.6);
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

-(void)controllerButtonPressed:(id)sender {
    CCMenuItemSprite *mi = (CCMenuItemSprite*)sender;
    control_option1.normalImage = [CCSprite spriteWithFile:@"btn-controls_ps.png"];
    control_option2.normalImage = [CCSprite spriteWithFile:@"btn-controls_dp.png"];
    control_option3.normalImage = [CCSprite spriteWithFile:@"btn-controls_hz.png"];

    switch (mi.tag) {
        case 0:
            control_option1.normalImage = [CCSprite spriteWithFile:@"btn-controls_ps_sel.png"];
            break;
        case 1:
            control_option2.normalImage = [CCSprite spriteWithFile:@"btn-controls_dp_sel.png"];
            break;
        case 2:
            control_option3.normalImage = [CCSprite spriteWithFile:@"btn-controls_hz_sel.png"];
            break;
        default:
            break;
    }
    
    [self setControlType:(GameControlType)mi.tag];
}

-(void)setControlType:(GameControlType)type {
    [[GameLayer getInstance].controls setControlType:type];
    
}

-(void) restartGameFromPause {
    [[GameLayer getInstance] restartGameFromPause];
}

@end
