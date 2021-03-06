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
#import "AGProgressBar.h"
#import "HelpScreen.h"

@interface GameMenu : CCLayer {
    @private
        CCMenuItemSprite *_playButton;
        AGProgressBar *_progressBar;
        CCLayer *_helpScreen;
        CCMenu *mainMenu;
        bool playMode;
}

-(void) showProgressBar;
-(void) resetProgressBar;
-(void) hideProgressBar;
-(void) setProgressBar:(float)percent;
-(void) playModeOn:(bool)status;
-(void) closeHelp;


@end
