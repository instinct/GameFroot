//
//  Switch.h
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"
#import "SimpleAudioEngine.h"

@interface Switch : GameObject {
	NSString *key;
	int tileId;
	int frames;
	BOOL active;
}

@property (nonatomic,assign) NSString *key;

-(void) setupSwitch:(int)_tileId withKey:(NSString *)_key frames:(int)_frames;
-(void) togle;

@end
