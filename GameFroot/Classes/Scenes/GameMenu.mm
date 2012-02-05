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
        
        CCSprite *bg = [CCSprite spriteWithFile:@"loading-bg.png"];
        [bg setScale:CC_CONTENT_SCALE_FACTOR()];
        [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
        [self addChild:bg];
        
        CCLabelBMFont *level = [CCLabelBMFont labelWithString:[Shared getLevelTitle] fntFile:@"Chicago.fnt"];
        [level setPosition:ccp(size.width*0.5,size.height*0.8)];
        [self addChild:level];
        
        CCSprite *title = [CCSprite spriteWithFile:@"loading-title.png"];
        [title setScale:CC_CONTENT_SCALE_FACTOR()];
        [title setPosition:ccp(size.width*0.5,size.height*0.546875)];
        [self addChild:title];
        
        _progressBarBack = [CCSprite spriteWithFile:@"loading-bar-bg.png"];
        [_progressBarBack setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBarBack setPosition:ccp(size.width*0.5,size.height*0.4)];

        _progressBar = [CCSprite spriteWithFile:@"loading-bar-overlay.png"];
        [_progressBar setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBar setPosition:ccp(size.width*0.225,size.height*0.4075)];
        [_progressBar setAnchorPoint:ccp(0,0.5)];
  
		CCMenuItemSprite *backButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] selectedSprite:[CCSprite spriteWithFile:@"btn-main-menu2.png"] target:self selector:@selector(backMenu:)];
		[backButton setScale:0.75*CC_CONTENT_SCALE_FACTOR()];		
		CCMenu *menu = [CCMenu menuWithItems:backButton, nil];
		menu.position = ccp(size.width/2, size.height/2 - 100);
		[self addChild:menu];
        
        [self hideProgressBar];
        [self addChild:_progressBarBack];
        [self addChild:_progressBar z:10];
    }
    return self;
}

-(void) backMenu:(id)sender {
	[[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
}

-(void) showProgressBar {
    _progressBarBack.visible = YES;
    _progressBar.visible = YES;
}

-(void) hideProgressBar {
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
