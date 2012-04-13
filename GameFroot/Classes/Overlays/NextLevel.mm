//
//  NextLevel.m
//  GameFroot
//
//  Created by Jose Miguel on 18/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NextLevel.h"
#import "GameLayer.h"
#import "Shared.h"

#define MAIN_MENU_PROGRESS_BAR_LENGTH 410

@implementation NextLevel

NSString *backgroundNext = nil;

- (id)init {
    self = [super init];
    if (self) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        // Loading base assets
        
        CCSprite *bg;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *background = [prefs valueForKey:@"nextBackground"];
        
        if (background == nil) 
        {
            CCLOG(@"IntermediateLayer: Error, loading default one");
            bg = [CCSprite spriteWithFile:@"loading-bg.png"];
        }
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
        
        // PNG is 768x512
        bg.scale = 0.625 * CC_CONTENT_SCALE_FACTOR();
        [bg setPosition:ccp(size.width/2, size.height/2)];
        
        [self addChild:bg];
        
        // Loading progress bar assets
        _loadingTitle = [CCSprite spriteWithFile:@"loading-title.png"];
        [_loadingTitle setScale:CC_CONTENT_SCALE_FACTOR()];
        [_loadingTitle setPosition:ccp(size.width*0.5,size.height/2 + 35)];
        [self addChild:_loadingTitle];
        
        // Loading progress bar assets
        _progressBar = [AGProgressBar progressBarWithFile:@"main_menu.png"];
		[_progressBar.textureAtlas.texture setAliasTexParameters];
        [_progressBar setupWithFrameNamesLeft:@"bar_left.png" right:@"bar_right.png" middle:@"bar_middle.png" andBackgroundLeft:@"loading_bar_back_left.png" right:@"loading_bar_back_right.png" middle:@"loading_bar_back.png" andWidth:(MAIN_MENU_PROGRESS_BAR_LENGTH)];
        
        _progressBar.position = ccp(size.width*0.06,size.height*0.33);
        
        //[self hideProgressBar];
        [self addChild:_progressBar z:10];
    }
    return self;
}

-(void) resetProgressBar {
    [self setProgressBar:0.0f];
}

-(void) setProgressBar:(float)percent
{
    [_progressBar setPercent:percent];
    if (percent >= 100.0f) {
        [[GameLayer getInstance] removeNextLevelScreen];
    }
}

@end
