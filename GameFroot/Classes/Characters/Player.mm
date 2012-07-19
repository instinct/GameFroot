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
#import "Robot.h"
#import "MovingPlatform.h"
//#import "GB2ShapeCache.h"

static float const ANIMATION_OFFSET_X[11] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f, -20.0f,0.0f,0.0f};
static float const ANIMATION_OFFSET_Y[11] = {0.0f,-2.0f,-1.0f,0.0f,-2.0f,-1.0f,0.0f,-10.0f , -25.0f,0.0f,-2.0f};

@implementation Player

@synthesize action;
@synthesize ignoreGravity;
@synthesize shootDelay;
@synthesize shootDamage;
@synthesize autoSafepoint;
@synthesize health;
@synthesize initialHealth;
@synthesize topHealth;
@synthesize immune;
@synthesize fixedXSpeed;
@synthesize fixedYSpeed;

-(void) setupPlayer:(int)_playerID properties:(NSDictionary *)properties
{
    //CCLOG(@"Player.setupPlayer: %@", properties);
    
	playerID = _playerID;
    
	type = kGameObjectPlayer;
	moving = NO;
	direction = kDirectionNone;
	facingLeft = NO;
	jetpackCollected = NO;
	jetpackActivated = NO;
	lose = NO;
	win = NO;
	scrollOnProne = 0;
	hasWeapon = NO;
    safePositon = self.position;
    interact = nil;
    immune = NO;
    fixedXSpeed = 0;
    fixedYSpeed = 0;
    particle = nil;
    smokeOn = NO;
    
    initialX = originalX = [[properties objectForKey:@"positionX"] intValue];
	initialY = originalY = [[properties objectForKey:@"positionY"] intValue];
	lives = initialLives = [[properties objectForKey:@"lives"] intValue];
	health = initialHealth = [[properties objectForKey:@"health"] intValue];
    topHealth = health;
    
    defaultWeapon = [[properties objectForKey:@"weapon"] intValue];
    startsWithWeapon = [[properties objectForKey:@"hasWeapon"] boolValue];
    startsWithJetpack = [[properties objectForKey:@"hasJetpack"] intValue] == 1;
    
    horizontalSpeed = ([[properties objectForKey:@"speed"] floatValue] * 70.0f) / (PTM_RATIO*CC_CONTENT_SCALE_FACTOR());
    //CCLOG(@">>>>>>> player horizontal seed: %f", horizontalSpeed);
    
    [[GameLayer getInstance] setLives:lives];
    
	float spriteWidth = self.batchNode.texture.contentSize.width / 8;
	float spriteHeight = self.batchNode.texture.contentSize.height / 2;
	
	if (startsWithWeapon) [self changeWeapon:defaultWeapon];
    
    if (startsWithJetpack) [self addJetpack];
    
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
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	debugImmortal = [prefs integerForKey:@"immortal"];
}

-(void) removeWeapon
{
    if (weaponSpriteSheet != nil) {
		[[GameLayer getInstance] removeObject:weaponSpriteSheet];
	}
    
    hasWeapon = NO;
    [[GameLayer getInstance] disableAmmo];
}

-(void) changeWeapon:(int)_weaponID
{
	//CCLOG(@"Player.changeWeapon: %i", _weaponID);

	[self removeWeapon];
    
    hasWeapon = YES;
    [[GameLayer getInstance] enableAmmo];
    
	weaponID = _weaponID;
	
	switch (weaponID) {
		case 0: // Pistol
			
			shootDamage = 25;
			shootDelay= 0.5f;
			bulletOffsetY = (-2-7)/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 1: // Auto shotgun
			
			shootDamage = 25;
			shootDelay = 0.2f;
			bulletOffsetY = (-5-7)/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 2: // Laser
			
			shootDamage = 50;
			shootDelay = 0.1f;
			bulletOffsetY = (-5-9)/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 3: // Musket
			
			shootDamage = 150;
			shootDelay = 1.0f;
			bulletOffsetY = (0-9)/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 4: // AK 47
			
			shootDamage = 70;
			shootDelay = 0.05f;
			bulletOffsetY = (-5-9)/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 5: // M60
			
			shootDamage = 120;
			shootDelay = 0.05f;
			bulletOffsetY = (-5-9)/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 6: // Rocket Launcher
			
			shootDamage = 400;
			shootDelay = 1.2f;
			bulletOffsetY = (5-7)/CC_CONTENT_SCALE_FACTOR();
			
			break;
	}
	
	//weaponSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"weapon_%i.png",weaponID]];
    weaponSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"weapon_%i_single.png",weaponID]];
	
	if (REDUCE_FACTOR != 1.0f) [weaponSpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
	else [weaponSpriteSheet.textureAtlas.texture setAliasTexParameters];
	
	[[GameLayer getInstance] addObject:weaponSpriteSheet];
	
	//float spriteWidth = weaponSpriteSheet.texture.contentSize.width / 8;
	//float spriteHeight = weaponSpriteSheet.texture.contentSize.height / 2;
    float spriteWidth = weaponSpriteSheet.texture.contentSize.width;
	float spriteHeight = weaponSpriteSheet.texture.contentSize.height;
	
	weapon = [CCSprite spriteWithBatchNode:weaponSpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];
	[weapon setAnchorPoint:ccp(PLAYER_ANCHOR_X,PLAYER_ANCHOR_Y)];
	[weapon retain];
	[weaponSpriteSheet addChild:weapon];
	
	// Weapon animations
	standWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_stand_%i",weaponID]];
	if (standWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		standWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:standWeapon name:[NSString stringWithFormat:@"weapon_stand_%i",weaponID]];
	}
	
	walkWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_walk_%i",weaponID]];
	if (walkWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 6; x++) {
			//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		walkWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:walkWeapon name:[NSString stringWithFormat:@"weapon_walk_%i",weaponID]];
	}
	
	crouchWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_crouch_%i",weaponID]];
	if (crouchWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 7; x <= 7; x++) {
			//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		crouchWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:crouchWeapon name:[NSString stringWithFormat:@"weapon_crouch_%i",weaponID]];
	}
	
	proneWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_prone_%i",weaponID]];
	if (proneWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[8+x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[8+x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];            
            [frames addObject:frame];
		}
		proneWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:proneWeapon name:[NSString stringWithFormat:@"weapon_prone_%i",weaponID]];
	}
	
	jumpWeapon = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"weapon_jump_%i",weaponID]];
	if (jumpWeapon == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 2; x++) {
			//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:weaponSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[8+x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[8+x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		jumpWeapon = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:jumpWeapon name:[NSString stringWithFormat:@"weapon_jump_%i",weaponID]];
	}
	
	if (facingLeft) {
		weapon.scaleX = -1;
	}
    
    if (immortal) {
        id weaponBlinkAction = [CCSequence actions:
                                [CCFadeOut actionWithDuration:0.2],
                                [CCFadeIn actionWithDuration:0.2],
                                [CCFadeOut actionWithDuration:0.2],
                                [CCFadeIn actionWithDuration:0.2],
                                nil];
        [weapon runAction:weaponBlinkAction];
    }
}

