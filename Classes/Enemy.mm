//
//  Enemy.m
//  DoubleHappy
//
//  Created by Jose Miguel on 30/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Enemy.h"
#import "GameLayer.h"
#import "Constants.h"
#import "Bullet.h"
#import "GB2ShapeCache.h"

@implementation Enemy

@synthesize score;
@synthesize weaponName;
@synthesize shotDelay;
@synthesize speed;
@synthesize multiShot;
@synthesize multiShotDelay;
@synthesize collideTakeDamage;
@synthesize collideGiveDamage;
@synthesize behavior;

-(void) setupEnemy:(int)_playerID initialX:(int)dx initialY:(int)dy health:(int)_health player:(Player *)_player 
{
	playerID = _playerID;
	player = _player;
	
	type = kGameObjectEnemy;
	direction = kDirectionNone;
	facingLeft = NO;
	
	initialX = dx;
	initialY = dy;
	
	lives = 1;
	health = _health;
	topHealth = _health;
	
	float spriteWidth = self.batchNode.texture.contentSize.width / 8;
	float spriteHeight = self.batchNode.texture.contentSize.height / 2;
	
	stand = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"enemy_stand_%i",playerID]];
	if (stand == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		stand = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:stand name:[NSString stringWithFormat:@"enemy_stand_%i",playerID]];
	}
	
	walk = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"enemy_walk_%i",playerID]];
	if (walk == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 6; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		walk = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:walk name:[NSString stringWithFormat:@"enemy_walk_%i",playerID]];
	}
	
	crouch = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"enemy_rouch_%i",playerID]];
	if (crouch == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 7; x <= 7; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,0,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		crouch = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:crouch name:[NSString stringWithFormat:@"enemy_crouch_%i",playerID]];
	}
	
	prone = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"enemy_prone_%i",playerID]];
	if (prone == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 0; x <= 0; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		prone = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:prone name:[NSString stringWithFormat:@"enemy_prone_%i",playerID]];
	}
	
	jump = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"enemy_jump_%i",playerID]];
	if (jump == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 1; x <= 2; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		jump = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:jump name:[NSString stringWithFormat:@"enemy_jump_%i",playerID]];
	}
	
	die = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"enemy_die_%i",playerID]];
	if (die == nil) {
		NSMutableArray *frames = [NSMutableArray array];
		for(int x = 3; x <= 7; x++) {
			CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:self.batchNode.texture rect:CGRectMake(x*spriteWidth,spriteHeight,spriteWidth,spriteHeight)];
			[frames addObject:frame];
		}
		die = [CCAnimation animationWithFrames:frames delay:0.125f];
		[[CCAnimationCache sharedAnimationCache] addAnimation:die name:[NSString stringWithFormat:@"enemy_die_%i",playerID]];
	}
	
	//
	healthBar = [CCSprite spriteWithSpriteFrameName:@"enemybarbg.png"];
	[[GameLayer getInstance].hudSpriteSheet addChild:healthBar];
	healthBar.visible = NO;
	
	barLeft = [CCSprite spriteWithSpriteFrameName:@"enemybarfront_07.png"];
	barMiddle = [CCSprite spriteWithSpriteFrameName:@"enemybarfront_03.png"];
	barRight = [CCSprite spriteWithSpriteFrameName:@"enemybarfront_05.png"];
	[healthBar addChild:barLeft];
	[healthBar addChild:barMiddle];
	[healthBar addChild:barRight];
	
	barLeft.scaleY = 0.9;
	barMiddle.scaleY = 0.9;
	barRight.scaleY = 0.9;
	
	barMiddle.anchorPoint = ccp(0.0, 0.5);
	barMiddle.scaleX = 48;
	[barLeft setPosition:ccp(3, healthBar.contentSize.height/2 + 0.5)];
	[barMiddle setPosition:ccp(barLeft.position.x + barLeft.contentSize.width/2, barLeft.position.y)];
	[barRight setPosition:ccp(barMiddle.position.x + barMiddle.contentSize.width * barMiddle.scaleX, barMiddle.position.y)];
	
	
	if ([weaponName isEqualToString:@"gun"]) {
		weaponID = 0;
			
	} else if ([weaponName isEqualToString:@"laser"]) {
		weaponID = 2;

	} else if ([weaponName isEqualToString:@"missile"]) {		
		weaponID = 6;
		
	} else if ([weaponName isEqualToString:@"homing_missile"]) {		
		weaponID = 6;

	} else {	
		weaponID = 0;
	}
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	//CCLOG(@"Enemy.createBox2dObject");
	
	size = _size;
	
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = true;
	playerBodyDef.fixedRotation = true;
	playerBodyDef.type = b2_dynamicBody;
	playerBodyDef.position = b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y - 0)/PTM_RATIO);
	playerBodyDef.userData = self;
	body = world->CreateBody(&playerBodyDef);
	
	[[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"player2"];
	
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
	
	removed = NO;
}

