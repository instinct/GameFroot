//
//  Player.m
//  DoubleHappy
//
//  Created by Jose Miguel on 08/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Player.h"
#import "GameLayer.h"
#import "Constants.h"
#import "Bullet.h"
#import "GB2ShapeCache.h"

@implementation Player

@synthesize action;
@synthesize ignoreGravity;
@synthesize shootDelay;
@synthesize shootDamage;

-(void) setupPlayer:(int)_playerID initialX:(int)dx initialY:(int)dy
{
	playerID = _playerID;
	
	type = kGameObjectPlayer;
	moving = NO;
	direction = kDirectionNone;
	facingLeft = NO;
	initialX = originalX = dx;
	initialY = originalY = dy;
	jetpackCollected = NO;
	jetpackActivated = NO;
	lose = NO;
	win = NO;
	scrollOnProne = 0;
	
	lives = 3;
	health = 100;
	
	float spriteWidth = self.batchNode.texture.contentSize.width / 8;
	float spriteHeight = self.batchNode.texture.contentSize.height / 2;
	
	// Weapon
	[self changeWeapon:4]; // Default weapon
	
	// Player animations
	stand = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"stand_%i",playerID]];
	if (stand == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		stand = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:stand name:[NSString stringWithFormat:@"stand_%i",playerID]];
	}
	
	walk = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"walk_%i",playerID]];
	if (walk == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 6; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		walk = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:walk name:[NSString stringWithFormat:@"walk_%i",playerID]];
	}
	
	crouch = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"crouch_%i",playerID]];
	if (crouch == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 7; x <= 7; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		crouch = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:crouch name:[NSString stringWithFormat:@"crouch_%i",playerID]];
	}
	
	prone = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"prone_%i",playerID]];
	if (prone == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		prone = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:prone name:[NSString stringWithFormat:@"prone_%i",playerID]];
	}
	
	jump = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"jump_%i",playerID]];
	if (jump == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 2; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		jump = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:jump name:[NSString stringWithFormat:@"jump_%i",playerID]];
	}
	
	die = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"die_%i",playerID]];
	if (die == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 3; x <= 7; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		die = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:die name:[NSString stringWithFormat:@"die_%i",playerID]];
	}
}

-(void) changeWeapon:(int)_weaponID
{
	CCLOG(@"Player.changeWeapon: %i", _weaponID);
	
	if (weaponSpriteSheet != nil) {
		[[GameLayer getInstance] removeObject:weaponSpriteSheet];
	}
	
	weaponID = _weaponID;
	
	switch (weaponID) {
		case 0: // Pistol
			
			shootDamage = 25;
			shootDelay= 0.5f;
			bulletOffsetY = -2/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 1: // Auto shotgun
			
			shootDamage = 25;
			shootDelay = 0.2f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 2: // Laser
			
			shootDamage = 50;
			shootDelay = 0.1f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 3: // Musket
			
			shootDamage = 150;
			shootDelay = 1.0f;
			bulletOffsetY = 0;
			
			break;
			
		case 4: // AK 47
			
			shootDamage = 70;
			shootDelay = 0.05f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 5: // M60
			
			shootDamage = 120;
			shootDelay = 0.05f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 6: // Rocket Launcher
			
			shootDamage = 400;
			shootDelay = 1.2f;
			bulletOffsetY = 5/CC_CONTENT_SCALE_FACTOR();
			
			break;
	}
	
	weaponSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"weapon_%i.png",weaponID]];
	
	if (REDUCE_FACTOR != 1.0f) [weaponSpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
	else [weaponSpriteSheet.textureAtlas.texture setAliasTexParameters];
	
	[[GameLayer getInstance] addObject:weaponSpriteSheet];
	
	float spriteWidth = weaponSpriteSheet.texture.contentSize.width / 8;
	float spriteHeight = weaponSpriteSheet.texture.contentSize.height / 2;
	
	weapon = [CCSprite spriteWithBatchNode:weaponSpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];
	[weapon setAnchorPoint:ccp(0.41,0.33)];
	[weapon retain];
	[weaponSpriteSheet addChild:weapon];
	
	// Weapon animations
	standWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_stand_%i",weaponID]];
	if (standWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		standWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:standWeapon name:[NSString stringWithFormat:@"weapon_stand_%i",weaponID]];
	}
	
	walkWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_walk_%i",weaponID]];
	if (walkWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 6; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		walkWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:walkWeapon name:[NSString stringWithFormat:@"weapon_walk_%i",weaponID]];
	}
	
	crouchWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_crouch_%i",weaponID]];
	if (crouchWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 7; x <= 7; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		crouchWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:crouchWeapon name:[NSString stringWithFormat:@"weapon_crouch_%i",weaponID]];
	}
	
	proneWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_prone_%i",weaponID]];
	if (proneWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		proneWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:proneWeapon name:[NSString stringWithFormat:@"weapon_prone_%i",weaponID]];
	}
	
	jumpWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_jump_%i",weaponID]];
	if (jumpWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 2; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		jumpWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:jumpWeapon name:[NSString stringWithFormat:@"weapon_jump_%i",weaponID]];
	}
	
	if (facingLeft) {
		weapon.scaleX = -1;
	}
}

