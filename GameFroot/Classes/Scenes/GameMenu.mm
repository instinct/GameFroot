//
//  GameMenu.m
//  GameFroot
//
//
//  Created by Sam Win-Mason on 3/02/12.
//

#import "GameMenu.h"
#import "HomeLayer.h"

@implementation GameMenu

- (id)init {
    self = [super init];
    if (self) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        playMode = NO;
        
        // Loading base assets

        CCSprite *bg = [CCSprite spriteWithFile:@"loading-bg.png"];
        [bg setScale:CC_CONTENT_SCALE_FACTOR()];
        [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
        [self addChild:bg];
        
        CCLabelBMFont *level = [CCLabelBMFont labelWithString:[Shared getLevelTitle] fntFile:@"Chicago.fnt"];
        [level setPosition:ccp(size.width*0.5,size.height*0.8)];
        [self addChild:level];
        
        // Loading menu items
        
        _playButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"placeholder_game_menu_play.png"] selectedSprite:[CCSprite spriteWithFile:@"placeholder_game_menu_play.png"] target:self selector:@selector(_onPlay:)];
        
        CCMenuItemSprite *helpButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"placeholder_game_menu_help.png"] selectedSprite:[CCSprite spriteWithFile:@"placeholder_game_menu_help.png"] target:self selector:@selector(_onHelp:)];
        
        CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] target:self selector:@selector(backMenu:)];
		[backButton setScale:0.75];	
        
        CCMenu *mainMenu = [CCMenu menuWithItems:_playButton, helpButton, backButton, nil];
        [mainMenu alignItemsVerticallyWithPadding:4.0f];
        [self addChild:mainMenu];
        
        // Loading progress bar assets
               
        _loadingTitle = [CCSprite spriteWithFile:@"loading-title.png"];
        [_loadingTitle setScale:CC_CONTENT_SCALE_FACTOR()];
        [_loadingTitle setPosition:ccp(size.width*0.5,size.height*0.2)];
        _loadingTitle.scale = 0.8f;
        
        _progressBarBack = [CCSprite spriteWithFile:@"loading-bar-bg.png"];
        [_progressBarBack setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBarBack setPosition:ccp(size.width*0.5,size.height*0.1)];

        _progressBar = [CCSprite spriteWithFile:@"loading-bar-overlay.png"];
        [_progressBar setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBar setPosition:ccp(size.width*0.225,size.height*0.1075)];
        [_progressBar setAnchorPoint:ccp(0,0.5)];
        
        [self hideProgressBar];
        [self addChild:_loadingTitle];
        [self addChild:_progressBarBack];
        [self addChild:_progressBar z:10];
    }
    return self;
}

// Toggles between the loading and play buttons
-(void) playModeOn:(bool)status {
    if(status) {
        [self hideProgressBar];
        _playButton.visible = YES;
    } else {
        [self showProgressBar];
        _playButton.visible = NO;
    }
}

-(void) backMenu:(id)sender {
    [[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
}

-(void) _onPlay:(id)sender {
    [[GameLayer getInstance] removeLoadingScreen];
}

-(void) _onHelp:(id)sender {
    CCLOG(@"onHelp pushed!");
}

-(void) showProgressBar {
    _loadingTitle.visible = YES;
    _progressBarBack.visible = YES;
    _progressBar.visible = YES;
}

-(void) hideProgressBar {
    _loadingTitle.visible = NO;
    _progressBarBack.visible = NO;
    _progressBar.visible = NO;
}

-(void) resetProgressBar {
    [self setProgressBar:0.0f];
}


-(void) setProgressBar:(float)percent
{
	[_progressBar setTextureRect:CGRectMake(0,0,263*(float)(percent / 100.0f),18/CC_CONTENT_SCALE_FACTOR())];
}

@end
