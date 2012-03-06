//
//  CheckPoint.h
//  DoubleHappy
//
//  Created by Jose Miguel on 29/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"
#import "SimpleAudioEngine.h"

@interface CheckPoint : GameObject {
	int positionX;
	int positionY;
	int tileId;
	int frames;
	BOOL used;
}

-(void) setupCheckPointWithX:(int)x andY:(int)y tileId:(int)_tileId frames:(int)_frames;

@end