-(void) setState:(int) anim
{
	if (action == anim)	return;
	
	//CCLOG(@"Player.setState: %i", anim);
	
	if (!immortal) {
		[self stopAllActions];
		if (hasWeapon) {
            [weapon stopAllActions];
            weapon.opacity = 255;
            weapon.visible = YES;
        }
        
		if (jetpackCollected) {
            [jetpack stopAllActions];
        }
		
		self.opacity = 255;
		
		
		
		if (jetpackCollected) {
			jetpack.opacity = 255;
			jetpack.visible = YES;
		}
	}
	
	action = anim;
	
	if (anim == STAND)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"stand_%i",playerID] index:0];
		if (hasWeapon) [weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_stand_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_stand" index:0];
	}
	else if (anim == WALK)
	{
		[self runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walk]]];
		if (hasWeapon) [weapon runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walkWeapon]]];
		if (jetpackCollected) [jetpack runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walkJetpack]]];
	}
	else if (anim == CROUCH)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"crouch_%i",playerID] index:0];
		if (hasWeapon) [weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_crouch_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_crouch" index:0];
	}
	else if (anim == PRONE)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"prone_%i",playerID] index:0];
		if (hasWeapon) [weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_prone_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_prone" index:0];
	}
	else if (anim == JUMPING)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"jump_%i",playerID] index:0];
		if (hasWeapon) [weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_jump_%i",weaponID] index:0];
		if (jetpackCollected) [jetpack setDisplayFrameWithAnimationName:@"jetpack_jump" index:0];
	}
	else if (anim == FALLING)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"jump_%i",playerID] index:1];
		if (hasWeapon) [weapon setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"weapon_jump_%i",weaponID] index:1];
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
	playerBodyDef.position = b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO);
	playerBodyDef.userData = self;
	body = world->CreateBody(&playerBodyDef);
	
	//[[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"player"];
	
    b2PolygonShape shape;
    shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 1.0;
    fixtureDef.friction = 0.0; // we need this 0 so when moving it doens't slow down
    fixtureDef.restitution = 0.0; // bouncing
    body->CreateFixture(&fixtureDef);
}

-(void) moveRight
{
	if (!dying && !immortal) {
		
		b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(horizontalSpeed + horizontalSpeedOffset, current.y);
		body->SetLinearVelocity(velocity);
		
		self.scaleX = 1;
		
		if (type == kGameObjectPlayer) {
			if (hasWeapon) weapon.scaleX = 1;
            
			if (jetpackCollected) {
				jetpack.scaleX = 1;
			}
            
            if (jetpackCollected || smokeOn) {
				particle.angle = 240.0;
			}
		}
		
		if (!jumping && (!jetpackCollected || !jetpackActivated)) [self setState:WALK];
		
		moving = YES;
		direction = kDirectionRight;
		facingLeft = NO;
        
        inertia = 0;
        body->SetLinearDamping(0.0f);
	}
}

-(void) moveLeft
{
	if (!dying && !immortal) {
		
		b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(-horizontalSpeed + horizontalSpeedOffset, current.y);
		body->SetLinearVelocity(velocity);
		
		self.scaleX = -1;
		
		if (type == kGameObjectPlayer) {
			if (hasWeapon) weapon.scaleX = -1;
            
			if (jetpackCollected) {
				jetpack.scaleX = -1;
			}
            
            if (jetpackCollected || smokeOn) {
				particle.angle = 280.0;
			}
		}
		
		if (!jumping && (!jetpackCollected || !jetpackActivated)) [self setState:WALK];
		
		moving = YES;
		direction = kDirectionLeft;
		facingLeft = YES;
        
        inertia = 0;
        body->SetLinearDamping(0.0f);
	}
}

-(BOOL) isMoonWalking {
    if ( dying || immortal || jumping || (action == PRONE) || (action == CROUCH)) return ( NO );
    if (inertia != 0) return ( NO );
    
    b2Vec2 vel = body->GetLinearVelocity( );

    if (fabsf(roundf(vel.y)) != 0) return( NO );
    
    if ( ( vel.x < -0.01 ) && (horizontalSpeedOffset == 0) && ( !facingLeft || ( action == STAND ) ) ) return( YES );
    else if ( ( vel.x > 0 ) && (horizontalSpeedOffset == 0) && ( facingLeft || ( action == STAND  ) ) ) return( YES );
    
    return( NO );    
}

-(BOOL) isJumping {
    return jumping;
}

-(void) restartMovement {
    b2Vec2 current = body->GetLinearVelocity();
	if (!dying && !immortal && (moving || jumpingMoving)) {
		if (fabsf(roundf(current.x)) == 0) {
			
			if (direction == kDirectionLeft) {
				b2Vec2 velocity = b2Vec2(-horizontalSpeed + horizontalSpeedOffset, current.y);
				body->SetLinearVelocity(velocity);
				
			} else if (direction == kDirectionRight) {
				b2Vec2 velocity = b2Vec2(horizontalSpeed + horizontalSpeedOffset, current.y);
				body->SetLinearVelocity(velocity);
			}
        }
        
	//} else if (!jumping && !moving && !jumpingMoving && (fabsf(roundf(current.y)) == 0)){
    //    [self resetForces];
    }
}

