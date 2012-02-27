//
//  GameMenu.m
//  GameFroot
//
//
//  Created by Sam Win-Mason on 3/02/12.
//

#import "GameMenu.h"
#import "HomeLayer.h"

#define MAIN_MENU_PROGRESS_BAR_LENGTH 410

@implementation GameMenu

- (id)init {
    self = [super init];
    if (self) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        playMode = NO;
        
        // Loading base assets
        
        CCSprite *bg = [CCSprite spriteWithFile:@"blue-bg.png"];
        [bg setScale:CC_CONTENT_SCALE_FACTOR()];
        [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
        [self addChild:bg];
        
        CCLabelBMFont *level = [CCLabelBMFont labelWithString:[Shared getLevelTitle] fntFile:@"Chicpix2.fnt"];
        [level.textureAtlas.texture setAliasTexParameters];
        [level setPosition:ccp(size.width*0.5,size.height*0.8)];
        [self addChild:level];
        
        NSString *authorTextPrefix = @"By ";
        CCLabelBMFont *author = [CCLabelBMFont labelWithString:[authorTextPrefix stringByAppendingString:[[Shared getLevel] valueForKey:@"author"]] fntFile:@"Chicpix.fnt"];
        [author.textureAtlas.texture setAliasTexParameters];
        author.position = ccpSub(level.position, ccp(0,40));
        [self addChild:author];
        
        // Loading menu items
        
        _playButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"play_button_03.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"play_pressed_03.png"] target:self selector:@selector(_onPlay:)];
        
        CCMenuItemSprite *helpButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"help_button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"help_pressed.png"] target:self selector:@selector(_onHelp:)];
        
        CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithSpriteFrameName:@"back_button.png"] selectedSprite:[CCSprite spriteWithSpriteFrameName:@"back_pressed.png"] target:self selector:@selector(backMenu:)];
        
        CCMenu *mainMenu = [CCMenu menuWithItems:backButton, _playButton, helpButton, nil];
        mainMenu.position = ccp(size.width*0.5, size.height*0.4);
        helpButton.position = ccpSub(helpButton.position, ccp(0,(4*CC_CONTENT_SCALE_FACTOR())));
        [mainMenu alignItemsHorizontallyWithPadding:30];
        [self addChild:mainMenu];
        
        CCSprite *inactive_play = [CCSprite spriteWithSpriteFrameName:@"play_deactived.png"];
        inactive_play.position = ccpAdd(mainMenu.position, _playButton.position);
        [self addChild:inactive_play];
        
        // Loading progress bar assets
        _progressBar = [AGProgressBar progressBarWithFile:@"main_menu.png"];
		[_progressBar.textureAtlas.texture setAliasTexParameters];
        [_progressBar setupWithFrameNamesLeft:@"bar_left.png" right:@"bar_right.png" middle:@"bar_middle.png" andBackgroundLeft:@"loading_bar_back_left.png" right:@"loading_bar_back_right.png" middle:@"loading_bar_back.png" andWidth:(MAIN_MENU_PROGRESS_BAR_LENGTH)];
        
        _progressBar.position = ccp(size.width*0.06,size.height*0.13);
        
        //[self hideProgressBar];
        [self addChild:_progressBar z:10];
        [self hideProgressBar];
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
    _progressBar.visible = YES;
}

-(void) hideProgressBar {
    _progressBar.visible = NO;
}

-(void) resetProgressBar {
    [self setProgressBar:0.0f];
}


-(void) setProgressBar:(float)percent
{
    [_progressBar setPercent:percent];
}

@end