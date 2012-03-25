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

- (id) init 
{
	if ((self = [super init])) {
		type = kGameObjectMovingPlatform;
		
		paused = NO;
		stopped = NO;
		startedOff = NO;
        isCloud = YES;
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
		
	body->SetLinearVelocity(velocity);
	
	//[self schedule:@selector(updatePlatform:) interval:duration];
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
		
	body->SetLinearVelocity(velocity);
	
	//[self schedule:@selector(updatePlatform:) interval:duration];
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
		
	body->SetLinearVelocity(velocity);
	
	//[self schedule:@selector(updatePlatform:) interval:duration];
}

-(void) changeDirection
{
	b2Vec2 pos = body->GetPosition();
	
	if ((velocity.x != 0) && (velocity.y == 0))
	{		
		// Horizontal platform
		if (goingForward) {
			//float diff = (pos.x - origPosition.x) * PTM_RATIO;
			//float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(-velocity);
			goingForward = NO;
			
			//[self unschedule:@selector(updatePlatform:)];
			//[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
			
		} else {
			//float diff = (finalPosition.x - pos.x) * PTM_RATIO;
			//float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(velocity);
			goingForward = YES;
			
			//[self unschedule:@selector(updatePlatform:)];
			//[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
		}
		
	} else if ((velocity.x == 0) && (velocity.y != 0))
	{			
		// Vertical platform
		if (goingForward) {
			//float diff = (pos.y - origPosition.y) * PTM_RATIO;
			//float newDuration = (diff * duration) / translationYInPixels;
			
			body->SetLinearVelocity(-velocity);
			goingForward = NO;
			
			//[self unschedule:@selector(updatePlatform:)];
			//[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
			
		} else {
			//float diff = (finalPosition.y - pos.y) * PTM_RATIO;
			//float newDuration = (diff * duration) / translationYInPixels;
			
			body->SetLinearVelocity(velocity);
			goingForward = YES;
			
			//[self unschedule:@selector(updatePlatform:)];
			//[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
		}
		
			
	} else if ((velocity.x != 0) && (velocity.y != 0))
	{
		// Diagonal platfrom
		if (goingForward) {
			//float diff = (pos.x - origPosition.x) * PTM_RATIO;
			//float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(-velocity);
			goingForward = NO;
			
			//[self unschedule:@selector(updatePlatform:)];
			//[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
			
		} else {
			//float diff = (finalPosition.x - pos.x) * PTM_RATIO;
			//float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(velocity);
			goingForward = YES;
			
			//[self unschedule:@selector(updatePlatform:)];
			//[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
		}
	}
}

-(void) resetStatus:(BOOL)initial 
{
	if (initial && startedOff) {
		//[self unschedule:@selector(updateChangedPlatform:)];
		//[self unschedule:@selector(updatePlatform:)];
		
		[self startsOff];
		body->SetTransform(origPosition, 0);
		goingForward = YES;
       
        //[self schedule:@selector(updatePlatform:) interval:duration];
        [self pause];
		
	} else if (!paused) {
		//[self unschedule:@selector(updateChangedPlatform:)];
		//[self unschedule:@selector(updatePlatform:)];
		
		body->SetTransform(origPosition, 0);
		body->SetLinearVelocity(velocity);
		goingForward = YES;
		
		//[self schedule:@selector(updatePlatform:) interval:duration];
        
	}
}

/*
-(void) updateChangedPlatform:(ccTime)dt
{
	[self unschedule:@selector(updateChangedPlatform:)];
	
	if (goingForward) {
		body->SetTransform(finalPosition, 0);
		body->SetLinearVelocity(-velocity);
		goingForward = NO;
		
	} else {
		body->SetTransform(origPosition, 0);
		body->SetLinearVelocity(velocity);
		goingForward = YES;
	}
	
	[self schedule:@selector(updatePlatform:) interval:duration];
}

-(void) updatePlatform:(ccTime)dt
{
	if (goingForward) {
		body->SetTransform(finalPosition, 0);
		body->SetLinearVelocity(-velocity);
		goingForward = NO;
		
	} else {
		body->SetTransform(origPosition, 0);
		body->SetLinearVelocity( velocity );
		goingForward = YES;
	}
}
*/

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

-(float) distanceDestination:(b2Vec2)pos1 pos2:(b2Vec2)pos2
{
    return (pos2.x - pos1.x) + (pos2.y - pos1.y);
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
        float diff = [self distanceDestination:bodyPos pos2:finalPosition];
        //if ( [ self isInsideScreen:pos ] ) CCLOG(@"moving forward: %f", diff);
        if (diff < 0) [self changeDirection];
        
    } else {
        float diff = [self distanceDestination:bodyPos pos2:origPosition];
        //if ( [ self isInsideScreen:pos ] ) CCLOG(@"moving backward: %f", diff);
        if (diff > 0) [self changeDirection];
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
