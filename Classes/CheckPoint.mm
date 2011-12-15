//
//  CheckPoint.m
//  DoubleHappy
//
//  Created by Jose Miguel on 29/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CheckPoint.h"
#import "GameLayer.h"

@implementation CheckPoint

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
}

-(void) setupCheckPointWithX:(int)x andY:(int)y tileId:(int)_tileId frames:(int)_frames
{	
	positionX = x;
	positionY = y;
	tileId = _tileId;
	frames = _frames;
	used = NO;
	type = kGameObjectCollectable;
}

-(void) remove
{
	if (!used) {
		used = YES;
		
		if (frames > 1) [self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"item_%i",tileId] index:1];
		
		// Don't really remove, keep the object
		[[GameLayer getInstance] changeInitialPlayerPositionToX:positionX andY:positionY];
	}
}

@end
