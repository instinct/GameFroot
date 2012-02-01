//
//  TeleTransporter.m
//  DoubleHappy
//
//  Created by Jose Miguel on 28/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TeleTransporter.h"
#import "GameLayer.h"

@implementation TeleTransporter

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	size = _size;
	
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = true;
	playerBodyDef.fixedRotation = true;
	playerBodyDef.type = b2_staticBody;
	playerBodyDef.position.Set(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO);
	playerBodyDef.userData = self;
	body = world->CreateBody(&playerBodyDef);
	
	b2PolygonShape shape;
	shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0;
	fixtureDef.restitution = 0.0; // bouncing
	fixtureDef.isSensor = true;
	body->CreateFixture(&fixtureDef);
	
	removed = NO;
	active = NO;
}

-(void) setupTeleTransporterWithX:(int)x andY:(int)y 
{
	destinationX = x;
	destinationY = y;
}

-(void) remove
{
	if (!active) {
		active = YES;
		
		// Don't really remove, keep the object
		[[GameLayer getInstance] transportPlayerToX:destinationX andY:destinationY];
		
		// schedule to de-activate
		[self schedule:@selector(deactivate) interval:1.0f];
	}
}

-(void) deactivate
{
	[self unschedule:@selector(deactivate)];
	
	active = NO;
}

@end