-(void) setState:(int) anim
{
	if (action == anim)	return;
	
	[self stopAllActions];
	self.opacity = 255;
	
	action = anim;
	
	if (anim == STAND)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"enemy_stand_%i",playerID] index:0];
	}
	else if (anim == WALK)
	{
		[self runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:walk]]];
	}
	else if (anim == CROUCH)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"enemy_crouch_%i",playerID] index:0];
	}
	else if (anim == PRONE)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"enemy_prone_%i",playerID] index:0];
	}
	else if (anim == JUMPING)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"enemy_jump_%i",playerID] index:0];
	}
	else if (anim == FALLING)
	{
		[self setDisplayFrameWithAnimationName:[NSString stringWithFormat:@"enemy_jump_%i",playerID] index:1];
	}
}

-(void) moveRight
{
	if (!dying && !inmortal) {
		//CCLOG(@"Enemy.moveRight: %i", speed);
		
		b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(HORIZONTAL_SPEED - (HORIZONTAL_SPEED - speed) + horizontalSpeedOffset, current.y);
		body->SetLinearVelocity(velocity);
		
		self.scaleX = 1;
		
		//if (!jumping) 
		[self setState:WALK];
		
		moving = YES;
		direction = kDirectionRight;
		facingLeft = NO;
	}
}

-(void) moveLeft
{
	if (!dying && !inmortal) {
		//CCLOG(@"Enemy.moveLeft: %i", speed);
		
		b2Vec2 current = body->GetLinearVelocity();
		b2Vec2 velocity = b2Vec2(-(HORIZONTAL_SPEED- (HORIZONTAL_SPEED - speed)) + horizontalSpeedOffset, current.y);
		body->SetLinearVelocity(velocity);
		
		self.scaleX = -1;
		
		//if (!jumping) 
		[self setState:WALK];
		
		moving = YES;
		direction = kDirectionLeft;
		facingLeft = YES;
	}
}

-(void) changeDirection
{
	CCLOG(@"Enemy.changeDirection: %i", direction);
	if (direction == kDirectionRight) [self moveLeft];
	else if (direction == kDirectionLeft) [self moveRight];
}

-(void) shoot
{
	if (!dying && !inmortal && (action != PRONE) && (action != CROUCH)) {
		CGPoint bulletOffset = ccp(0,0);
		
		/*
		if (action == PRONE)
		{
			if (facingLeft) bulletOffset = ccp(0, -24);
			else bulletOffset = ccp(60, -24);
		}
		else if (action == CROUCH)
		{
			if (facingLeft) bulletOffset = ccp(0, 0);
			else bulletOffset = ccp(60, 0);
		}
		else
		{
			if (facingLeft) bulletOffset = ccp(0, 8);
			else bulletOffset = ccp(60, 8);
		}
		*/
		
		if (facingLeft) bulletOffset = ccp(-50, -5);
		else bulletOffset = ccp(50, -5);
		
		GameObjectDirection bulletDirection;
		if (facingLeft) bulletDirection = kDirectionLeft;
		else bulletDirection = kDirectionRight;
		
		Bullet *bullet = [Bullet bullet:bulletDirection weapon:weaponID];
		bullet.damage = shootDamage;
		[bullet setType:kGameObjectBulletEnemy];
		[bullet setPosition:ccpAdd(self.position,bulletOffset)];
		[bullet createBox2dObject:[GameLayer getInstance].world];
	}
}

