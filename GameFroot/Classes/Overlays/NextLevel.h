//
//  NextLevel.h
//  GameFroot
//
//  Created by Jose Miguel on 18/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Shared.h"
#import "AGProgressBar.h"

@interface NextLevel : CCLayer {
@private
    CCSprite *_loadingTitle;
    AGProgressBar *_progressBar;
}

-(void) resetProgressBar;
-(void) setProgressBar:(float)percent;

@end