-(void) jump
{	
    if ((action == PRONE) || (action == CROUCH)) {
        return;
    }
    
	pressedJump = YES;
    
    inertia = 0;
    body->SetLinearDamping(0.0f);
	
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"Player.jump: %i, %i, %i, %f, %i", canJump, dying, immortal, fabsf(roundf(current.y)), ignoreGravity);
	if (canJump && !dying && !immortal && ((fabsf(roundf(current.y)) == 0) || ignoreGravity)) {
		canJump = NO;
		jumping = YES;
		b2Vec2 impulse = b2Vec2(0.0f, VERTICAL_SPEED);
		body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
		
        [self setState:JUMPING];
        ignoreGravity = NO;
        
	} else if (jetpackCollected && !jetpackActivated && !dying && !immortal) {
		//b2Vec2 impulse = b2Vec2(0.0f, fabs(current.y) + JETPACK_SPEED);
		//body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
		
		jetpackActivated = YES;
        jetpackSoundHandle = [[SimpleAudioEngine sharedEngine] playEffect:@"IG Jetpack.caf" loop:YES];
		[particle resetSystem];
		
		b2Vec2 impulse = b2Vec2(0.0f, fabs(current.y) + JETPACK_IMPULSE);
		body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
        
        [self setState:JUMPING];
        ignoreGravity = NO;
	}
}

-(void) jumpDirection:(GameObjectDirection)dir
{
    if ((action == PRONE) || (action == CROUCH)) {
        return;
    }
    
	pressedJump = YES;
    
    inertia = 0;
    body->SetLinearDamping(0.0f);
	
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"Player.jumDirection: %i, %i, %f, %i", dir, canJump, fabsf(roundf(current.y)), ignoreGravity);
	if (canJump && !dying && !immortal) { // && ((fabsf(roundf(current.y)) == 0) || ignoreGravity)) {
		
		canJump = NO;
		jumping = YES;
		jumpingMoving = YES;
		b2Vec2 impulse;
		
		if (dir == kDirectionLeft) {
			impulse = b2Vec2(-horizontalSpeed, VERTICAL_SPEED);
			
			self.scaleX = -1;
			direction = kDirectionLeft;
			facingLeft = YES;
			
			if (type == kGameObjectPlayer) {
				if (hasWeapon) weapon.scaleX = -1;
                
				if (jetpackCollected) {
					jetpack.scaleX = -1;
					particle.angle=280.0;
				}
			}
			
		} else {
			impulse = b2Vec2(horizontalSpeed, VERTICAL_SPEED);
			
			self.scaleX = 1;
			direction = kDirectionRight;
			facingLeft = NO;
			
			if (type == kGameObjectPlayer) {
				if (hasWeapon) weapon.scaleX = 1;
                
				if (jetpackCollected) {
					jetpack.scaleX = 1;
					particle.angle=240.0;
				}
			}
		}
		
		[self resetForces];
		body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
        
        [self setState:JUMPING];
        ignoreGravity = NO;
		
	} else if (jetpackCollected && !jetpackActivated && !dying && !immortal) {
		
		jetpackActivated = YES;
        jetpackSoundHandle = [[SimpleAudioEngine sharedEngine] playEffect:@"IG Jetpack.caf" loop:YES];
		[particle resetSystem];
		
		if (dir == kDirectionLeft) {
            [self resetHorizontalSpeed];
			b2Vec2 impulse = b2Vec2(-horizontalSpeed, fabs(current.y) + JETPACK_IMPULSE);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = -1;
			direction = kDirectionLeft;
			facingLeft = YES;
			
			if (type == kGameObjectPlayer) {
				if (hasWeapon) weapon.scaleX = -1;
                
				if (jetpackCollected) {
					jetpack.scaleX = -1;
					particle.angle=280.0;
				}
			}
			
		} else {
			[self resetHorizontalSpeed];
			b2Vec2 impulse = b2Vec2(horizontalSpeed, fabs(current.y) + JETPACK_IMPULSE);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = 1;
			direction = kDirectionRight;
			facingLeft = NO;
			
			if (type == kGameObjectPlayer) {
				if (hasWeapon) weapon.scaleX = 1;
                
				if (jetpackCollected) {
					jetpack.scaleX = 1;
					particle.angle=240.0;
				}
			}
		}
        
        [self setState:JUMPING];
        ignoreGravity = NO;
		
	} else if (jumping && !dying && !immortal) {
		//CCLOG(@"Player.jumDirection: change direction in the air");
		if (dir == kDirectionLeft) {
			[self resetHorizontalSpeed];
			b2Vec2 impulse = b2Vec2(-horizontalSpeed, 0.0f);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = -1;
			direction = kDirectionLeft;
			facingLeft = YES;
			
			if (type == kGameObjectPlayer) {
				if (hasWeapon) weapon.scaleX = -1;
                
				if (jetpackCollected) {
					jetpack.scaleX = -1;
					particle.angle=280.0;
				}
			}
			
		} else {
			[self resetHorizontalSpeed];
			b2Vec2 impulse = b2Vec2(horizontalSpeed, 0.0f);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
			self.scaleX = 1;
			direction = kDirectionRight;
			facingLeft = NO;
			
			if (type == kGameObjectPlayer) {
				if (hasWeapon) weapon.scaleX = 1;
                
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
            [[SimpleAudioEngine sharedEngine] stopEffectWithHandle:jetpackSoundHandle];
			[particle stopSystem];
		}
		
		b2Vec2 current = body->GetLinearVelocity();
		if (current.y > 0) {
            // Delay jump rest to avoid reseting too early (before player actually moves)
            // since this will make the player to not register hitFloor event.
            
            [self scheduleOnce:@selector(resetVerticalSpeed) delay:1.0/60.0f];
		}
	}
}

-(void) resetVerticalSpeed
{
    b2Vec2 current = body->GetLinearVelocity();
    body->SetLinearVelocity(b2Vec2(current.x,0));
}

-(void) resetHorizontalSpeed
{
    b2Vec2 current = body->GetLinearVelocity();
    body->SetLinearVelocity(b2Vec2(0,current.y));
}

-(void) stop
{
    if (!dying) {
        b2Vec2 vel = body->GetLinearVelocity();
        body->SetLinearVelocity(b2Vec2(horizontalSpeedOffset, vel.y));
        if (!jetpackActivated && !jumping) [self setState:STAND];
        moving = NO;
        direction = kDirectionNone;
        
        // Apply some inertia
        if (fabsf(roundf(vel.y)) == 0)
        {
            inertia = vel.x/0.5f;
            b2Vec2 impulse = b2Vec2(inertia, vel.y);
            body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
            body->SetLinearDamping(20.0f);
        }
    }
}

-(void) crouch
{
	b2Vec2 vel = body->GetLinearVelocity();
	if (!dying && !immortal && !jetpackActivated && (fabsf(roundf(vel.x)) == 0) && (fabsf(roundf(vel.y)) == 0)) {
		[self resetHorizontalSpeed];
		[self setState:CROUCH];
		moving = NO;
		direction = kDirectionNone;
	}
}

