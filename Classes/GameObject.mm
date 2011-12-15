//
//  GameObject.m
//  SimpleBox2dScroller
//
//  Created by min on 3/17/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "GameObject.h"
#import "GameLayer.h"

@implementation GameObject

@synthesize type;
@synthesize body;
@synthesize size;
@synthesize removed;

- (id)init
{
    self = [super init];
    if (self) {
        type = kGameObjectNone;
		firstTimeAdded = YES;
    }
    
    return self;
}

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
	body->CreateFixture(&fixtureDef);
	
	removed = NO;
}

-(void) remove
{
	removed = YES;
	
	body->SetLinearVelocity(b2Vec2(0.0f, 0.0f));
		
	id removeAction = [CCSequence actions:
					[CCHide action],
					[CCCallFunc actionWithTarget:self selector:@selector(destroy)],
					nil];
	[self runAction:removeAction];
}

-(void) destroy {
	[GameLayer getInstance].world->DestroyBody(body);
	self.visible = NO;
}

-(void) setPosition:(CGPoint)pos
{
	[super setPosition:pos];
	
	if (firstTimeAdded) {
		originalPosition = self.position;
		firstTimeAdded = NO;
	}
}

-(void) resetPosition
{
	if (removed) {
		[self createBox2dObject:[GameLayer getInstance].world size:size];
		self.position = originalPosition;
		body->SetTransform(b2Vec2(((self.position.x)/PTM_RATIO), (self.position.y)/PTM_RATIO),0);
		self.visible = YES;
		removed = NO;
		
	} else {
		self.position = originalPosition;
		body->SetTransform(b2Vec2(((self.position.x)/PTM_RATIO), (self.position.y)/PTM_RATIO),0);
	}
}

- (void)dealloc
{
    [super dealloc];
}

@end
