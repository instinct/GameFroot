//
//  AGProgressBar.h
//  GameFroot
//
//  Created by Sam Win-Mason on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface AGProgressBar : CCSpriteBatchNode {
    @private
    CCSprite *pbLeftEnd;
    CCSprite *pbRightEnd;
    CCSprite *pb;
    CCSprite *pbBgLeftEnd;
    CCSprite *pbBgRightEnd;
    CCSprite *pbBg;
    int pbWidth;
    bool isSetup;
    float percent;
}

+(id) progressBarWithFile:(NSString *)filename;

-(void) setupWithFrameNamesLeft:(NSString *)left right:(NSString*)right middle:(NSString*)middle andBackgroundLeft:(NSString*)bgl right:(NSString *)bgr middle:(NSString *)bgm andWidth:(int)width;
-(void) setPercent:(float)percent;
-(float) getPercent;

@end