-(void) prone
{		
	b2Vec2 vel = body->GetLinearVelocity();
	if (!dying && !immortal && !jetpackActivated && (fabsf(roundf(vel.x)) == 0) && (fabsf(roundf(vel.y)) == 0)) {
		[self resetHorizontalSpeed];
		[self setState:PRONE];
		moving = NO;
		direction = kDirectionNone;
	}
}

-(void) createSmoke
{
    if (particle == nil) {
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
    }
}

-(void) displaySmoke
{
    smokeOn = YES;
    [self createSmoke];
    
    if (!jetpackCollected || !jetpackActivated) {
        [particle resetSystem];
    }
}

-(void) removeSmoke
{
    smokeOn = NO;
    [particle stopSystem];
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
		
		//jetpackSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"jetpack-sheet.png"];
        jetpackSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"jetpack-single.png"];
		
		if (REDUCE_FACTOR != 1.0f) [jetpackSpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
		else [jetpackSpriteSheet.textureAtlas.texture setAliasTexParameters];
		
		[[GameLayer getInstance] addObject:jetpackSpriteSheet withZOrder:LAYER_PLAYER-1];
		
		//float spriteWidth = jetpackSpriteSheet.texture.contentSize.width / 8;
		//float spriteHeight = jetpackSpriteSheet.texture.contentSize.height / 2;
        float spriteWidth = jetpackSpriteSheet.texture.contentSize.width/2;
		float spriteHeight = jetpackSpriteSheet.texture.contentSize.height;
		
		jetpack = [CCSprite spriteWithBatchNode:jetpackSpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];
		[jetpack setAnchorPoint:ccp(PLAYER_ANCHOR_X,PLAYER_ANCHOR_Y)];
		[jetpack retain];
		[jetpackSpriteSheet addChild:jetpack];
		
		// Jetpack animations
		standJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_stand"];
		if (standJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 0; x <= 0; x++) {
				//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			standJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:standJetpack name:@"jetpack_stand"];
		}
		
		walkJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_walk"];
		if (walkJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 1; x <= 6; x++) {
				//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			walkJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:walkJetpack name:@"jetpack_walk"];
		}
		
		crouchJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_crouch"];
		if (crouchJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 7; x <= 7; x++) {
				//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			crouchJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:crouchJetpack name:@"jetpack_crouch"];
		}
		
		proneJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_prone"];
		if (proneJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 0; x <= 0; x++) {
				//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(spriteWidth,0,spriteWidth,spriteHeight)];
				[frames addObject:frame];
			}
			proneJetpack = [CCAnimation animationWithFrames:frames delay:0.125f];
			[[CCAnimationCache sharedAnimationCache] addAnimation:proneJetpack name:@"jetpack_prone"];
		}
		
		jumpJetpack = [[CCAnimationCache sharedAnimationCache] animationByName:@"jetpack_jump"];
		if (jumpJetpack == nil) {
			NSMutableArray *frames = [NSMutableArray array];
			for(int x = 1; x <= 2; x++) {
				//CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:jetpackSpriteSheet.texture rect:CGRectMake(ANIMATION_OFFSET_X[8+x] / CC_CONTENT_SCALE_FACTOR(),ANIMATION_OFFSET_Y[8+x] / CC_CONTENT_SCALE_FACTOR(),spriteWidth,spriteHeight)];
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
		
        [self createSmoke];        
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
		[[SimpleAudioEngine sharedEngine] stopEffectWithHandle:jetpackSoundHandle];
		jetpack.visible = NO;
		
        if (!smokeOn) {
            particle.visible = NO;
            [particle stopSystem];
        }
		
		//[[GameLayer getInstance] removeObject:jetpackSpriteSheet];
		//[[GameLayer getInstance] removeObject:particle];
		
		fuel = 0;
	}
}

-(void) increaseHealth:(int)amount
{
	health += amount;
	if (health > topHealth) {
		health = topHealth;
	}
	[[GameLayer getInstance] setHealth:health];
}

-(void) decreaseHealth:(int)amount
{
	[self hit:-amount];
}

-(void) setMaxHealth:(int)amount
{
    topHealth = amount;
    [[GameLayer getInstance] setHealth:health];
}

-(void) increaseLive:(int)amount
{
	lives += amount;
	[[GameLayer getInstance] setLives:lives];
}

-(void) decreaseLive:(int)amount
{
	if (lives < amount) [self die];
	else {
		lives -= amount;
		[[GameLayer getInstance] setLives:lives];
	}
}

-(void) shoot
{
	if (!dying && !immortal) {
		
		if ((action == PRONE) || (action == CROUCH)) {
			return;
		}
		
		if (touchingSwitch != nil) {
            // Ignore shoot
			[touchingSwitch togle];
			[[GameLayer getInstance] activateSwitch:touchingSwitch.key];
		
        } else if ((interact != nil) && [interact interacted]) {
            // Ignore shoot
            
		} else if (hasWeapon && ([[GameLayer getInstance] getAmmo] > 0)) {
			
            switch (weaponID) {
                case 0: // Pistol
                     [[SimpleAudioEngine sharedEngine] playEffect:@"W Pistol.caf"];
                    break;
                    
                case 1: // Auto shotgun
                    [[SimpleAudioEngine sharedEngine] playEffect:@"W Shotgun.caf"];
                    break;
                    
                case 2: // Laser
                    [[SimpleAudioEngine sharedEngine] playEffect:@"W Lasergun.caf"];                                  
                    break;
                    
                case 3: // Musket
                    [[SimpleAudioEngine sharedEngine] playEffect:@"W Shotgun.caf"];
                    break;
                    
                case 4: // AK 47
                    [[SimpleAudioEngine sharedEngine] playEffect:@"W Machine Gun single shot.caf"];
                    break;
                    
                case 5: // M60
                    [[SimpleAudioEngine sharedEngine] playEffect:@"W Machine gun.caf"];
                    break;
                    
                case 6: // Rocket Launcher
                    [[SimpleAudioEngine sharedEngine] playEffect:@"W Rocket launcher launch.caf"];
                    break;
            }

            
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
            
            if (weaponID == 1) {
                Bullet *bullet1 = [Bullet bullet:bulletDirection weapon:weaponID];
                bullet1.damage = shootDamage;
                [bullet1 setPosition:ccpAdd(self.position,bulletOffset)];
                [bullet1 createBox2dObject:[GameLayer getInstance].world];
                [bullet1 setAngle:1.0f];
                
                Bullet *bullet2 = [Bullet bullet:bulletDirection weapon:weaponID];
                bullet2.damage = shootDamage;
                [bullet2 setPosition:ccpAdd(self.position,bulletOffset)];
                [bullet2 createBox2dObject:[GameLayer getInstance].world];
                [bullet2 setAngle:-1.0f];
            }
		}
	}
}