-(void) setState:(int) anim
{
	if (action == anim)	return;
	
	//CCLOG(@"Player.setState: %i", anim);
	
	if (!immortal) {
		[self stopAllActions];
		[weapon stopAllActions];
		if (jetpackCollected) [jetpack stopAllActions];
		
		self.opacity = 255;
		
		weapon.opacity = 255;
		weapon.visible = YES;
		
		if (jetpackCollected) {
			jetpack.opacity = 255;
			jetpack.visible = YES;
		}
	}
	
	action = anim;
	
	if (anim == STAND)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"stand_%i",playerID] index:0];
		[weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_stand_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_stand" index:0];
	}
	else if (anim == WALK)
	{
		[self runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walk]]];
		[weapon runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walkWeapon]]];
		if (jetpackCollected) [jetpack runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walkJetpack]]];
	}
	else if (anim == CROUCH)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"crouch_%i",playerID] index:0];
		[weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_crouch_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_crouch" index:0];
	}
	else if (anim == PRONE)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"prone_%i",playerID] index:0];
		[weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_prone_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_prone" index:0];
	}
	else if (anim == JUMPING)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"jump_%i",playerID] index:0];
		[weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_jump_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_jump" index:0];
	}
	else if (anim == FALLING)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"jump_%i",playerID] index:1];
		[weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_jump_%i",weaponID] index:1];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_jump" index:1];
	}
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	//CCLOG(@"Player.createBox2dObject");
	
	size = _size;
	
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = false;
	playerBodyDef.fixedRotation = true;
	playerBodyDef.type = b2_dynamicBody;
	playerBodyDef.position = b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y + 0)/PTM_RATIO);
	playerBodyDef.userData = self;
	body = world->CreateBody(&playerBodyDef);
	
	[[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"player"];
	
	/*
	 b2PolygonShape shape;
	 shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
	 b2FixtureDef fixtureDef;
	 fixtureDef.shape = &shape;
	 fixtureDef.density = 1.0;
	 fixtureDef.friction = 0.0; // we need this 0 so when moving it doens't slow down
	 fixtureDef.restitution = 0.0; // bouncing
	 body->CreateFixture(&fixtureDef);
	 */
}

-(void) moveRight
{
	if (!dying && !immortal) {
		
		b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(HORIZONTAL_SPEED + horizontalSpeedOffset, current.y);
		body->SetLinearVelocity(velocity);
		
		self.scaleX = 1;
		
		if (type == kGameObjectPlayer) {
			weapon.scaleX = 1;
			if (jetpackCollected) {
				jetpack.scaleX = 1;
				particle.angle = 240.0;
			}
		}
		
		if (!jetpackCollected || !jetpackActivated) [self setState:WALK];
		
		moving = YES;
		direction = kDirectionRight;
		facingLeft = NO;
	}
}

-(void) moveLeft
{
	if (!dying && !immortal) {
		
		b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(-HORIZONTAL_SPEED + horizontalSpeedOffset, current.y);
		body->SetLinearVelocity(velocity);
		
		self.scaleX = -1;
		
		if (type == kGameObjectPlayer) {
			weapon.scaleX = -1;
			if (jetpackCollected) {
				jetpack.scaleX = -1;
				particle.angle = 280.0;
			}
		}
		
		if (!jetpackCollected || !jetpackActivated) [self setState:WALK];
		
		moving = YES;
		direction = kDirectionLeft;
		facingLeft = YES;
	}
}

-(void) restartMovement {
	if (!dying && !immortal && (moving || jumpingMoving)) {
		b2Vec2 current = body->GetLinearVelocity();
		
		if (fabsf(roundf(current.x)) == 0) {
			
			if (direction == kDirectionLeft) {
				b2Vec2 velocity = b2Vec2(-HORIZONTAL_SPEED + horizontalSpeedOffset, current.y);
				body->SetLinearVelocity(velocity);
				
			} else if (direction == kDirectionRight) {
				b2Vec2 velocity = b2Vec2(HORIZONTAL_SPEED + horizontalSpeedOffset, current.y);
				body->SetLinearVelocity(velocity);
			}	
		}
	}
}

