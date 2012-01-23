//
//  GameObject.h
//  SimpleBox2dScroller
//
//  Created by min on 3/17/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "cocos2d.h"
#import "Constants.h"
#import "Box2D.h"

enum ANIM { STAND = 0, WALK, CROUCH, PRONE, JUMPING, FALLING };

@interface GameObject : CCSprite {
	b2Body *body;
	
    GameObjectType type;
	
	CGSize size;
	
	BOOL removed;
	
	BOOL firstTimeAdded;
	CGPoint originalPosition;
}

@property (nonatomic, readwrite) GameObjectType type;
@property (nonatomic, readwrite) b2Body *body;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) BOOL removed;

-(void) createBox2dObject:(b2World*)world size:(CGSize)size;
-(void) remove;
-(void) resetPosition;
-(void) update:(ccTime)dt;

@end
