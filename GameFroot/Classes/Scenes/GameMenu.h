//
//  GameMenu.h
//  GameFroot
//
//  Created by Sam Win-Mason on 3/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameLayer.h"
#import "Shared.h"

@interface GameMenu : CCLayer {
    @private 
        CCSprite *_progressBar;
        CCSprite *_progressBarBack;
}

-(void) showProgressBar;
-(void) resetProgressBar;
-(void) hideProgressBar;
-(void) setProgressBar:(float)percent;

@end