-(void) hit:(int)force 
{
	//CCLOG(@"Enemy.hit: %i, %i, %i", health, topHealth, force);
	health -= force;
	
	if (health == 0) {
		barLeft.visible = NO;
		barMiddle.visible = NO;
		barRight.visible = NO;
		
	} else {
		barLeft.visible = YES;
		barMiddle.visible = YES;
		barRight.visible = YES;
		
		barMiddle.scaleX = 48 * health/(float)topHealth;
		[barMiddle setPosition:ccp(barLeft.position.x + barLeft.contentSize.width/2, barLeft.position.y)];
		[barRight setPosition:ccp(barMiddle.position.x + barMiddle.contentSize.width * barMiddle.scaleX, barMiddle.position.y)];
	}
	
	[healthBar stopAllActions];
	
	if (health <= 0) {
		healthBar.visible = NO;
		[self die];
		
	} else {
		id healthAction = [CCSequence actions:
						   [CCShow action],
						   [CCDelayTime actionWithDuration:1.0],
						   [CCHide action],
						   nil];
		[healthBar runAction:healthAction];
	}
}

-(void) die
{
	if (!dying && !inmortal) {
		dying = YES;
		jumping = NO;
		removed = YES;
		
		body->SetLinearVelocity(b2Vec2(0.0f, 0.0f));
		
		[self setState:STAND];
		
		id dieAction = [CCSequence actions:
						//[CCFadeOut actionWithDuration:1.0],
						[CCAnimate actionWithAnimation:die],
						[CCCallFunc actionWithTarget:self selector:@selector(remove)],
						nil];
		[self runAction:dieAction];
	}
}

-(void) remove {
	[GameLayer getInstance].world->DestroyBody(body);
	self.visible = NO;
}

-(void) faceRight
{
	if (!dying && !inmortal) {
		self.scaleX = 1;
		direction = kDirectionRight;
		facingLeft = NO;
	}
}

-(void) faceLeft
{
	if (!dying && !inmortal) {
		self.scaleX = -1;
		direction = kDirectionLeft;
		facingLeft = YES;
	}
}

-(void) restartPosition
{
	if (removed) {
		[self resetPosition];
		
	} else {
		lives = 1;
		health = topHealth;
		
		float spriteWidth = self.batchNode.texture.contentSize.width / 8;
		float spriteHeight = self.batchNode.texture.contentSize.height / 2;
		
		CGPoint pos = ccp(initialX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - initialY - 1) * MAP_TILE_HEIGHT));
		pos.x += spriteWidth/2.0f;
		pos.y += spriteHeight/2.0f - 18.0f;
		
		self.position = pos;
		self.scaleX = 1;
		direction = kDirectionNone;
		facingLeft = NO;
		
		self.opacity = 255;
		self.visible = YES;
		
		dying = NO;
		removed = NO;
		inmortal = NO;
		
		body->SetTransform(b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y - 0)/PTM_RATIO),0);
		self.visible = YES;
	}
}

-(void) resetPosition
{
	if (!removed) return;
	
	lives = 1;
	health = topHealth;
	
	float spriteWidth = self.batchNode.texture.contentSize.width / 8;
	float spriteHeight = self.batchNode.texture.contentSize.height / 2;
	
	CGPoint pos = ccp(initialX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - initialY - 1) * MAP_TILE_HEIGHT));
	pos.x += spriteWidth/2.0f;
	pos.y += spriteHeight/2.0f - 18.0f;
	
	self.position = pos;
	self.scaleX = 1;
	direction = kDirectionNone;
	facingLeft = NO;
	
	self.opacity = 255;
	self.visible = YES;
	
	dying = NO;
	removed = NO;
	inmortal = NO;
	
	[self createBox2dObject:[GameLayer getInstance].world size:size];
	body->SetTransform(b2Vec2(((self.position.x - 30)/PTM_RATIO), (self.position.y - 0)/PTM_RATIO),0);
	self.visible = YES;
}