-(void) immortal
{
	if (!immortal) {
		immortal = YES;
		
		[self stopAllActions];
		if (type == kGameObjectPlayer) {
			if (hasWeapon) [weapon stopAllActions];
			if (jetpackCollected) {
                [jetpack stopAllActions];
            }
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
            
            if (hasWeapon) {
                id weaponBlinkAction = [CCSequence actions:
                                        [CCFadeOut actionWithDuration:0.2],
                                        [CCFadeIn actionWithDuration:0.2],
                                        [CCFadeOut actionWithDuration:0.2],
                                        [CCFadeIn actionWithDuration:0.2],
                                        nil];
                [weapon runAction:weaponBlinkAction];
			}
            
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
    if (debugImmortal) return;
    
    if (immune) return;
    
    health -= force;
	if (health <= 0) health = 0;
	[[GameLayer getInstance] setHealth:health];
	
	if (health == 0) {
		[self die];
	}
}

-(void) die
{
    if (debugImmortal) return;
    
    if (immune) return;
    
	if (!dying && !immortal) {
		
        [[SimpleAudioEngine sharedEngine] playEffect:@"IG Death.caf" pitch:1.0f pan:0.0f gain:1.0f];
        
		lives--;
		[[GameLayer getInstance] setLives:lives];
		
		if (lives <= 0) {
			// End game
			lose = YES;
			
		} else {
			health = topHealth;
			[[GameLayer getInstance] setHealth:0];
		}
		
		dying = YES;
		jumping = NO;
		jumpingMoving = NO;
		moving = NO;
		
		pressedJump = NO;
		if (jetpackCollected) {
			jetpackActivated = NO;
            [[SimpleAudioEngine sharedEngine] stopEffectWithHandle:jetpackSoundHandle];
			[particle stopSystem];
		}
		
		[self resetForces];
		
		[[GameLayer getInstance] pause];
		
		[self setState:STAND];
		
		id dieAction = [CCSequence actions:
						//[CCFadeOut actionWithDuration:1.0],
						[CCAnimate actionWithAnimation:die],
						[CCCallFunc actionWithTarget:self selector:@selector(resetPosition)],
						nil];
		[self runAction:dieAction];
		
		if (type == kGameObjectPlayer) {
			if (hasWeapon) weapon.visible = NO;
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
	if (lose) {
		[[GameLayer getInstance] loseGame];
		lose = NO;
		self.visible = NO;
		direction = kDirectionNone;
		facingLeft = NO;
        
	} else {
        
        if (win) win = NO;
     
		self.visible = YES;
		
		[[GameLayer getInstance] resetControls];
        
        // Auto safe position
        CGPoint pos;
        if (autoSafepoint && (!CGPointEqualToPoint(safePositon, CGPointZero))) pos = safePositon;
        else {
            CGSize hitArea = CGSizeMake(PLAYER_WIDTH / CC_CONTENT_SCALE_FACTOR(), PLAYER_HEIGHT / CC_CONTENT_SCALE_FACTOR());
            pos = ccp(initialX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - initialY - 1) * MAP_TILE_HEIGHT));
            pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f;
            pos.y += hitArea.height/2.0f;
		}
        //

		self.position = pos;
		self.scaleX = 1;
		direction = kDirectionNone;
		facingLeft = NO;
		
        // Need to run inmediatly (box2d locked safe)
		body->SetTransform(b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO),0);
		
		self.opacity = 255;
		if (type == kGameObjectPlayer) {
			
            if (hasWeapon) {
                weapon.visible = YES;
                weapon.scaleX = 1;
			}
            
			if (jetpackCollected) {
				jetpack.scaleX = 1;
				jetpack.visible = YES;
			}
		}
		
		dying = NO;
		
		[[GameLayer getInstance] resume];
        [[GameLayer getInstance] resetScheduledElements];
		
		[self immortal];
		
		[[GameLayer getInstance] setHealth:health];
	}
}

-(void) restart
{
    safePositon = CGPointZero;
    
    if (startsWithJetpack) [self addJetpack];
    else [self removeJetpack];
    
    if (startsWithWeapon) [self changeWeapon:defaultWeapon];
    else [self removeWeapon];
    
    lives = initialLives;
	health = initialHealth;
    
    [[GameLayer getInstance] setLives:lives];
    [[GameLayer getInstance] setHealth:health];
    
    initialX = originalX;
    initialY = originalY;
 
    fixedXSpeed = 0;
    fixedYSpeed = 0;
    
    [self resetForces];
	[self resetPosition];
    [self removeSmoke];
}

-(void) changePositionX:(int)dx andY:(int)dy
{	
	auxX = dx;
	auxY = dy;
	
    //CCLOG(@"Player.changePositionX: %i andY:%i",dx, dy);
    
	immortal = YES;
	
	[self stopAllActions];
	if (type == kGameObjectPlayer) {
		if (hasWeapon) [weapon stopAllActions];
		if (jetpackCollected) {
            [jetpack stopAllActions];
        }
	}
	
	[[GameLayer getInstance] pause];
	
	id blinkAction = [CCSequence actions:
					  [CCFadeOut actionWithDuration:0.2],
                      [CCDelayTime actionWithDuration:0.8],
					  [CCCallFunc actionWithTarget:self selector:@selector(changePosition)],
					  nil];
	[self runAction:blinkAction];
	
	if (type == kGameObjectPlayer) {
        if (hasWeapon) {
            id weaponBlinkAction = [CCSequence actions:
                                    [CCFadeOut actionWithDuration:0.2],
                                    nil];
            [weapon runAction:weaponBlinkAction];
		}
        
		if (jetpackCollected) {
			id jetpackBlinkAction = [CCSequence actions:
									 [CCFadeOut actionWithDuration:0.2],
									 nil];
			[jetpack runAction:jetpackBlinkAction];
		}
	}
}

-(void) changeToPosition:(CGPoint)pos
{
	//[self stop];
	
    CGSize hitArea = CGSizeMake(PLAYER_WIDTH / CC_CONTENT_SCALE_FACTOR(), PLAYER_HEIGHT / CC_CONTENT_SCALE_FACTOR());
    pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f - (MAP_TILE_WIDTH);
    pos.y += hitArea.height/2.0f - (MAP_TILE_HEIGHT/2.0f);
    
	self.position = pos;
	
	//body->SetTransform(b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO),0);
	[self markToTransformBody:b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO) angle:0.0];
    
}

