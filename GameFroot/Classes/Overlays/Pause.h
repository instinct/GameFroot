//
//  Pause.h
//  GameFroot
//
//  Created by Jose Miguel on 08/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Shared.h"

@interface Pause : CCLayerColor 
{
    CCMenuItemToggle *musicButton;
	CCMenuItemToggle *dpadButton;
    
    BOOL useDPad;
}

@end
