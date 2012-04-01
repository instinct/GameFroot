//
//  MovingPlatform.m
//  GameManager
//
//  Created by Jose Miguel on 11/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MovingPlatform.h"
#import "GameLayer.h"

@implementation MovingPlatform

@synthesize goingForward;
@synthesize velocity;
@synthesize isCloud;
@synthesize isKiller;

- (id) init 
{
	if ((self = [super init])) {
		type = kGameObjectMovingPlatform;
		
		paused = NO;
		stopped = NO;
		startedOff = NO;
        isCloud = YES;
        isKiller = NO;
	}
	return self;
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	size = _size;
	
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = true;
	playerBodyDef.fixedRotation = true;
	playerBodyDef.type = b2_kinematicBody;
	playerBodyDef.position = b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO);
	playerBodyDef.userData = self;
	body = world->CreateBody(&playerBodyDef);
	
    // Define the box shape as edges to avoid player to get stuck
	b2Vec2 lowerLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), 0 - (size.height/2.0f/PTM_RATIO));
	b2Vec2 lowerRight = b2Vec2(size.width/2.0f/PTM_RATIO, 0 - (size.height/2.0f/PTM_RATIO));
	b2Vec2 upperRight = b2Vec2(size.width/2.0f/PTM_RATIO, size.height/2.0f/PTM_RATIO);
	b2Vec2 upperLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), size.height/2.0f/PTM_RATIO);
    
    // To avoid vertical moving platforms to trigger an end contact when on top (with side edges)
    // we create left and right edges a bit smaller so they don't touch the top edge
    b2Vec2 nearUpperRight = b2Vec2(size.width/2.0f/PTM_RATIO, (size.height/2.0f/PTM_RATIO)  - 0.1f);
	b2Vec2 nearUpperLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), (size.height/2.0f/PTM_RATIO) - 0.1f);
    
	b2EdgeShape groundBox;		
	
	// bottom
	groundBox.Set(lowerLeft, lowerRight);
	body->CreateFixture(&groundBox,1.0);
	
	// top
	groundBox.Set(upperRight, upperLeft);
	body->CreateFixture(&groundBox,1.0);
	
	// left
	groundBox.Set(nearUpperLeft, lowerLeft);
	body->CreateFixture(&groundBox,1.0);
	
	// right
	groundBox.Set(lowerRight, nearUpperRight);
	body->CreateFixture(&groundBox,1.0);

    
    /*
	b2PolygonShape shape;
	shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0;
	fixtureDef.restitution = 0.0; // bouncing
	body->CreateFixture(&fixtureDef);
    */
    
	origPosition = body->GetPosition();
}

-(void) moveVertically:(float)_translationInPixels duration:(float)_duration 
{
	[self unschedule:@selector(updatePlatform:)];
	
	translationYInPixels = _translationInPixels;
	duration = _duration * CC_CONTENT_SCALE_FACTOR();
	
	goingForward = YES;
	
	float vel = (translationYInPixels / duration) /PTM_RATIO;
	
	velocity = b2Vec2(0, vel);
	finalPosition = origPosition + b2Vec2(0, translationYInPixels/PTM_RATIO);
    
    origAngle = b2Cross(origPosition, finalPosition);
 
	body->SetLinearVelocity(velocity);
}

-(void) moveHorizontally:(float)_translationInPixels duration:(float)_duration 
{
	//[self unschedule:@selector(updatePlatform:)];
	
	translationXInPixels = _translationInPixels;
	duration = _duration * CC_CONTENT_SCALE_FACTOR();
	
	goingForward = YES;
	
	float vel = (translationXInPixels / duration) /PTM_RATIO;
	
	velocity = b2Vec2(vel, 0);
	finalPosition = origPosition + b2Vec2(translationXInPixels/PTM_RATIO, 0);
    
    origAngle = b2Cross(origPosition, finalPosition);

	body->SetLinearVelocity(velocity);
}