-(void) jump
{	
    if ((action == PRONE) || (action == CROUCH)) {
        //[self setState:STAND];
        return;
    }
    
	pressedJump = YES;
	
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"Player.jump: %i, %f, %i", canJump, fabsf(roundf(current.y)), ignoreGravity);
	if (canJump && !dying && !immortal && ((fabsf(roundf(current.y)) == 0) || ignoreGravity)) {
		canJump = NO;
		jumping = YES;
		b2Vec2 impulse = b2Vec2(0.0f, VERTICAL_SPEED);
		body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
		
	} else if (jetpackCollected && !jetpackActivated && !dying && !immortal) {
		//b2Vec2 impulse = b2Vec2(0.0f, fabs(current.y) + JETPACK_SPEED);
		//body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
		
		jetpackActivated = YES;
		[particle resetSystem];
		
		b2Vec2 impulse = b2Vec2(0.0f, fabs(current.y) + JETPACK_IMPULSE);
		body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
	}
}

-(void) jumpDirection:(GameObjectDirection)dir
{
    if ((action == PRONE) || (action == CROUCH)) {
        //[self setState:STAND];
        return;
    }
    
	pressedJump = YES;
	
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"Player.jumDirection: %i, %i, %f, %i", dir, canJump, fabsf(roundf(current.y)), ignoreGravity);
	if (canJump && !dying && !immortal && ((fabsf(roundf(current.y)) == 0) || ignoreGravity)) {
		
		canJump = NO;
		jumping = YES;
		jumpingMoving = YES;
		b2Vec2 impulse;
		
		if (dir == kDirectionLeft) {
			impulse = b2Vec2(-HORIZONTAL_SPEED, VERTICAL_SPEED);
			
			self.scaleX = -1;
			direction = kDirectionLeft;
			facingLeft = YES;
			
			if (type == kGameObjectPlayer) {
				weapon.scaleX = -1;
				if (jetpackCollected) {
					jetpack.scaleX = -1;
					particle.angle=280.0;
				}
			}
			
		} else {
			impulse = b2Vec2(HORIZONTAL_SPEED, VERTICAL_SPEED);
			
			self.scaleX = 1;
			direction = kDirectionRight;
			facingLeft = NO;
			
			if (type == kGameObjectPlayer) {
				weapon.scaleX = 1;
				if (jetpackCollected) {
					jetpack.scaleX = 1;
					particle.angle=240.0;
				}
			}
		}
		
		body->SetLinearVelocity(b2Vec2(0.0f, 0.0f)); // reset previous movement
		body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
		
	} else if (jetpackCollected && !jetpackActivated && !dying && !immortal) {
		
		jetpackActivated = YES;
		[particle resetSystem];
		
		if (dir == kDirectionLeft) {
			body->SetLinearVelocity(b2Vec2(0,current.y));
			b2Vec2 impulse = b2Vec2(-HORIZONTAL_SPEED, fabs(current.y) + JETPACK_IMPULSE);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = -1;
			direction = kDirectionLeft;
			facingLeft = YES;
			
			if (type == kGameObjectPlayer) {
				weapon.scaleX = -1;
				if (jetpackCollected) {
					jetpack.scaleX = -1;
					particle.angle=280.0;
				}
			}
			
		} else {
			body->SetLinearVelocity(b2Vec2(0,current.y));
			b2Vec2 impulse = b2Vec2(HORIZONTAL_SPEED, fabs(current.y) + JETPACK_IMPULSE);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = 1;
			direction = kDirectionRight;
			facingLeft = NO;
			
			if (type == kGameObjectPlayer) {
				weapon.scaleX = 1;
				if (jetpackCollected) {
					jetpack.scaleX = 1;
					particle.angle=240.0;
				}
			}
		}
		
	} else if (jumping && !dying && !immortal) {
		//CCLOG(@"Player.jumDirection: change direction in the air");
		if (dir == kDirectionLeft) {
			body->SetLinearVelocity(b2Vec2(0,current.y));
			b2Vec2 impulse = b2Vec2(-HORIZONTAL_SPEED, 0.0f);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = -1;
			direction = kDirectionLeft;
			facingLeft = YES;
			
			if (type == kGameObjectPlayer) {
				weapon.scaleX = -1;
				if (jetpackCollected) {
					jetpack.scaleX = -1;
					particle.angle=280.0;
				}
			}
			
		} else {
			body->SetLinearVelocity(b2Vec2(0,current.y));
			b2Vec2 impulse = b2Vec2(HORIZONTAL_SPEED, 0.0f);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = 1;
			direction = kDirectionRight;
			facingLeft = NO;
			
			if (type == kGameObjectPlayer) {
				weapon.scaleX = 1;
				if (jetpackCollected) {
					jetpack.scaleX = 1;
					particle.angle=240.0;
				}
			}
		}
	}
}

