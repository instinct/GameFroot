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
        
        // Add background guide
        CCSprite *background = [CCSprite spriteWithFile:@"pause_menu_template.png"];
        background.position = ccp(size.width/2, size.height/2);
        [self addChild:background];
        
        //\\//\\// Add main menu stuff //\\//\\//
        
        CCMenuItemSprite *continueButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"continue.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"continue_pressed.png"] target:self selector:@selector(resumeGame)];
        
        CCMenuItemSprite *quitButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"quit.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"quit.png"] target:self selector:@selector(quitGame)];
        
        CCMenu *bottomMenu = [CCMenu menuWithItems:quitButton,continueButton, nil];
        bottomMenu.position = ccp(size.width*bottomMenu.scaleX*0.5, size.height*bottomMenu.scaleY*0.138);
        [bottomMenu alignItemsHorizontallyWithPadding:150];
        [self addChild:bottomMenu];
        
        //\\//\\// add music button //\\//\\//
        
        musicButton = [CCMenuItemToggle itemWithTarget:self selector:@selector(music:) items:
                       [CCMenuItemImage itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"music_off.png"]selectedSprite:[CCSprite spriteWithSpriteFrameName:@"music_off.png"]],                      [CCMenuItemImage itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"music_on.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"music_on.png"]],
                       nil];
        
        CCMenu *musicMenu = [CCMenu menuWithItems:musicButton, nil];
        musicMenu.position = ccp(size.width*musicMenu.scaleX*0.18, size.height*musicMenu.scaleY*0.63);
        [self addChild:musicMenu];
        
        //\\//\\// add controls submenu //\\//\\//
        
        control_option1 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"pro_swipe_off.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"pro_swipe_on.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option2 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"dpad_off.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"dpad_on.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option3 = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"hit_zones_off.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"hit_zones_on.png"] target:self selector:@selector(controllerButtonPressed:)];
        
        control_option1.tag = (int)controlProSwipe;
        control_option2.tag = (int)controlDpad;
        control_option3.tag = (int)controlNoDpad;
        
        CCMenu *controlsMenu = [CCMenu menuWithItems:control_option1, control_option2, control_option3, nil];
        [controlsMenu alignItemsHorizontally];
        controlsMenu.position = ccp(size.width*controlsMenu.scaleX*0.487, size.height*controlsMenu.scaleY*0.348);
        [self addChild:controlsMenu];
        
        //\\//\\//  pause menu state //\\//\\//
        
        // Read saved settings
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		int musicPref = [prefs integerForKey:@"music"];
		[musicButton setSelectedIndex: musicPref];

        // set the selected control method
        //if ([Shared isDebugging]) CCLOG(@"DPad preference: %i", dpadPref);
        [self setControlButtonSelected:[[GameLayer getInstance].controls getControlType]];
	}
	return self;
}

-(void) quitGame
{    
    [[GameLayer getInstance] quitGame];
}

-(void) resumeGame
{
    [[GameLayer getInstance] resumeGame];
}

-(void)music: (id)sender {
	[[GameLayer getInstance] music:sender];
}

-(void)setControlButtonSelected:(GameControlType)tag {
    control_option1.normalImage = [CCSprite spriteWithSpriteFrameName:@"pro_swipe_off.png"];
    control_option2.normalImage = [CCSprite spriteWithSpriteFrameName:@"dpad_off.png"];
    control_option3.normalImage = [CCSprite spriteWithSpriteFrameName:@"hit_zones_off.png"];
    switch (tag) {
        case controlProSwipe:
            control_option1.normalImage = [CCSprite spriteWithSpriteFrameName:@"pro_swipe_on.png"];
            break;
        case controlDpad:
            control_option2.normalImage = [CCSprite spriteWithSpriteFrameName:@"dpad_on.png"];
            break;
        case controlNoDpad:
            control_option3.normalImage = [CCSprite spriteWithSpriteFrameName:@"hit_zones_on.png"];
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
