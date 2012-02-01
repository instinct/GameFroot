//
//  MovingPlatform.h
//  GameManager
//
//  Created by Jose Miguel on 11/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"

@interface MovingPlatform : GameObject {
	
	b2Vec2 origPosition;
	b2Vec2 finalPosition;
	b2Vec2 velocity;
	BOOL goingForward;
	
	float translationXInPixels;
	float translationYInPixels;
	float duration;
	
	BOOL paused;
	BOOL stopped;
	BOOL startedOff;
}

@property (nonatomic, assign) BOOL goingForward;
@property (nonatomic, assign) b2Vec2 velocity;

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size;
-(void) moveVertically:(float)_translationInPixels duration:(float)_duration;
-(void) moveHorizontally:(float)_translationInPixels duration:(float)_duration;
-(void) moveTo:(CGPoint)_pos duration:(float)_duration;
-(void) resetStatus:(BOOL)initial;
-(void) changeDirection;
-(void) update:(ccTime)dt;

-(void) pause;
-(void) resume;
-(void) togle;
-(void) startsOff;

@end