-(void) resetJump
{
	if (pressedJump) {
		pressedJump = NO;
		
		if (jetpackActivated) {
			jetpackActivated = NO;
			[particle stopSystem];
		}
		
		b2Vec2 current = body->GetLinearVelocity();
		if (current.y > 0) {
			body->SetLinearVelocity(b2Vec2(current.x,0));
		}
	}
}

-(void) stop
{
	b2Vec2 vel = body->GetLinearVelocity();
	body->SetLinearVelocity(b2Vec2(horizontalSpeedOffset, vel.y));
	[self setState:STAND];
	moving = NO;
	direction = kDirectionNone;
}

-(void) crouch
{
	b2Vec2 vel = body->GetLinearVelocity();
	if (!dying && !immortal && !jetpackActivated && (fabsf(roundf(vel.y)) == 0)) {
		body->SetLinearVelocity(b2Vec2(0.0f, vel.y));
		[self setState:CROUCH];
		moving = NO;
		direction = kDirectionNone;
	}
}

-(void) prone
{		
	b2Vec2 vel = body->GetLinearVelocity();
	if (!dying && !immortal && !jetpackActivated && (fabsf(roundf(vel.y)) == 0)) {
		body->SetLinearVelocity(b2Vec2(0.0f, vel.y));
		[self setState:PRONE];
		moving = NO;
		direction = kDirectionNone;
	}
}

-(void) addJetpack
{
	if (jetpackCollected) {
		fuel += 2000;
		
	} else if (jetpackSpriteSheet != nil) {
		jetpack.visible = YES;
		particle.visible = YES;
		jetpackCollected = YES;
		fuel = 2000;
		[particle stopSystem];
		
		if (facingLeft) {
			jetpack.scaleX = -1;
			
		} else {
			jetpack.scaleX = 1;
		}
		
	} else {
		jetpackCollected = YES;
		fuel = 2000;
		
		jetpackSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"jetpack-sheet.png"];
		
		if (REDUCE_FACTOR != 1.0f) [jetpackSpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
		else [jetpackSpriteSheet.textureAtlas.texture setAliasTexParameters];
		
		[[GameLayer getInstance] addObject:jetpackSpriteSheet withZOrder:LAYER_PLAYER-1];
		
		
		float spriteWidth = jetpackSpriteSheet.texture.contentSize.width / 8;
		float spriteHeight = jetpackSpriteSheet.texture.contentSize.height / 2;
		
		jetpack = [CCSprite spriteWithBatchNode:jetpackSpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];
		[jetpack setAnchorPoint:ccp(0.41,0.33)];
		[jetpack retain];
		[jetpackSpriteSheet addChild:jetpack];
		
		// Jetpack animations
		standJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_stand"];
		if (standJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 0; x <= 0; x++) {
				CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			standJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:standJetpack name:@"jetpack_stand"];
		}
		
		walkJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_walk"];
		if (walkJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 1; x <= 6; x++) {
				CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			walkJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:walkJetpack name:@"jetpack_walk"];
		}
		
		crouchJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_crouch"];
		if (crouchJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 7; x <= 7; x++) {
				CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			crouchJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:crouchJetpack name:@"jetpack_crouch"];
		}
		
		proneJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_prone"];
		if (proneJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 0; x <= 0; x++) {
				CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			proneJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:proneJetpack name:@"jetpack_prone"];
		}
		
		jumpJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_jump"];
		if (jumpJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 1; x <= 2; x++) {
				CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			jumpJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:jumpJetpack name:@"jetpack_jump"];
		}
		
		if (facingLeft) {
			jetpack.scaleX = -1;
			
		} else {
			jetpack.scaleX = 1;
		}
		
		particle = [[[CCParticleSystemQuad alloc] initWithTotalParticles:10] autorelease];
		CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:@"smoke.png"];
		particle.texture=texture;
		particle.emissionRate=5.00;
		particle.angle=240.0;
		particle.angleVar=20.0;
		ccBlendFunc blendFunc={GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA};
		particle.blendFunc=blendFunc;
		particle.duration=-1.00;
		particle.emitterMode=kCCParticleModeGravity;
		ccColor4F startColor={1.00,1.00,1.00,1.00};
		particle.startColor=startColor;
		ccColor4F startColorVar={0.00,0.00,0.00,0.00};
		particle.startColorVar=startColorVar;
		ccColor4F endColor={1.00,1.00,1.00,0.00};
		particle.endColor=endColor;
		ccColor4F endColorVar={0.00,0.00,0.00,0.00};
		particle.endColorVar=endColorVar;
		particle.startSize=80.00/CC_CONTENT_SCALE_FACTOR();
		particle.startSizeVar=0.00;
		particle.endSize=50.00/CC_CONTENT_SCALE_FACTOR();
		particle.endSizeVar=0.00;
		particle.gravity=ccp(0.00,0.00);
		particle.radialAccel=0.00;
		particle.radialAccelVar=30.00;
		particle.speed=120;
		particle.speedVar=50;
		particle.tangentialAccel= 0;
		particle.tangentialAccelVar= 0;
		particle.totalParticles=10;
		particle.life=1.00;
		particle.lifeVar=0.10;
		particle.startSpin=0.00;
		particle.startSpinVar=0.00;
		particle.endSpin=0.00;
		particle.endSpinVar=0.00;
		particle.position=ccp(239.22,186.55);
		particle.posVar=ccp(5.00,0.00);
		
		if (facingLeft) particle.angle=280.0;
		else particle.angle=240.0;
		
		particle.autoRemoveOnFinish = NO;
		
		[[GameLayer getInstance] addObject:particle withZOrder:LAYER_PLAYER-1];
		[particle stopSystem];
	}
}

