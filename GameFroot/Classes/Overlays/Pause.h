//
//  Pause.h
//  GameFroot
//
//  Created by Jose Miguel on 08/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Shared.h"
#import "Controls.h"

@interface Pause : CCLayerColor 
{
    CCMenuItemToggle *musicButton;
	CCMenuItemToggle *controlsButton;
    CCMenuItemSprite *control_option1;
    CCMenuItemSprite *control_option2;
    CCMenuItemSprite *control_option3;
}
-(void)setControlType:(GameControlType)type;

@end