-(void) update:(ccTime)dt
{
	if (removed) return;
	
	CGSize winsize = [[CCDirector sharedDirector] winSize];
	CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:self.position];

	if (pos.x + self.contentSize.width < 0) {
		if (!self.visible) {
			self.visible = NO;
			[self stop];
		}
		return;
	
		
	} else if (pos.x - self.contentSize.width > winsize.width) {
		if (!self.visible) {
			self.visible = NO;
			[self stop];
		}
		return;
		
	} else if (!self.visible) {
		self.visible = YES;
	}
	
	// behavior
	// 1: static
	// 2: static shooting
	// 3: walking
	// 4: walking shooting
	// 5: clever following
	
	if (behavior == 1) return;
	
	if (behavior == 2) {
		if (self.position.x > player.position.x) {
			if (direction != kDirectionLeft) {
				//CCLOG(@"Enemy.update: face left");
				[self faceLeft];
			}
			
		} else if (self.position.x < player.position.x) {
			if (direction != kDirectionRight) {
				//CCLOG(@"Enemy.update: face rigth");
				[self faceRight];
			}
		}
		
	} else if ((behavior == 3) || (behavior == 4)  || (behavior == 5)) {
		if (self.position.x > player.position.x + 200.0f) {
			if (direction != kDirectionLeft) {
				//CCLOG(@"Enemy.update: move left");
				[self moveLeft];
			}
			
		} else if (self.position.x < player.position.x - 200.0f) {
			if (direction != kDirectionRight) {
				//CCLOG(@"Enemy.update: move rigth");
				[self moveRight];
			}
			
		} else if (roundf(self.position.y/100) == roundf(player.position.y/100)) {
			// Enemy and player on same level and close enough
			if ((self.position.x > player.position.x) && moving) {
				//CCLOG(@"Enemy.update: stop");
				[self stop];
				self.scaleX = -1;
				direction = kDirectionNone;
				facingLeft = YES;
				
			} else if ((self.position.x <= player.position.x) && moving) {
				//CCLOG(@"Enemy.update: stop (2)");
				[self stop];
				self.scaleX = 1;
				direction = kDirectionNone;
				facingLeft = NO;
			}
			
		} else {
			if (direction == kDirectionNone) {
				int rnd = arc4random()%100;
				if (rnd < 50) {
					//CCLOG(@"Enemy.update: move rigth (2)");
					[self moveRight];
					
				} else {
					//CCLOG(@"Enemy.update: move left (2)");
					[self moveLeft];
				}
			}
		}
	}
	
	if ((behavior == 2) || (behavior == 4)  || (behavior == 5)) {
		if (roundf(self.position.y/100) == roundf(player.position.y/100)) {
			// Enemy and player on same level
			int rnd = arc4random()%100;
			if (rnd < 2) {
				if (facingLeft) [self shoot];
				else if (!facingLeft) [self shoot];
			}
		}
	}
	
	if (prevPosition.x == self.position.x) {
		//CCLOG(@"can't move!!");
		[self setState:STAND];
		
	} else {
		[self setState:WALK];
	}
	
	prevPosition = self.position;
}

- (void)setPosition:(CGPoint)point {
	[super setPosition:point];
	float spriteHeight = self.batchNode.texture.contentSize.height/2;

	CGPoint posHealth = ccp(self.position.x + [GameLayer getInstance].position.x/REDUCE_FACTOR, self.position.y + spriteHeight/2 + 30 + [GameLayer getInstance].position.y/REDUCE_FACTOR);
	[healthBar setPosition:ccp(roundf(posHealth.x*REDUCE_FACTOR), roundf(posHealth.y*REDUCE_FACTOR))];
}

- (void) dealloc
{
	[weaponName release];
	
	[super dealloc];
}

@end
