//
//  NextLevel.h
//  GameFroot
//
//  Created by Jose Miguel on 18/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameLayer.h"
#import "Shared.h"

@interface NextLevel : CCLayer {
@private
    CCSprite *_loadingTitle;
    CCSprite *_progressBar;
    CCSprite *_progressBarBack;
}

-(void) resetProgressBar;
-(void) setProgressBar:(float)percent;

@end