-(void) removeJetpack
{
	if (jetpackCollected) {
		[self resetJump];
		
		[jetpack stopAllActions];
		
		jetpackCollected = NO;
		jetpackActivated = NO;
		
		jetpack.visible = NO;
		particle.visible = NO;
		
		//[[GameLayer getInstance] removeObject:jetpackSpriteSheet];
		//[[GameLayer getInstance] removeObject:particle];
		
		fuel = 0;
	}
}

-(void) increaseHealth:(int)amount
{
	health += amount;
	if (health > 100) {
		health = 100;
	}
	[[GameLayer getInstance] setHealth:health];
}

-(void) decreaseHealth:(int)amount
{
	[self hit:-amount];
}

-(void) increaseLive:(int)amount
{
	lives++;
	[[GameLayer getInstance] setLives:lives];
}

-(void) decreaseLive:(int)amount
{
	if (lives < 1) [self die];
	else {
		lives--;
		[[GameLayer getInstance] setLives:lives];
	}
}

-(void) shoot
{
	if (!dying && !immortal) {
		
		if ((action == PRONE) || (action == CROUCH)) {
			//[self setState:STAND];
			return;
		}
		
		if (touchingSwitch != nil) {
			[touchingSwitch togle];
			[[GameLayer getInstance] activateSwitch:touchingSwitch.key];
			
		} else if ([[GameLayer getInstance] getAmmo] > 0) {
			
			[[GameLayer getInstance] reduceAmmo];
			
			CGPoint bulletOffset = ccp(0,0);
			
			if (facingLeft) bulletOffset = ccp(-50/CC_CONTENT_SCALE_FACTOR(), bulletOffsetY);
			else bulletOffset = ccp(50/CC_CONTENT_SCALE_FACTOR(), bulletOffsetY);
			
			GameObjectDirection bulletDirection;
			if (facingLeft) bulletDirection = kDirectionLeft;
			else bulletDirection = kDirectionRight;
			
			Bullet *bullet = [Bullet bullet:bulletDirection weapon:weaponID];
			bullet.damage = shootDamage;
			[bullet setPosition:ccpAdd(self.position,bulletOffset)];
			[bullet createBox2dObject:[GameLayer getInstance].world];
			//CCLOG(@"Player position: %f,%f", self.position.x, self.position.y);
		}
	}
}

