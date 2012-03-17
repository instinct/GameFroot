//
//  Collectable.m
//  DoubleHappy
//
//  Created by Jose Miguel on 30/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Collectable.h"
#import "GameLayer.h"
#import "SimpleAudioEngine.h"

@implementation Collectable

@synthesize itemType;
@synthesize itemValue;

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
	shape.SetAsBox((size.width/4.0)/PTM_RATIO, (size.height/4.0f)/PTM_RATIO);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0;
	fixtureDef.restitution = 0.0; // bouncing
	fixtureDef.isSensor = true;
	body->CreateFixture(&fixtureDef);
	
	removed = NO;
}

-(void) remove
{
    
	
	if (itemType == kCollectableMoney) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Coin.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] increasePoints:itemValue];
		[super remove];
		
	} else if (itemType == kCollectableAmmo) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Ammo.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] increaseAmmo:itemValue];
		[super remove];
		
	} else if (itemType == kCollectableWeapon) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"W Change weapon.caf" pitch:1.0f pan:0.0f gain:1.0f];
		if (itemValue < 8) [[GameLayer getInstance] changeWeapon:itemValue-1];
		else [[GameLayer getInstance] increaseAmmo:itemValue];
		[super remove];
	
	} else if (itemType == kCollectableJetpack) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Star and gem.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] jetpack];
		[super remove];
	
	} else if (itemType == kCollectableHealth) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Star and gem.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] increaseHealth:itemValue];
		[super remove];
		
	} else if (itemType == kCollectableTime) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Star and gem.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] increaseTime:itemValue];
		[super remove];
		
	} else if (itemType == kCollectableLive) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Star and gem.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] increaseLive:1];
		[super remove];
		
	} else if (itemType == kCollectableFinal) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Check Point - Harp.caf" pitch:1.0f pan:0.0f gain:1.0f];
		[[GameLayer getInstance] winGame];
		removed = YES;
	}
}

@end