-(void) changeInitialPositionX:(int)dx andY:(int)dy
{
	initialX = dx;
	initialY = dy;
}

-(void) changePosition
{
	[self stop];
	    
    CGSize hitArea = CGSizeMake(PLAYER_WIDTH / CC_CONTENT_SCALE_FACTOR(), PLAYER_HEIGHT / CC_CONTENT_SCALE_FACTOR());
    CGPoint pos = ccp(auxX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - auxY - 1) * MAP_TILE_HEIGHT));
    pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f;
    pos.y += hitArea.height/2.0f;
	
	self.position = pos;
	
	//body->SetTransform(b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO),0);
	[self markToTransformBody:b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO) angle:0.0];
    
	id blinkAction = [CCSequence actions:
					  [CCFadeIn actionWithDuration:0.2],
					  nil];
	
	[self runAction:blinkAction];
	
	if (type == kGameObjectPlayer) {
        if (hasWeapon) {
            id weaponBlinkAction = [CCSequence actions:
                                    [CCFadeIn actionWithDuration:0.2],
                                    nil];
            [weapon runAction:weaponBlinkAction];
		}
        
		if (jetpackCollected) {
			id jetpackBlinkAction = [CCSequence actions:
									 [CCFadeIn actionWithDuration:0.2],
									 nil];
			[jetpack runAction:jetpackBlinkAction];
		}
	}
	
	[[GameLayer getInstance] resume];
	
	immortal = NO;
}

-(void) hitsFloor
{
	b2Vec2 current = body->GetLinearVelocity();
	
    if (current.y > 0) return; // Ignore floor hits when we just walk into another different type of platform (so different body)
        
    //CCLOG(@"Player.hitsFloor: speed: %f", current.y);
    
    if (current.y < 0) {
        int hurtFall = (-(current.y * PTM_RATIO * CC_CONTENT_SCALE_FACTOR()) - 800) / 12;
        if (hurtFall > 0) {
            // Apply damage when falling at high speed
            [[SimpleAudioEngine sharedEngine] playEffect:@"IG Hero Damage.caf" pitch:1.0f pan:0.0f gain:1.0f];
            [self hit: hurtFall];
        }
    }
    
	canJump = YES;
    jumping = NO;
    jumpingMoving = NO;
    
    if (dying) return;
    
    if (!moving) {
        
        if (current.x != 0) {
            [self resetHorizontalSpeed];
        }
        
        if ((action != PRONE) && (action != CROUCH) && (!jetpackActivated)) [self setState:STAND];
        
    } else {
        [self setState:WALK];
    }
}

-(void) displaceHorizontally:(float)speed 
{
    //CCLOG(@"Player.displaceHorizontally: %f", speed);
    
	//if (speed != horizontalSpeedOffset) {
    
		b2Vec2 current = body->GetLinearVelocity();
		
        canJump = YES;
        
		if (moving) {
			if (direction == kDirectionLeft) body->SetLinearVelocity(b2Vec2(-horizontalSpeed + speed, current.y));
			else if (direction == kDirectionRight) body->SetLinearVelocity(b2Vec2(horizontalSpeed + speed, current.y));
			else body->SetLinearVelocity(b2Vec2(speed, current.y));
			
		} else {
			body->SetLinearVelocity(b2Vec2(speed, current.y));
		}
		
		horizontalSpeedOffset = speed;
	//}
}

-(void) setTouchingSwitch:(Switch *) touchingSwitch_ {
	touchingSwitch = touchingSwitch_;
}

-(void) resetForces
{
    //CCLOG(@"Player.resetForces");
	body->SetLinearVelocity(b2Vec2(0,0));
	body->SetAngularVelocity(0);
}

-(void) resume 
{
	[self resumeSchedulerAndActions];
    [weapon resumeSchedulerAndActions];
    [jetpack resumeSchedulerAndActions];
    
    paused = NO;
}

-(void) pause 
{
	[self pauseSchedulerAndActions];
    [weapon pauseSchedulerAndActions];
    [jetpack pauseSchedulerAndActions];
    
    paused = YES;
}