-(void) immortal
{
	if (!immortal) {
		immortal = YES;
		
		[self stopAllActions];
		if (type == kGameObjectPlayer) {
			[weapon stopAllActions];
			if (jetpackCollected) [jetpack stopAllActions];
		}
		self.opacity = 0;
		
		id blinkAction = [CCSequence actions:
						  [CCFadeOut actionWithDuration:0.2],
						  [CCFadeIn actionWithDuration:0.2],
						  [CCFadeOut actionWithDuration:0.2],
						  [CCFadeIn actionWithDuration:0.2],
						  [CCCallFunc actionWithTarget:self selector:@selector(restore)],
						  nil];
		[self runAction:blinkAction];
		
		if (type == kGameObjectPlayer) {
			id weaponBlinkAction = [CCSequence actions:
									[CCFadeOut actionWithDuration:0.2],
									[CCFadeIn actionWithDuration:0.2],
									[CCFadeOut actionWithDuration:0.2],
									[CCFadeIn actionWithDuration:0.2],
									nil];
			[weapon runAction:weaponBlinkAction];
			
			if (jetpackCollected) {
				id jetpackBlinkAction = [CCSequence actions:
										 [CCFadeOut actionWithDuration:0.2],
										 [CCFadeIn actionWithDuration:0.2],
										 [CCFadeOut actionWithDuration:0.2],
										 [CCFadeIn actionWithDuration:0.2],
										 nil];
				[jetpack runAction:jetpackBlinkAction];
			}
		}
	}
}

-(void) restore
{
	self.opacity = 255;
	immortal = NO;
}

-(void) hit:(int)force 
{
	health -= force;
	if (health <= 0) health = 0;
	[[GameLayer getInstance] setHealth:health];
	
	if (health == 0) {
		[self die];
	}
}

-(void) die
{
	if (!dying && !immortal) {
		
		lives--;
		[[GameLayer getInstance] setLives:lives];
		
		if (lives <= 0) {
			// End game
			lose = YES;
			
		} else {
			health = 100;
			[[GameLayer getInstance] setHealth:0];
		}
		
		dying = YES;
		jumping = NO;
		jumpingMoving = NO;
		moving = NO;
		
		pressedJump = NO;
		if (jetpackCollected) {
			jetpackActivated = NO;
			[particle stopSystem];
		}
		
		body->SetLinearVelocity(b2Vec2(0.0f, 0.0f));
		
		[[GameLayer getInstance] pause];
		
		[self setState:STAND];
		
		id dieAction = [CCSequence actions:
						//[CCFadeOut actionWithDuration:1.0],
						[CCAnimate actionWithAnimation:die],
						[CCCallFunc actionWithTarget:self selector:@selector(resetPosition)],
						nil];
		[self runAction:dieAction];
		
		if (type == kGameObjectPlayer) {
			weapon.visible = NO;
			if (jetpackCollected) jetpack.visible = NO;
		}
	}
}

-(void) lose
{
	lives = 0;
	health = 0;
	[self die];
}

-(void) win
{
	win = YES;
}

-(void) resetPosition
{	
	if (lose || win) {
		// Restart player
		lives = 3;
		health = 100;
		
		[[GameLayer getInstance] setLives:lives];
		[[GameLayer getInstance] setHealth:health];
		
		initialX = originalX;
		initialY = originalY;
		
		if (win) {
			win = NO;
		}
		
		[self removeJetpack];
	}
	
	if (lose) {
		[[GameLayer getInstance] loseGame];
		lose = NO;
		self.visible = NO;
		direction = kDirectionNone;
		facingLeft = NO;
		[self changeWeapon:4]; // Default weapon
		
	} else {
		
		self.visible = YES;
		
		[[GameLayer getInstance] removeBullets];
		[[GameLayer getInstance] resetControls];
		
		float spriteWidth = self.batchNode.texture.contentSize.width / 8;
		float spriteHeight = self.batchNode.texture.contentSize.height / 2;
		
		CGPoint pos = ccp(initialX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - initialY - 1) * MAP_TILE_HEIGHT));
		pos.x += spriteWidth/2.0f;
		pos.y += spriteHeight/2.0f;
		
		self.position = pos;
		self.scaleX = 1;
		direction = kDirectionNone;
		facingLeft = NO;
		
		body->SetTransform(b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y + 0)/PTM_RATIO),0);
		
		self.opacity = 255;
		if (type == kGameObjectPlayer) {
			weapon.visible = YES;
			weapon.scaleX = 1;
			
			if (jetpackCollected) {
				jetpack.scaleX = 1;
				jetpack.visible = YES;
			}
		}
		
		dying = NO;
		
		[[GameLayer getInstance] resume];
		[[GameLayer getInstance] resetElements];
		
		[self immortal];
		
		[[GameLayer getInstance] setHealth:health];
	}
}

