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

#define TILE_TYPE_NONE                  0
#define TILE_TYPE_SOLID                 1
#define TILE_TYPE_CLOUD                 2
#define TILE_TYPE_SPIKE                 3
#define TILE_TYPE_ICE                   4
#define TILE_TYPE_DESTRUCTABLE          5

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
    
    BOOL spawned;
    
    // Manages body transfromations
    BOOL flagToDestroyBody;
    BOOL flagToTransformBody;
    BOOL flagToRecreateBody;
    CGSize recreateSize;
    b2Vec2 tranformPosition;
    float tranformAngle;
    
}

@property (nonatomic, readwrite) GameObjectType type;
@property (nonatomic, readwrite) b2Body *body;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) BOOL removed;
@property (nonatomic, assign) BOOL spawned;

-(void) createBox2dObject:(b2World*)world size:(CGSize)size;
-(BOOL) applyPendingBox2dActions;
-(void) markToDestroyBody;
-(void) markToTransformBody:(b2Vec2)position angle:(float)angle;
-(void) markToRecreateBody:(CGSize)size;

-(BOOL) interacted;

-(CGPoint) getTilePosition;
-(void) restart;
-(void) update:(ccTime)dt;
-(void) remove;
-(void) destroy;

// collision handling
-( void )handleBeginCollision:( contactData )data;
-( void )handlePreSolve:( contactData )data manifold:(const b2Manifold *)oldManifold;
-( void )handlePostSolve:( contactData )data impulse:(const b2ContactImpulse *)impulse;
-( void )handleEndCollision:( contactData )data;

@end