-(void) update:(ccTime)dt
{
    if (paused || dying) return;
    
	b2Vec2 current = body->GetLinearVelocity();
	//CCLOG(@"%f, %i", current.y, action);
	//CCLOG(@"%f,%f", self.positionf.x, self.position.y);
    
	if ((fabsf(roundf(current.y)) != 0) && !ignoreGravity) {
        
		//CCLOG(@"%f, %i", current.y, ignoreGravity);
		if ((current.y > 0) && jumping) {
			if (!ignoreGravity) [self setState:JUMPING];
			
		} else if (current.y < -0.01) {
			if (!ignoreGravity) [self setState:FALLING];
			
			if ((pressedJump && jetpackCollected && !jetpackActivated)
				&& (self.position.y + self.size.height*(1.0f-self.anchorPoint.y) < ([GameLayer getInstance].mapHeight * MAP_TILE_HEIGHT))) 
			{
				jetpackActivated = YES;
                jetpackSoundHandle = [[SimpleAudioEngine sharedEngine] playEffect:@"IG Jetpack.caf" loop:YES];
				[particle resetSystem];
				
				b2Vec2 impulse = b2Vec2(0.0f, fabs(current.y) + JETPACK_IMPULSE);
				body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
				
                [self setState:JUMPING];
                ignoreGravity = NO;
            
			}
		}
	}
	
	if (jetpackCollected && jetpackActivated) {
		//CCLOG(@"%f", self.position.y);
		if (self.position.y + self.size.height*(1.0f-self.anchorPoint.y) < ([GameLayer getInstance].mapHeight * MAP_TILE_HEIGHT)) {
			b2Vec2 impulse = b2Vec2(0.0f, JETPACK_SPEED);
			body->ApplyLinearImpulse(impulse, body->GetWorldCenter());
			
		} else {
			[self resetVerticalSpeed];
		}
		
		fuel -= 5;
		
		if (fuel <= 0) {
			[self removeJetpack];
		}
	}

    if (fixedXSpeed != 0) {
        b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(fixedXSpeed / PTM_RATIO, current.y);
		body->SetLinearVelocity(velocity);
    }
    
    if (fixedYSpeed != 0) {
        b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(current.x, -fixedYSpeed / PTM_RATIO);
		body->SetLinearVelocity(velocity);
        
        if (fixedYSpeed > 0) [self setState:JUMPING];
        else [self setState:FALLING];
    }
        
    if ((fixedXSpeed == 0) && (fixedYSpeed == 0)) {
        // ********************
        // direction check
        // ********************
        // if player is pushed, the physics engine might result in "moonwalking"
        if ( [ self isMoonWalking ] == YES ) [ self resetForces ];
    }
    
    
    if (inertia != 0) {
        if (inertia > 0) 
        {
            inertia -= 2.0f;
            if (inertia < 0) inertia = 0;
        }
        else {
            inertia += 2.0f;
            if (inertia > 0) inertia = 0;
        }
        
        if (inertia == 0) {
            inertia = 0;
            body->SetLinearDamping(0.0f);
        }
    }
    
    // done
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
                scrollOnProneDelay = 60;
			}
			
            scrollOnProneDelayCount += 1;
            if (scrollOnProneDelayCount >= scrollOnProneDelay) {
                scrollOnProne += 1.5;
            }
			
			if (scrollOnProne > scrollOnProneMax) scrollOnProne = scrollOnProneMax;
			
            //CCLOG(@">>>>> %f, %f, %f, %f", scrollOnProne, scrollOnProneMax, winSize.height, localPoint.y);
            
			//[[GameLayer getInstance] setViewpointCenter:ccp(point.x,point.y - scrollOnProne/CC_CONTENT_SCALE_FACTOR())];
            [[GameLayer getInstance] amendOffsetCameraY: -scrollOnProne/CC_CONTENT_SCALE_FACTOR()];
			
		} else if (scrollOnProne > 0) {
			scrollOnProne -= 4;
			if (scrollOnProne < 0) scrollOnProne = 0;
            scrollOnProneDelayCount = 0;
			
			//[[GameLayer getInstance] setViewpointCenter:ccp(point.x,point.y - scrollOnProne/CC_CONTENT_SCALE_FACTOR())];
            [[GameLayer getInstance] amendOffsetCameraY: -scrollOnProne/CC_CONTENT_SCALE_FACTOR()];
			
		} else {
			//[[GameLayer getInstance] setViewpointCenter:ccp(point.x,point.y)];
            [[GameLayer getInstance] amendOffsetCameraY: 0];
		}
		
        if (hasWeapon) [weapon setPosition:point];
		
		if (jetpackCollected) {
			[jetpack setPosition:point];
        }
        
        if (jetpackCollected || smokeOn) {
			if (facingLeft) [particle setPosition:ccp(point.x + 40.0f/CC_CONTENT_SCALE_FACTOR(), point.y - 40.0f/CC_CONTENT_SCALE_FACTOR())];
			else [particle setPosition:ccp(point.x - 40.0f/CC_CONTENT_SCALE_FACTOR(), point.y - 40.0f/CC_CONTENT_SCALE_FACTOR())];
		}
	}
	[super setPosition:point];
    
    if (type == kGameObjectPlayer) {
        b2Vec2 velocity = body->GetLinearVelocity( );
        if ((lround(velocity.y) == 0) && !jumping && !dying) {
            // Check there is a solid block under the player
            CGPoint mapPos = [self getTilePosition];
            int tileUnder = [[GameLayer getInstance] getTileAt:ccp(mapPos.x, mapPos.y + 1)];
            //CCLOG(@">>>>> tileUnder: %f,%f => %i", mapPos.x, mapPos.y + 1, tileUnder);
            
            if ((tileUnder == TILE_TYPE_SOLID) || (tileUnder == TILE_TYPE_CLOUD)) {
                safePositon = self.position;
                //CCLOG(@">>>>>>>>> Player safe position: %f,%f", safePositon.x, safePositon.y);
            }
        }
        
        if (NO) { // Debug only!!
            CGPoint mapPos = [self getTilePosition];
            int tileUnder = [[GameLayer getInstance] getTileAt:ccp(mapPos.x, mapPos.y + 1)];
            CCLOG(@">>>>> tileUnder: %f,%f => %i", mapPos.x, mapPos.y + 1, tileUnder);
            
            int tileFeet = [[GameLayer getInstance] getTileAt:ccp(mapPos.x, mapPos.y)];
            CCLOG(@">>>>> tileFeet: %f,%f => %i", mapPos.x, mapPos.y, tileFeet);
            
            int tileHead = [[GameLayer getInstance] getTileAt:ccp(mapPos.x, mapPos.y - 1)];
            CCLOG(@">>>>> tileHead: %f,%f => %i", mapPos.x, mapPos.y - 1, tileHead);
        }
        
        /*
        // Testing tile position in front of player
        CGPoint mapPos = [self getTilePosition];
        int tileInFront = 0;
        if (facingLeft) tileInFront = [[GameLayer getInstance] getTileAt:ccp(mapPos.x-1, mapPos.y+1)];
        else tileInFront = [[GameLayer getInstance] getTileAt:ccp(mapPos.x+1, mapPos.y+1)];
        CCLOG(@">>>>> %f,%f => %i", mapPos.x, mapPos.y, tileInFront);
        */
    }
}

// handle player collisions

-(BOOL) isBelowCloud:(GameObject *) object
{
    return (self.position.y - self.size.height*self.anchorPoint.y < object.position.y + object.size.height*(1.0f-object.anchorPoint.y));  
}

