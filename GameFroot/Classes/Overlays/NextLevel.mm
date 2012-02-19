//
//  NextLevel.m
//  GameFroot
//
//  Created by Jose Miguel on 18/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NextLevel.h"

@implementation NextLevel

- (id)init {
    self = [super init];
    if (self) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        // Loading base assets
        
        CCSprite *bg = [CCSprite spriteWithFile:@"loading-bg.png"];
        [bg setScale:CC_CONTENT_SCALE_FACTOR()];
        [bg setPosition:ccp(size.width*0.5,size.height*0.5)];
        [self addChild:bg];
        
        //CCLabelBMFont *level = [CCLabelBMFont labelWithString:[Shared getLevelTitle] fntFile:@"Chicago.fnt"];
        //[level setPosition:ccp(size.width*0.5,size.height*0.8)];
        //[self addChild:level];
        
        // Loading progress bar assets
        _loadingTitle = [CCSprite spriteWithFile:@"loading-title.png"];
        [_loadingTitle setScale:CC_CONTENT_SCALE_FACTOR()];
        [_loadingTitle setPosition:ccp(size.width*0.5,size.height/2 + 30)];
        
        _progressBarBack = [CCSprite spriteWithFile:@"loading-bar-bg.png"];
        [_progressBarBack setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBarBack setPosition:ccp(size.width*0.5,size.height/2 - 10)];
        
        _progressBar = [CCSprite spriteWithFile:@"loading-bar-overlay.png"];
        [_progressBar setScale:CC_CONTENT_SCALE_FACTOR()];
        [_progressBar setPosition:ccp(size.width*0.225,size.height/2 - 11)];
        [_progressBar setAnchorPoint:ccp(0,0.5)];
        
        [self resetProgressBar];
        [self addChild:_loadingTitle];
        [self addChild:_progressBarBack];
        [self addChild:_progressBar z:10];
    }
    return self;
}

-(void) resetProgressBar {
    [self setProgressBar:0.0f];
}


-(void) setProgressBar:(float)percent
{
	[_progressBar setTextureRect:CGRectMake(0,0,263*(float)(percent / 100.0f),18/CC_CONTENT_SCALE_FACTOR())];
    if (percent >= 100.0f) {
        [[GameLayer getInstance] removeNextLevelScreen];
    }
}

@end