-(void) changePositionX:(int)dx andY:(int)dy
{	
	auxX = dx;
	auxY = dy;
	
	immortal = YES;
	
	[self stopAllActions];
	if (type == kGameObjectPlayer) {
		[weapon stopAllActions];
		if (jetpackCollected) [jetpack stopAllActions];
	}
	
	[[GameLayer getInstance] pause];
	
	id blinkAction = [CCSequence actions:
					  [CCFadeOut actionWithDuration:1.0],
					  [CCCallFunc actionWithTarget:self selector:@selector(_changePosition)],
					  nil];
	[self runAction:blinkAction];
	
	if (type == kGameObjectPlayer) {
		id weaponBlinkAction = [CCSequence actions:
								[CCFadeOut actionWithDuration:1.0],
								nil];
		[weapon runAction:weaponBlinkAction];
		
		if (jetpackCollected) {
			id jetpackBlinkAction = [CCSequence actions:
									 [CCFadeOut actionWithDuration:1.0],
									 nil];
			[jetpack runAction:jetpackBlinkAction];
		}
	}
}

-(void) changeInitialPositionX:(int)dx andY:(int)dy
{
	initialX = dx;
	initialY = dy;
}

-(void) _changePosition
{
	[self stop];
	
	float spriteWidth = self.batchNode.texture.contentSize.width / 11;
	float spriteHeight = self.batchNode.texture.contentSize.height;
	
	CGPoint pos = ccp(auxX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - auxY - 1) * MAP_TILE_HEIGHT));
	pos.x += spriteWidth/2.0f;
	pos.y += spriteHeight/2.0f;
	
	self.position = pos;
	
	body->SetTransform(b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y + 0)/PTM_RATIO),0);
	
	id blinkAction = [CCSequence actions:
					  [CCFadeIn actionWithDuration:1.0],
					  nil];
	
	[self runAction:blinkAction];
	
	if (type == kGameObjectPlayer) {
		id weaponBlinkAction = [CCSequence actions:
								[CCFadeIn actionWithDuration:1.0],
								nil];
		[weapon runAction:weaponBlinkAction];
		
		if (jetpackCollected) {
			id jetpackBlinkAction = [CCSequence actions:
									 [CCFadeIn actionWithDuration:1.0],
									 nil];
			[jetpack runAction:jetpackBlinkAction];
		}
	}
	
	[[GameLayer getInstance] resume];
	
	immortal = NO;
}

-(void) changeToPosition:(CGPoint)pos
{
	auxPos = pos;
	
	id change = [CCSequence actions:
				 [CCDelayTime actionWithDuration:1.0/60.0],
				 [CCCallFunc actionWithTarget:self selector:@selector(_changeToPosition)],
				 nil];
	[self runAction:change];
}

-(void) _changeToPosition
{
	self.position = auxPos;
	
	body->SetTransform(b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y + 0)/PTM_RATIO),0);
}

-(void) hitsFloor
{
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"Player.hitsFloor, jumping:%i, moving:%i, jumpingMoving:%i, vel:%f,%f", jumping, moving, jumpingMoving, current.x, current.y);
	
	canJump = YES;
	helpFall = YES;
	
	//if (fabsf(roundf(current.y)) != 0) {	
		//if (jumping) {
		
		//CCLOG(@"Player.hitsFloor, jumping:%i, moving:%i, jumpingMoving:%i, vel:%f,%f", jumping, moving, jumpingMoving, current.x, current.y);
		
		jumping = NO;
		jumpingMoving = NO;
		
		if (!moving) {
			
			if (current.x != 0) {
				//CCLOG(@"Reset X linear velocity");
				body->SetLinearVelocity(b2Vec2(0.0f, current.y));
			}
			
			if ((action != PRONE) && (action != CROUCH)) [self setState:STAND];
			
		} else {
			[self setState:WALK];
		}
	//}
}

-(void) displaceHorizontally:(float)speed 
{
	if (speed != horizontalSpeedOffset) {
		b2Vec2 current = body->GetLinearVelocity();
		
		if (moving) {
			if (direction == kDirectionLeft) body->SetLinearVelocity(b2Vec2(-HORIZONTAL_SPEED + speed, current.y));
			else if (direction == kDirectionRight) body->SetLinearVelocity(b2Vec2(HORIZONTAL_SPEED + speed, current.y));
			else body->SetLinearVelocity(b2Vec2(speed, current.y));
			
		} else {
			body->SetLinearVelocity(b2Vec2(speed, current.y));
		}
		
		horizontalSpeedOffset = speed;
	}
}

