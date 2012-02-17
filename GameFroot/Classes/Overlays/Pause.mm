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
        
		CCMenuItemSprite *resumeButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-resume.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-resume-off.png"] target:self selector:@selector(pauseGame)];
		
        CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-main-menu.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-main-menu-off.png"] target:self selector:@selector(quitGame)];
		
		musicButton = [CCMenuItemToggle itemWithTarget:self selector:@selector(music:) items:
					   [CCMenuItemImage itemFromNormalImage:@"btn-music-on.png" selectedImage:@"btn-music-on.png"],
					   [CCMenuItemImage itemFromNormalImage:@"btn-music-off.png" selectedImage:@"btn-music-off.png"],
					   nil];
		
		
        // Create controls menu
        
        CCSprite *controlsLabel = [CCSprite spriteWithFile:@"label-controls.png"];
       
        
        control_option1 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-controls_ps.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-controls_ps_sel.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option2 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-controls_dp.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-controls_dp_sel.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option3 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-controls_hz.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-controls_hz_sel.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option1.tag = (int)controlProSwipe;
        control_option2.tag = (int)controlDpad;
        control_option3.tag = (int)controlNoDpad;
        
        CCMenu *controlsMenu = [CCMenu menuWithItems:control_option1, control_option2, control_option3, nil];
        [controlsMenu alignItemsHorizontally];
        controlsMenu.position = ccp(size.width/2 + 70, size.height/2 - 80);
        controlsLabel.position = ccp(controlsMenu.position.x - 170, controlsMenu.position.y);
        [self addChild:controlsLabel];
        [self addChild:controlsMenu];
        
		// Read saved settings
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		int musicPref = [prefs integerForKey:@"music"];
        //if ([Shared isDebugging]) CCLOG(@"Music preference: %i", musicPref);
		[musicButton setSelectedIndex: musicPref];

		// set the selected control method
        //if ([Shared isDebugging]) CCLOG(@"DPad preference: %i", dpadPref);
        [self setControlButtonSelected:[[GameLayer getInstance].controls getControlType]];
		
		CCMenu *menuPause = [CCMenu menuWithItems:resumeButton, backButton, musicButton, nil];
		
        //menuPause.scale = 0.75;
		menuPause.position = ccp(size.width*menuPause.scaleX*0.5, size.height*menuPause.scaleY*0.6);
		[menuPause alignItemsVertically];
		
        [self addChild:menuPause];
        
        CCMenuItemSprite *restartButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-replay.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-replay.png"] target:self selector:@selector(restartGameFromPause)];
		[restartButton setScale:0.75];		
		CCMenu *menuRestart = [CCMenu menuWithItems:restartButton, nil];
		menuRestart.position = ccp(size.width/2, size.height/2 - 130);
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

-(void)setControlButtonSelected:(GameControlType)tag {
    control_option1.normalImage = [CCSprite spriteWithFile:@"btn-controls_ps.png"];
    control_option2.normalImage = [CCSprite spriteWithFile:@"btn-controls_dp.png"];
    control_option3.normalImage = [CCSprite spriteWithFile:@"btn-controls_hz.png"];
    switch (tag) {
        case controlProSwipe:
            control_option1.normalImage = [CCSprite spriteWithFile:@"btn-controls_ps_sel.png"];
            break;
        case controlDpad:
            control_option2.normalImage = [CCSprite spriteWithFile:@"btn-controls_dp_sel.png"];
            break;
        case controlNoDpad:
            control_option3.normalImage = [CCSprite spriteWithFile:@"btn-controls_hz_sel.png"];
            break;
        default:
            break;
    }
}

-(void)controllerButtonPressed:(id)sender {
    CCMenuItemSprite *mi = (CCMenuItemSprite*)sender;
    [self setControlButtonSelected:(GameControlType)mi.tag];   
    [self setControlType:(GameControlType)mi.tag];
}

-(void)setControlType:(GameControlType)type {
    [[GameLayer getInstance].controls setControlType:type];
}

-(void) restartGameFromPause {
    [[GameLayer getInstance] restartGameFromPause];
}

-(void) show {
    // update buttons if settings have changed
    [self setControlButtonSelected:[[GameLayer getInstance].controls getControlType]];
    [super show];
}

@end