-(void) moveTo:(CGPoint)_pos duration:(float)_duration {
	//[self unschedule:@selector(updatePlatform:)];
	
	translationXInPixels = _pos.x - (origPosition.x *PTM_RATIO);
	translationYInPixels = _pos.y - (origPosition.y *PTM_RATIO);
	
	duration = _duration * CC_CONTENT_SCALE_FACTOR();
	
	goingForward = YES;
	
	float velX = (translationXInPixels / duration) /PTM_RATIO;
	float velY = (translationYInPixels / duration) /PTM_RATIO;
	
	velocity = b2Vec2(velX, velY);
	finalPosition = origPosition + b2Vec2(translationXInPixels/PTM_RATIO, translationYInPixels/PTM_RATIO);
    
    origAngle = b2Cross(origPosition, finalPosition);

	body->SetLinearVelocity(velocity);
}

-(void) changeDirection
{
	if (goingForward) {			
        body->SetLinearVelocity(-velocity);
        goingForward = NO;
        
    } else {
        body->SetLinearVelocity(velocity);
        goingForward = YES;
    }
}

-(void) resetStatus:(BOOL)initial 
{
	if (initial && startedOff) {		
		[self startsOff];
		body->SetTransform(origPosition, 0);
		goingForward = YES;

        [self pause];
		
	} else if (!paused) {
		body->SetTransform(origPosition, 0);
		body->SetLinearVelocity(velocity);
		goingForward = YES;
	}
}

-( BOOL )isInsideScreen:( CGPoint )pos {
#if PLATFORM_TRACK_ALWAYS == 1
    return( YES );
#else
    CGSize winSize = [ [ CCDirector sharedDirector ] winSize ];
    CGRect rect;
    
    rect = CGRectMake( -self.contentSize.width - PLATFORM_TRACK_RANGE, 
                      -self.contentSize.height - PLATFORM_TRACK_RANGE,
                      winSize.width + ( self.contentSize.width * 2 ) + ( PLATFORM_TRACK_RANGE * 2 ),
                      winSize.height + ( self.contentSize.height * 2 ) + ( PLATFORM_TRACK_RANGE * 2 ) );
    return( CGRectContainsPoint( rect , pos ) );
#endif
}

-(void) update:(ccTime)dt
{
	if (paused || removed) return;
		
    // check if visible, otherwise hide
	CGPoint pos = [ [ GameLayer getInstance ] convertToMapCoordinates:self.position ];
    if ( [ self isInsideScreen:pos ] == NO ) {
        if ( self.visible ) {
			self.visible = NO;
		}
        
	} else {
        if ( !self.visible ) {
            self.visible = YES;
        }
	}
    
    b2Vec2 bodyPos = body->GetPosition();
    
    if (goingForward) {
        float currentAngle = b2Cross(bodyPos, finalPosition);
        if ((origAngle >= 0) && (currentAngle < 0)) [self changeDirection];
        else if ((origAngle < 0) && (currentAngle >= 0)) [self changeDirection];
        
    } else {
        float currentAngle = b2Cross(bodyPos, origPosition);
        if ((origAngle >= 0) && (currentAngle >= 0)) [self changeDirection];
        else if ((origAngle < 0) && (currentAngle < 0)) [self changeDirection];
    }
    
	[super update:dt];
}

-(void) resume 
{
	if (stopped) return;
	
	[self resumeSchedulerAndActions];
	paused = NO;
    
	if (goingForward) {
		body->SetLinearVelocity(velocity);
		
	} else {
		body->SetLinearVelocity(-velocity);
	}
}

-(void) pause 
{
	[self pauseSchedulerAndActions];	
	paused = YES;
	body->SetLinearVelocity(b2Vec2(0,0));
}

-(void) togle 
{
	if (stopped) {
		stopped = NO;
		[self resume];
		
	} else {
		stopped = YES;
		[self pause];
	}
}

-(void) startsOff
{
	startedOff = YES;
	stopped = YES;
	[self pause];
}

@end