-(void) setTouchingSwitch:(Switch *) touchingSwitch_ {
	touchingSwitch = touchingSwitch_;
}

-(void) resetForces
{
	body->SetLinearVelocity(b2Vec2(0,0));
	body->SetAngularVelocity(0);
}

-(void) resume 
{
	[self resumeSchedulerAndActions];
}

-(void) pause 
{
	[self pauseSchedulerAndActions];
}


-(void) update:(ccTime)dt
{
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"%f, %i", current.y, action);
	
	if (ignoreGravity) body->SetGravityScale(0.0f);
	else body->SetGravityScale(1.0f);
	
	if ((fabsf(roundf(current.y)) == 0) || ignoreGravity) {
		//CCLOG(@"%f, %i, %i", current.y, action, jumping);
		if ((fabsf(roundf(current.x)) == 0) && (action != PRONE) && (action != CROUCH) && (!jumping)) {
			[self setState:STAND];
		}
		
	} else {
		//CCLOG(@"%f", current.y);
		if ((current.y > 0) && jumping) {
			if (!ignoreGravity) [self setState:JUMPING];
			
		} else {
			if (!ignoreGravity) [self setState:FALLING];
			
			if ((pressedJump && jetpackCollected && !jetpackActivated)
				&& (self.position.y + self.size.height*(1.0f-self.anchorPoint.y) < ([GameLayer getInstance].mapHeight * MAP_TILE_HEIGHT))) 
			{
				jetpackActivated = YES;
				[particle resetSystem];
				
				b2Vec2 impulse = b2Vec2(0.0f, fabs(current.y) + JETPACK_IMPULSE);
				body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
				
			} else if (helpFall && !jumping) {
				// Give little impluse down so we can fall in one tile gaps
				
				//CCLOG(@"Help fall %f", current.y);
				
				//body->ApplyLinearImpulse(b2Vec2(0.0f, -5.0f), body->GetWorldCenter());
				body->ApplyForce(b2Vec2(0.0f, -250.0f),body->GetWorldCenter());

				helpFall = NO;
			}
		}
	}
	
	if (jetpackCollected && jetpackActivated) {
		//CCLOG(@"%f", self.position.y);
		if (self.position.y + self.size.height*(1.0f-self.anchorPoint.y) < ([GameLayer getInstance].mapHeight * MAP_TILE_HEIGHT)) {
			b2Vec2 impulse = b2Vec2(0.0f, JETPACK_SPEED);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
		} else {
			body->SetLinearVelocity(b2Vec2(current.x,0));
		}
		
		fuel -= 5;
		
		if (fuel <= 0) {
			[self removeJetpack];
		}
	}
	
	[super update:dt];
}

- (void)setPosition:(CGPoint)point
{
	if (type == kGameObjectPlayer) {
		if (action == PRONE) {
			CGSize winSize = [[CCDirector sharedDirector] winSize];
			CGPoint localPoint = [[GameLayer getInstance] convertToMapCoordinates:point];
			
			if (scrollOnProne == 0) {
				scrollOnProneMax = (winSize.height - localPoint.y);
			}
			
			scrollOnProne += 4;
			if (scrollOnProne > scrollOnProneMax) scrollOnProne = scrollOnProneMax;
			
			[[GameLayer getInstance] setViewpointCenter:ccp(point.x,point.y - scrollOnProne/CC_CONTENT_SCALE_FACTOR())];
			
		} else if (scrollOnProne > 0) {
			scrollOnProne -= 4;
			if (scrollOnProne < 0) scrollOnProne = 0;
			
			[[GameLayer getInstance] setViewpointCenter:ccp(point.x,point.y - scrollOnProne/CC_CONTENT_SCALE_FACTOR())];
			
		} else {
			[[GameLayer getInstance] setViewpointCenter:ccp(point.x,point.y)];
		}
		[weapon setPosition:point];
		
		if (jetpackCollected) {
			[jetpack setPosition:point];
			if (facingLeft) [particle setPosition:ccp(point.x + 40.0f/CC_CONTENT_SCALE_FACTOR(), point.y - 40.0f/CC_CONTENT_SCALE_FACTOR())];
			else [particle setPosition:ccp(point.x - 40.0f/CC_CONTENT_SCALE_FACTOR(), point.y - 40.0f/CC_CONTENT_SCALE_FACTOR())];
		}
	}
	[super setPosition:point];
}

- (void) dealloc
{
	if (type == kGameObjectPlayer) {
		[weapon release];
		if (jetpackCollected) [jetpack release];
	}
	
	[super dealloc];
}

@end
