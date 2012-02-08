//
//  Bullet.m
//  DoubleHappy
//
//  Created by Derek Doucett on 11-01-24.
//  Copyright 2011 Ravenous Games. All rights reserved.
//

#import "Bullet.h"
#import "GameLayer.h"
#import "Constants.h"

@implementation Bullet

@synthesize spriteSheet;
@synthesize damage;
@synthesize removing;

+(Bullet *)bullet:(GameObjectDirection)dir weapon:(int)_weapon
{
	Bullet *bullet;
	
	CCSpriteBatchNode *spriteSheet;
	float spriteWidth;
	float spriteHeight;
	
	if (_weapon == 2) {
		spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"bullet_laser.png"];
		spriteWidth = spriteSheet.texture.contentSize.width / 8;
		
	} else if (_weapon == 6) {
		spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"rocketsheet.png"];
		spriteWidth = spriteSheet.texture.contentSize.width / 13;
		
	} else {
		spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"bullet1.png"];
		spriteWidth = spriteSheet.texture.contentSize.width / 8;
	}
	
	spriteHeight = spriteSheet.texture.contentSize.height;
	//CCLOG(@"weapon size: %f,%f", spriteWidth, spriteHeight);
	
	if (_weapon == 2) {
		bullet = [Bullet spriteWithBatchNode:spriteSheet rect:CGRectMake(spriteWidth*2,0,spriteWidth,spriteHeight)];
		
	} else if (_weapon == 6) {
		bullet = [Bullet spriteWithBatchNode:spriteSheet rect:CGRectMake(spriteWidth*4,0,spriteWidth,spriteHeight)];
		
	} else {
		bullet = [Bullet spriteWithBatchNode:spriteSheet rect:CGRectMake(spriteWidth*2,0,spriteWidth,spriteHeight)];
	}
	
	bullet.spriteSheet = spriteSheet;
	
	if (REDUCE_FACTOR != 1.0f) [spriteSheet.textureAtlas.texture setAntiAliasTexParameters];
	else [spriteSheet.textureAtlas.texture setAliasTexParameters];
	
	[[GameLayer getInstance] addBullet:spriteSheet];
	[spriteSheet addChild:bullet];
	
	[bullet initWithDirection:dir weapon:_weapon];
	
	return bullet;
}

-(void) initWithDirection:(GameObjectDirection)dir weapon:(int)_weapon
{
	direction = dir;
	weapon = _weapon;
	
	type = kGameObjectBullet;
	
	damage = 10;
	
	
	if (_weapon == 2) {
		numFrames = 1;
		numFramesExplosion = 4;
		
	} else if (_weapon == 6) {
		numFrames = 2;
		numFramesExplosion = 5;
		
	} else {
		numFrames = 1;
		numFramesExplosion = 4;
	}
	
	spriteWidth = spriteSheet.texture.contentSize.width / ((numFrames*4) + numFramesExplosion);
	spriteHeight = spriteSheet.texture.contentSize.height;
	
	left = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"bullet_left_%i",weapon]];
	if (left == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = (2*numFrames); x < (2*numFrames) + numFrames; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		left = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:left name:[NSString stringWithFormat:@"bullet_left_%i",weapon]];
	}
	
	right = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"bullet_right_%i",weapon]];
	if (right == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = (3*numFrames); x < (3*numFrames) + numFrames; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		right = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:right name:[NSString stringWithFormat:@"bullet_right_%i",weapon]];
	}
	
	explosion = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"bullet_explosion_%i",weapon]];
	if (explosion == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = (4*numFrames); x < (4*numFrames) + numFramesExplosion; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		explosion = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:explosion name:[NSString stringWithFormat:@"bullet_explosion_%i",weapon]];
	}
	
	if (direction == kDirectionLeft) [self runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:left]]];
	else [self runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:right]]];
	
	[self schedule:@selector(update:) interval:1.0/10.0f];
}

-(void) createBox2dObject:(b2World*)world
{
	b2BodyDef bulletBodyDef;
	bulletBodyDef.allowSleep = false;
	bulletBodyDef.fixedRotation = true;
	
	//bulletBodyDef.bullet = true;
	
	// If bullet is kinematic, it won't collide with static objects (platforms)
	// If bullet is dynamic, it will fall with gravity, so ignore gravity for this kind
	//bulletBodyDef.type = b2_kinematicBody;
	bulletBodyDef.type = b2_dynamicBody;
	
	bulletBodyDef.position = b2Vec2((self.position.x/PTM_RATIO), self.position.y/PTM_RATIO);
	bulletBodyDef.userData = self;
	body = world->CreateBody(&bulletBodyDef);
	
	body->SetGravityScale(0.0f);
	
	b2PolygonShape shape;
	shape.SetAsBox((32.0f/6.0f)/(PTM_RATIO*CC_CONTENT_SCALE_FACTOR()), (20.0f/6.0f)/(PTM_RATIO*CC_CONTENT_SCALE_FACTOR()));
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0; // we need this 0 so when moving it doens't slow down
	fixtureDef.restitution = 0.0; // bouncing
	fixtureDef.isSensor = true;
	body->CreateFixture(&fixtureDef);
	
	if (direction == kDirectionLeft) {
		b2Vec2 velocity = b2Vec2(-BULLET_SPEED, 0.0f);
		body->SetLinearVelocity(velocity);
		
	} else {
		b2Vec2 velocity = b2Vec2(BULLET_SPEED, 0.0f);
		body->SetLinearVelocity(velocity);
	}
}

-(void) die {
	if (!removing) {
		
		[self unschedule:@selector(update:)];
		
		removing = YES;
		body->SetLinearVelocity(b2Vec2(0.0f, 0.0f));
        
		id dieAction = [CCSequence actions:
						//[CCHide action],
						[CCAnimate actionWithAnimation:explosion],
						[CCHide action],
						[CCDelayTime actionWithDuration:0.1f],
						[CCCallFunc actionWithTarget:self selector:@selector(destroy)],
						nil];
		[self runAction:dieAction];
	}
}

-(void) destroy
{
	[GameLayer getInstance].world->DestroyBody(body);
    [spriteSheet removeAllChildrenWithCleanup:YES];
	[[GameLayer getInstance] removeBullet:spriteSheet];
}


-(void) update:(ccTime)dt
{
	CGSize winsize = [[CCDirector sharedDirector] winSize];
	CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:self.position];
	//CCLOG(@"%f,%f - %f, %f", pos.x, pos.y, self.contentSize.width, winsize.width);
		
	if (pos.x + self.contentSize.width < 0) {
		[self die];
		return;
		
	} else if (pos.x - self.contentSize.width > winsize.width) {
		[self die];
		return;
		
	} else if (pos.y + self.contentSize.height < 0) {
		[self die];
		return;
		
	} else if (pos.y - self.contentSize.height > winsize.height) {
		[self die];
		return;
	}
	
	[super update:dt];
}


@end
