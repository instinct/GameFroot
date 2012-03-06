//
//  Switch.m
//  DoubleHappy
//
//  Created by Jose Miguel on 23/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Switch.h"

@implementation Switch

@synthesize key;

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

-(void) setupSwitch:(int)_tileId withKey:(NSString *)_key frames:(int)_frames 
{
	key = [_key retain];
	tileId = _tileId;
	frames = _frames;
	type = kGameObjectSwitch;
	active = NO;
}

-(void) resetPosition
{
	if (active) {
		if (frames > 1) [self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"tile_%i",tileId] index:0];
		active = NO;
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Switches 2.caf"];
	}
}

-(void) togle 
{
	if (active) {
		if (frames > 1) [self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"tile_%i",tileId] index:0];
		active = NO;
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Switches 2.caf"];
	} else {
		if (frames > 1) [self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"tile_%i",tileId] index:1];
		active = YES;
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Switches 2.caf"];
	}
}

- (void)dealloc
{
	[key release];
    [super dealloc];
}

@end
