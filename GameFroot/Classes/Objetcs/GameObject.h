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

typedef enum {
    CONTACT_IS_BELOW,
    CONTACT_IS_ABOVE,
    CONTACT_IS_RIGHT,
    CONTACT_IS_LEFT,
    CONTACT_IS_UNDEFINED,
} CONTACT_IS;

typedef struct _contactData {
    id              object;
    b2Contact*      contact;
    CONTACT_IS      position;
} contactData;

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
-(CGPoint) getTilePosition;
-(void) resetPosition;
-(void) update:(ccTime)dt;
-(void) remove;
-(void) destroy;

// collision handling
-( void )handleBeginCollision:( contactData )data;
-( void )handlePreSolve:( contactData )data;
-( void )handlePostSolve:( contactData )data;
-( void )handleEndCollision:( contactData )data;

@end
