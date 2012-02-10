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

- (id) init 
{
	if ((self = [super init])) {
		type = kGameObjectMovingPlatform;
		
		paused = NO;
		stopped = NO;
		startedOff = NO;
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
	
    /*
    // Define the box shape as edges
	b2Vec2 lowerLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), 0 - (size.height/2.0f/PTM_RATIO));
	b2Vec2 lowerRight = b2Vec2(size.width/2.0f/PTM_RATIO, 0 - (size.height/2.0f/PTM_RATIO));
	b2Vec2 upperRight = b2Vec2(size.width/2.0f/PTM_RATIO, size.height/2.0f/PTM_RATIO);
	b2Vec2 upperLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), size.height/2.0f/PTM_RATIO);
    
	b2EdgeShape groundBox;		
	
	// bottom
	groundBox.Set(lowerLeft, lowerRight);
	body->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(upperRight, upperLeft);
	body->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(upperLeft, lowerLeft);
	body->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(lowerRight, upperRight);
	body->CreateFixture(&groundBox,0);
    */
    
    
	b2PolygonShape shape;
	shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0;
	fixtureDef.restitution = 0.0; // bouncing
	body->CreateFixture(&fixtureDef);
    
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
	
	[self schedule:@selector(updatePlatform:) interval:duration];
}

-(void) moveHorizontally:(float)_translationInPixels duration:(float)_duration 
{
	[self unschedule:@selector(updatePlatform:)];
	
	translationXInPixels = _translationInPixels;
	duration = _duration * CC_CONTENT_SCALE_FACTOR();
	
	goingForward = YES;
	
	float vel = (translationXInPixels / duration) /PTM_RATIO;
	
	velocity = b2Vec2(vel, 0);
	finalPosition = origPosition + b2Vec2(translationXInPixels/PTM_RATIO, 0);
		
	body->SetLinearVelocity(velocity);
	
	[self schedule:@selector(updatePlatform:) interval:duration];
}

-(void) moveTo:(CGPoint)_pos duration:(float)_duration {
	[self unschedule:@selector(updatePlatform:)];
	
	translationXInPixels = _pos.x - (origPosition.x *PTM_RATIO);
	translationYInPixels = _pos.y - (origPosition.y *PTM_RATIO);
	
	duration = _duration * CC_CONTENT_SCALE_FACTOR();
	
	goingForward = YES;
	
	float velX = (translationXInPixels / duration) /PTM_RATIO;
	float velY = (translationYInPixels / duration) /PTM_RATIO;
	
	velocity = b2Vec2(velX, velY);
	finalPosition = origPosition + b2Vec2(translationXInPixels/PTM_RATIO, translationYInPixels/PTM_RATIO);
		
	body->SetLinearVelocity(velocity);
	
	[self schedule:@selector(updatePlatform:) interval:duration];
}

-(void) changeDirection
{
	b2Vec2 pos = body->GetPosition();
	
	if ((velocity.x != 0) && (velocity.y == 0))
	{		
		// Horizontal platform
		if (goingForward) {
			float diff = (pos.x - origPosition.x) * PTM_RATIO;
			float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(-velocity);
			goingForward = NO;
			
			[self unschedule:@selector(updatePlatform:)];
			[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
			
		} else {
			float diff = (finalPosition.x - pos.x) * PTM_RATIO;
			float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(velocity);
			goingForward = YES;
			
			[self unschedule:@selector(updatePlatform:)];
			[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
		}
		
	} else if ((velocity.x == 0) && (velocity.y != 0))
	{			
		// Vertical platform
		if (goingForward) {
			float diff = (pos.y - origPosition.y) * PTM_RATIO;
			float newDuration = (diff * duration) / translationYInPixels;
			
			body->SetLinearVelocity(-velocity);
			goingForward = NO;
			
			[self unschedule:@selector(updatePlatform:)];
			[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
			
		} else {
			float diff = (finalPosition.y - pos.y) * PTM_RATIO;
			float newDuration = (diff * duration) / translationYInPixels;
			
			body->SetLinearVelocity(velocity);
			goingForward = YES;
			
			[self unschedule:@selector(updatePlatform:)];
			[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
		}
		
			
	} else if ((velocity.x != 0) && (velocity.y != 0))
	{
		// Diagonal platfrom
		if (goingForward) {
			float diff = (pos.x - origPosition.x) * PTM_RATIO;
			float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(-velocity);
			goingForward = NO;
			
			[self unschedule:@selector(updatePlatform:)];
			[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
			
		} else {
			float diff = (finalPosition.x - pos.x) * PTM_RATIO;
			float newDuration = (diff * duration) / translationXInPixels;
			
			body->SetLinearVelocity(velocity);
			goingForward = YES;
			
			[self unschedule:@selector(updatePlatform:)];
			[self schedule:@selector(updateChangedPlatform:) interval:newDuration];
		}
	}
}

-(void) resetStatus:(BOOL)initial 
{
	if (initial && startedOff) {
		[self unschedule:@selector(updateChangedPlatform:)];
		[self unschedule:@selector(updatePlatform:)];
		
		[self startsOff];
		body->SetTransform(origPosition, 0);
		goingForward = YES;
		
	} else if (!paused) {
		[self unschedule:@selector(updateChangedPlatform:)];
		[self unschedule:@selector(updatePlatform:)];
		
		body->SetTransform(origPosition, 0);
		body->SetLinearVelocity(velocity);
		goingForward = YES;
		
		[self schedule:@selector(updatePlatform:) interval:duration];
	}
}

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

-(void) update:(ccTime)dt
{
	if (removed) return;
	
	CGSize winsize = [[CCDirector sharedDirector] winSize];
	
	//CCLOG(@"Moving platform visible:%i, paused:%i, awake:%i, active:%i", self.visible, paused, body->IsAwake(), body->IsActive());
	
	CGPoint posOrig = [[GameLayer getInstance] convertToMapCoordinates:ccp(origPosition.x *PTM_RATIO,origPosition.y *PTM_RATIO)];
	CGPoint posFinal = [[GameLayer getInstance] convertToMapCoordinates:ccp(finalPosition.x *PTM_RATIO,finalPosition.y *PTM_RATIO)];
	
	//CCLOG(@"%f,%f - %f, %f", posOrig.x, posOrig.y, self.contentSize.width, winsize.width);
	
	if ((posOrig.x + self.contentSize.width < 0) && (posFinal.x + self.contentSize.width < 0)) {
		if (self.visible) {
			self.visible = NO;
			//[self pause];
			body->SetActive(false);
		}
		return;
		
		
	} else if ((posOrig.x - self.contentSize.width > winsize.width) && (posFinal.x - self.contentSize.width > winsize.width)) {
		if (self.visible) {
			self.visible = NO;
			//[self pause];
			body->SetActive(false);
		}
		return;
	
	} else if ((posOrig.y + self.contentSize.height < 0) && (posFinal.y + self.contentSize.height < 0)) {
		if (self.visible) {
			self.visible = NO;
			//[self pause];
			body->SetActive(false);
		}
		return;
		
		
	} else if ((posOrig.y - self.contentSize.height > winsize.height) && (posFinal.y - self.contentSize.height > winsize.height)) {
		if (self.visible) {
			self.visible = NO;
			//[self pause];
			body->SetActive(false);
		}
		return;
		
	} else if (!self.visible) {
		self.visible = YES;
		//[self resume];
		body->SetActive(true);
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
