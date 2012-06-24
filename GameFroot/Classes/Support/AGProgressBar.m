//
//  AGProgressBar.m
//  GameFroot
//
//  Created by Sam Win-Mason on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AGProgressBar.h"

#define AG_PROGRESS_BAR_BG_PAD 4

@implementation AGProgressBar

+(id) progressBarWithFile:(NSString *)filename {
    return [AGProgressBar batchNodeWithFile:filename];
}

-(void) setupWithFrameNamesLeft:(NSString *)left 
                          right:(NSString *)right 
                         middle:(NSString *)middle 
              andBackgroundLeft:(NSString *)bgl 
                          right:(NSString *)bgr 
                         middle:(NSString *)bgm
                       andWidth:(int)width {
    
    if(!isSetup) {
        isSetup = YES;
        pbWidth = width;
        percent = 0;
        
        // init sprites
        pbLeftEnd = [CCSprite spriteWithSpriteFrameName:left];
        pb = [CCSprite spriteWithSpriteFrameName:middle];
        pbRightEnd = [CCSprite spriteWithSpriteFrameName:right];
        pbBgLeftEnd = [CCSprite spriteWithSpriteFrameName:bgl];
        pbBg = [CCSprite spriteWithSpriteFrameName:bgm];
        pbBgRightEnd = [CCSprite spriteWithSpriteFrameName:bgr];
        
        pb.zOrder = 10;
        pbLeftEnd.zOrder = 10;
        pbRightEnd.zOrder = 10;
        // setup sprites
        
        // setup background
        CGPoint origin = ccp(0,0);
        pbBgLeftEnd.position = origin;
        pbBg.position = ccpAdd(origin, ccp((((pbWidth + AG_PROGRESS_BAR_BG_PAD))/2),0));
        pbBg.scaleX = ((pbWidth + AG_PROGRESS_BAR_BG_PAD)*CC_CONTENT_SCALE_FACTOR());
        pbBgRightEnd.position = ccpAdd(origin,ccp(((pbWidth + AG_PROGRESS_BAR_BG_PAD)),0));
        
        [self setPercent:percent];
        [self addChild:pbLeftEnd];
        [self addChild:pbRightEnd];
        [self addChild:pb];
        [self addChild:pbBgLeftEnd];
        [self addChild:pbBg];
        [self addChild:pbBgRightEnd];
        
    }
}

-(void) setPercent:(float)value {
    percent = value/100;
    CGPoint origin = ccp(0,0);
    pbLeftEnd.position = ccpAdd(origin, ccp(AG_PROGRESS_BAR_BG_PAD/2,1));
    pb.position = ccpAdd(ccpAdd(origin, ccp(AG_PROGRESS_BAR_BG_PAD/2,1)), ccp((((pbWidth*percent))/2),0));
    pb.scaleX = ((pbWidth*percent)*CC_CONTENT_SCALE_FACTOR());
    pbRightEnd.position = ccpAdd(ccpAdd(origin, ccp(AG_PROGRESS_BAR_BG_PAD/2,1)),ccp(((pbWidth*percent)),0));
}

-(float) getPercent {
    return percent;
}

-(void) setColor:(ccColor3B)color {
    pbLeftEnd.color = color;
    pb.color = color;
    pbRightEnd.color = color;
}



@end