-( void )handleBeginCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    b2Vec2 velocity;
    
    switch ( object.type ) {
            
        case kGameObjectPlatform:
            if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ];
            break;
        
        case kGameObjectCloud:
            if ( [self isBelowCloud:object] ) data.contact->SetEnabled( false );
            else if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ];
            break;
            
        case kGameObjectKiller:
            if (debugImmortal || immune) if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ]; // just to be sure it can walk/jump
            [ self die ];
            break;
            
        case kGameObjectCollectable:
            [ object remove ];
            break;
            
        case kGameObjectRobot:
            interact = object;
            if ( data.position == CONTACT_IS_BELOW ) {
                velocity = object.body->GetLinearVelocity( );
                if ( ( velocity.y != 0 ) && !( ( Robot* )object ).shooted ) self.ignoreGravity = YES;
                [ self hitsFloor ];
                if ( ( velocity.x != 0 ) && !( ( Robot* )object ).shooted ) [ self displaceHorizontally:velocity.x ];
            }
            break;
            
        case kGameObjectBulletEnemy:
			if ( self.action != PRONE ) {
                [[SimpleAudioEngine sharedEngine] playEffect:@"IG Hero Damage.caf" pitch:1.0f pan:0.0f gain:1.0f];
				[ self hit:( ( Bullet* )object ).damage ];
				[ ( Bullet* )object die ];
			}
            break;            
            
        case kGameObjectMovingPlatform:
            
            if (( ( MovingPlatform* )object ).isKiller) {
                if (debugImmortal || immune) if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ]; // just to be sure it can walk/jump
                [ self die ];
            }
            
            velocity = ( ( MovingPlatform* )object ).body->GetLinearVelocity( );
            
            if ( (( MovingPlatform* )object ).isCloud ) {
                if ( [self isBelowCloud:object] ) data.contact->SetEnabled( false );
                else if ( data.position == CONTACT_IS_BELOW ) {
                    if ( ( ( MovingPlatform* )object ).velocity.y != 0 ) self.ignoreGravity = YES;
                    [ self hitsFloor ];
                    if ( ( ( MovingPlatform* )object ).velocity.x != 0 ) [ self displaceHorizontally:velocity.x ];
                } 
            
            } else if ( data.position == CONTACT_IS_BELOW ) {
                if ( ( ( MovingPlatform* )object ).velocity.y != 0 ) self.ignoreGravity = YES;
                [ self hitsFloor ];
                if ( ( ( MovingPlatform* )object ).velocity.x != 0 ) [ self displaceHorizontally:velocity.x ];
            }
            
            break;
            
        case kGameObjectSwitch:
            [ self setTouchingSwitch:( Switch* )object ];
            break;
            
        default:
            break;
    }
}

-( void )handlePreSolve:( contactData )data manifold:(const b2Manifold *)oldManifold { 
    GameObject* object = ( GameObject* )data.object;
    b2Vec2 velocity;
    
    switch ( object.type ) {
            
        case kGameObjectCloud:
            if ( [self isBelowCloud:object] ) data.contact->SetEnabled( false );
            else {
                b2Vec2 current = self.body->GetLinearVelocity();
                if ((current.y < -0.01) || ((fabsf(roundf(current.y)) == 0) && [self isJumping])) [self hitsFloor];
            }
            break;
            
        case kGameObjectMovingPlatform:
            if ( [self isBelowCloud:object] && (( MovingPlatform* )object ).isCloud ) data.contact->SetEnabled( false );
            else if ( data.position == CONTACT_IS_BELOW ) {
                velocity = ( ( MovingPlatform* )object ).body->GetLinearVelocity( );
                if ( ( ( MovingPlatform* )object ).velocity.x != 0 ) [ self displaceHorizontally:velocity.x ];
            }
            break;
            
        case kGameObjectRobot:
            if ( ( ( Robot* )object ).solid == NO ) data.contact->SetEnabled( false );
            else {
                if ( data.position == CONTACT_IS_BELOW ) {
                    velocity = ( ( Robot* )object ).body->GetLinearVelocity();
                   if ( ( velocity.x != 0 ) && !( ( Robot* )object ).shooted ) [ self displaceHorizontally:velocity.x ];
                }
            }
            break;
            
        default:
            break;
    }
}

-( void )handlePostSolve:( contactData )data impulse:(const b2ContactImpulse *)impulse { 
    GameObject* object = ( GameObject* )data.object;
    b2Vec2 velocity;
    
    switch ( object.type ) {
            
        case kGameObjectCloud:
            if ( [self isBelowCloud:object] ) data.contact->SetEnabled( false );
            break;
        
        case kGameObjectMovingPlatform:
            if ( [self isBelowCloud:object] && (( MovingPlatform* )object ).isCloud ) {
                data.contact->SetEnabled( false );
                
            } else {
                int32 count = data.contact->GetManifold()->pointCount;
                float32 maxImpulse = 0.0f;
                for (int32 i = 0; i < count; ++i) {
                    maxImpulse = b2Max(maxImpulse, impulse->normalImpulses[i]);
                }
                
                // We pressing player agains another object, so change direction
                if (maxImpulse > 10.0) {
                    velocity = ( ( MovingPlatform* )object ).body->GetLinearVelocity( );
                    
                    switch ( data.position ) {
                            
                        case CONTACT_IS_ABOVE:
                            if ( velocity.y < -0.01 ) [ ( MovingPlatform* )object changeDirection ];
                            break;
                        case CONTACT_IS_LEFT:
                            if ( velocity.x > 0 ) [ ( MovingPlatform* )object changeDirection ];
                            break;
                        case CONTACT_IS_RIGHT:
                            if ( velocity.x < -0.01 ) [ ( MovingPlatform* )object changeDirection ];
                            break;
                        default:
                            break;
                    }
                }
            }
            break;
            
        default:
            break;
    }
}

-( void )handleEndCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    b2Vec2 velocity;
    
    switch ( object.type ) {
            
        case kGameObjectPlatform:
        case kGameObjectCloud:
            [ self restartMovement ];
            break;
            
        case kGameObjectSwitch:
            [ self setTouchingSwitch:nil ];
            break;
            
        case kGameObjectRobot:
            [ ( Robot* )object finished:self ];
            velocity = ( ( Robot* )object ).body->GetLinearVelocity();
            if ( ( velocity.y != 0 ) && !( ( Robot* )object ).shooted ) self.ignoreGravity = NO;
            if ( ( velocity.x != 0 ) && !( ( Robot* )object ).shooted ) [ self displaceHorizontally:0.0f ];
            [ self restartMovement ];
            interact = nil;
            break;
            
        case kGameObjectMovingPlatform:
            if ( ( ( MovingPlatform* )object ).velocity.y != 0) self.ignoreGravity = NO;
            if ( ( ( MovingPlatform* )object ).velocity.x != 0) [ self displaceHorizontally:0.0f ];
            [ self restartMovement ];
            break;
            
        default:
            break;
            
    }
}

- (void) dealloc
{
	if (type == kGameObjectPlayer) {
		if (hasWeapon) [weapon release];
		if (jetpackCollected) [jetpack release];
	}
	
	[super dealloc];
}

@end
