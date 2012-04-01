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
#import "Robot.h"
#import "MovingPlatform.h"

//#import "GB2ShapeCache.h"

#define BAR_LIVE_WIDTH	43

@implementation Enemy

@synthesize collideTakeDamage;
@synthesize collideGiveDamage;
@synthesize behaviourCycle;

-(void) setupEnemy:(int)_playerID properties:(NSDictionary *)properties player:(Player *)_player 
{
	playerID = _playerID;
	player = _player;
	
	type = kGameObjectEnemy;
	direction = kDirectionNone;
	facingLeft = NO;
	
	initialX = [[properties objectForKey:@"positionX"] intValue];
	initialY = [[properties objectForKey:@"positionY"] intValue];
	lives = 1;
	health = [[properties objectForKey:@"health"] intValue];
	topHealth = health;
    
    score = [[properties objectForKey:@"score"] intValue];
    shootDamage = [[properties objectForKey:@"damage"] intValue];
    weaponName = [properties objectForKey:@"weapon"];
    shootDelay = [[properties objectForKey:@"shotDelay"] intValue] / 100.0f;
    horizontalSpeed = [[properties objectForKey:@"speed"] intValue] / (PTM_RATIO*CC_CONTENT_SCALE_FACTOR());
    multiShot = [[properties objectForKey:@"multiShot"] intValue];
    multiShotDelay = [[properties objectForKey:@"multiShotDelay"] intValue] / 100.0f;
    collideTakeDamage = [[properties objectForKey:@"collideTakeDamage"] intValue];
    collideGiveDamage = [[properties objectForKey:@"collideGiveDamage"] intValue];
    behaviour = [[properties objectForKey:@"behaviour"] intValue];
    boss = (health > BOSS_THRESHOLD);
    
    // NOTE: this is a temporary assignment to get the super crate box level working
    // in future this behaviour will be controlled via a robot script or enemy properties
    // rather than the spawned value.
    
    //CCLOG(@"Enemy.setupEnemy: %@", properties);
    
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
	barMiddle.scaleX = BAR_LIVE_WIDTH;
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
	
	switch (weaponID) {
		case 0: // Pistol
			
			//shootDamage = 25;
			//shootDelay= 0.5f;
			bulletOffsetY = -2/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 1: // Auto shotgun
			
			//shootDamage = 25;
			//shootDelay = 0.2f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 2: // Laser
			
			//shootDamage = 50;
			//shootDelay = 0.1f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 3: // Musket
			
			//shootDamage = 150;
			//shootDelay = 1.0f;
			bulletOffsetY = 0;
			
			break;
			
		case 4: // AK 47
			
			//shootDamage = 70;
			//shootDelay = 0.05f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 5: // M60
			
			//shootDamage = 120;
			//shootDelay = 0.05f;
			bulletOffsetY = -5/CC_CONTENT_SCALE_FACTOR();
			
			break;
			
		case 6: // Rocket Launcher
			
			//shootDamage = 400;
			//shootDelay = 1.2f;
			bulletOffsetY = 5/CC_CONTENT_SCALE_FACTOR();
			
			break;
	}
    
    // Create Enemy AI states based on settings

    EnemyBehaviourState *shootBehav = [[[EnemyBehaviourState alloc] 
                                       initWithMode:ENEMY_BEHAVIOUR_SHOOTING 
                                       minDuration:0.001f 
                                       maxDuration:0.001f 
                                       updateSelString:@"shoot" 
                                       initSelString:nil] autorelease];
    
    EnemyBehaviourState *walkBehav = [[[EnemyBehaviourState alloc] 
                                       initWithMode:ENEMY_BEHAVIOUR_WALKING
                                       minDuration:1.5f 
                                       maxDuration:1.5f 
                                       updateSelString:@"updateWalking" 
                                       initSelString:nil] autorelease];
    
    EnemyBehaviourState *idleBehav = [[[EnemyBehaviourState alloc] 
                                       initWithMode:ENEMY_BEHAVIOUR_NONE 
                                       minDuration:shootDelay
                                       maxDuration:shootDelay 
                                       updateSelString:@"idle" 
                                       initSelString:@"initIdle"] autorelease];
    
    EnemyBehaviourState *multiShotIdleBehav = [[[EnemyBehaviourState alloc] 
                                       initWithMode:ENEMY_BEHAVIOUR_NONE 
                                       minDuration:multiShotDelay
                                       maxDuration:multiShotDelay 
                                       updateSelString:@"idle" 
                                       initSelString:@"initIdle"] autorelease];
    
    // depending on user settings, add appropriate behaviours to cycle
    self.behaviourCycle = [[[NSMutableArray alloc] init] autorelease];
    behaviourCyclePosition = 0;
    behaviourTimer = 0.0f;
    
    if (!boss) [behaviourCycle insertObject:idleBehav atIndex:0];
    
    if (behaviour & ENEMY_BEHAVIOUR_WALKING) {
        [behaviourCycle insertObject:walkBehav atIndex:0];
    }
    
    if (behaviour & ENEMY_BEHAVIOUR_SHOOTING) {
        [behaviourCycle insertObject:shootBehav atIndex:0];
        for (int i = 0; i < multiShot; i++) {
            if (!boss) [behaviourCycle insertObject:multiShotIdleBehav atIndex:0];
            [behaviourCycle insertObject:shootBehav atIndex:0];
        }
    }
    
    if (behaviour & ENEMY_BEHAVIOUR_JUMPING) {
        canJump = NO;
        jumpDelay = ENEMY_JUMP_DELAY;
    }
    
    if (![self isFacingPlayer]) {
        if (facingLeft) {
            [self faceRight];
        } else {
            [self faceLeft];
        }
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
    
    // Don't collide with robots since robots have category 0x2
    fixtureDef.filter.maskBits = ~0x2; // = 0xFFFD
    
	body->CreateFixture(&fixtureDef);
    
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

-(void) changeDirection
{
	//CCLOG(@"Enemy.changeDirection: %i", direction);
	if (direction == kDirectionRight) [self moveLeft];
	else if (direction == kDirectionLeft) [self moveRight];
}

-(void) shoot
{
	if (!dying && !immortal && (action != PRONE) && (action != CROUCH)) {
		CGPoint bulletOffset = ccp(0,0);
		
        if (facingLeft) bulletOffset = ccp(-50/CC_CONTENT_SCALE_FACTOR(), bulletOffsetY);
        else bulletOffset = ccp(50/CC_CONTENT_SCALE_FACTOR(), bulletOffsetY);
		
		GameObjectDirection bulletDirection;
		if (facingLeft) bulletDirection = kDirectionLeft;
		else bulletDirection = kDirectionRight;
		
		Bullet *bullet = [Bullet bullet:bulletDirection weapon:weaponID];
		bullet.damage = shootDamage;
		[bullet setType:kGameObjectBulletEnemy];
		[bullet setPosition:ccpAdd(self.position,bulletOffset)];
		[bullet createBox2dObject:[GameLayer getInstance].world];
        
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

-(void) hit:(int)force 
{
	//CCLOG(@"Enemy.hit: %i, %i, %i", health, topHealth, force);
	[[SimpleAudioEngine sharedEngine] playEffect:@"IG Enemy Damage.caf" pitch:1.0f pan:0.0f gain:1.0f];
    
    health -= force;
	
	if (health == 0) {
		barLeft.visible = NO;
		barMiddle.visible = NO;
		barRight.visible = NO;
		
	} else {
		barLeft.visible = YES;
		barMiddle.visible = YES;
		barRight.visible = YES;
		
		barMiddle.scaleX = BAR_LIVE_WIDTH * health/(float)topHealth;
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
	if (!dying && !immortal) {
		dying = YES;
		jumping = NO;
		
		[self remove];
        
		[self setState:STAND];
		
		id dieAction;
        
        // If spawend then we need to destroy
        if (spawned)
            dieAction = [CCSequence actions:
                        [CCShow action],
						//[CCFadeOut actionWithDuration:1.0],
						[CCAnimate actionWithAnimation:die],
						[CCHide action],
                        [CCCallFunc actionWithTarget:self selector:@selector(destroy)],
						nil];
        else
            dieAction = [CCSequence actions:
                         [CCShow action],
                         //[CCFadeOut actionWithDuration:1.0],
                         [CCAnimate actionWithAnimation:die],
                         [CCHide action],
                         nil];
        
		[self runAction:dieAction];
	}
}

-(void) destroy 
{
    [self remove];
    [[GameLayer getInstance] removeEnemy:self]; 
}

-(void) restart
{
    lives = 1;
    health = topHealth;
    
    CGSize hitArea = CGSizeMake(34.0 / CC_CONTENT_SCALE_FACTOR(), 76.0 / CC_CONTENT_SCALE_FACTOR());
    CGPoint pos = ccp(initialX * MAP_TILE_WIDTH, (([GameLayer getInstance].mapHeight - initialY - 1) * MAP_TILE_HEIGHT));
    pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f;
    pos.y += hitArea.height/2.0f;
    
    self.position = pos;
    self.scaleX = 1;
    direction = kDirectionNone;
    facingLeft = NO;
    
    self.opacity = 255;
    self.visible = YES;
    
    dying = NO;
    immortal = NO;
    
    if (removed) [self createBox2dObject:[GameLayer getInstance].world size:size];
    [self markToTransformBody:b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO) angle:0.0];
    
    self.visible = YES;
    body->SetActive( true );
}

-(void) resetForces
{
    //CCLOG(@"Enemy.resetForces");
	body->SetLinearVelocity(b2Vec2(0,0));
	body->SetAngularVelocity(0);
}

- (void)setPosition:(CGPoint)point {
	[super setPosition:point];
	float spriteHeight = (self.batchNode.texture.contentSize.height/2) * CC_CONTENT_SCALE_FACTOR();
	CGPoint posHealth = ccp(self.position.x*REDUCE_FACTOR + [GameLayer getInstance].position.x, self.position.y*REDUCE_FACTOR + spriteHeight/2 + [GameLayer getInstance].position.y);
	[healthBar setPosition:ccp(roundf(posHealth.x), roundf(posHealth.y))];
}

// --------------------------------------------------------------
// AI actions
// --------------------------------------------------------------

-(void) stop
{
    // make sure we can call this each frame
    if ( ( direction == kDirectionNone ) && ( moving == NO ) ) return; 
	if ( dying || immortal ) return;
    b2Vec2 vel = body->GetLinearVelocity();
    body->SetLinearVelocity(b2Vec2(0.0f, vel.y));
    [self setState:STAND];
    moving = NO;
    direction = kDirectionNone;
}

-(BOOL) isFacingPlayer
{
    if ((self.position.x > player.position.x) && (facingLeft == YES)) return YES;
    else if ((self.position.x < player.position.x) && (facingLeft == NO)) return YES;
    else return NO;
}

-( void )faceRight {
    // make sure we can call this each frame
    if ( ( !facingLeft ) && ( moving == NO ) ) return; 
	if ( dying || immortal ) return;
    // stand and look right
    self.scaleX = 1;
    [self stop];
    facingLeft = NO;
}

-( void )faceLeft {
    // make sure we can call this each frame
    if ( ( facingLeft ) && ( moving == NO ) ) return;
	if ( dying || immortal ) return;
    // stand and look left
    self.scaleX = -1;
    [self stop];
    facingLeft = YES;
}

-( void )moveRight {
    // make sure we can call this each frame
    if ( ( direction == kDirectionRight ) && ( moving == YES ) ) return;
	if ( dying || immortal ) return;
    // walk right
    b2Vec2 current = body->GetLinearVelocity();
    b2Vec2 velocity = b2Vec2(horizontalSpeed, current.y);
    body->SetLinearVelocity(velocity);
    //
    self.scaleX = 1;
    [ self setState:WALK ];
    moving = YES;
    direction = kDirectionRight;
    facingLeft = NO;
}

-(void) moveLeft {
    // make sure we can call this each frame
    if ( ( direction == kDirectionLeft ) && ( moving == YES ) ) return;
	if ( dying || immortal ) return;
    // walk lelt
    b2Vec2 current = body->GetLinearVelocity();
    b2Vec2 velocity = b2Vec2(-horizontalSpeed, current.y);
    body->SetLinearVelocity(velocity);
    //    
    self.scaleX = -1;
    [ self setState:WALK ];
    moving = YES;
    direction = kDirectionLeft;
    facingLeft = YES;
}

// --------------------------------------------------------------
// jumps should maybe be randomized to make AI fail

-( void )jumpTo:( CGPoint )jumpTo {
    b2Vec2 impulse;
    
    // make sure repeated calls are okay
    if ( jumping ) return;
	if ( dying || immortal ) return;
    
    float dir = ( direction == kDirectionLeft ) ? -1.0f : +1.0f; 
    // create impulse based on jump direction
    if ( jumpTo.y >= 0 ) {
        // jump up or horizontally
        jumpTo.x -= 1;
        jumpTo.y += 3;
        impulse = b2Vec2( dir * ENEMY_JUMP_GAIN * jumpTo.x, ENEMY_JUMP_GAIN * jumpTo.y  );
    } else {
        // jump down
        jumpTo.y = 2;
        impulse = b2Vec2( dir * ENEMY_JUMP_GAIN * jumpTo.x, ENEMY_JUMP_GAIN * jumpTo.y );
    }
    // apply impulse
    [self resetForces];
    body->ApplyLinearImpulse( impulse, body->GetWorldCenter( ) );    
    [ self setState:JUMPING ];
    jumping = YES;
    
}

// --------------------------------------------------------------
// updated AI handling
// --------------------------------------------------------------

// get tile type relative to position ( -x => left, y => up )
// used in all tile checking
// y is subtracted, so that positive y relative to object, is up

-( int )tileType:( int )x y:( int )y {
    // if left, invert x
    if ( direction == kDirectionLeft ) x = -x;
    // return tile type
    return( [ [ GameLayer getInstance ] getTileAt:ccp( tilePos.x + x, tilePos.y - y ) ] );
}

// --------------------------------------------------------------
// check if a tile is walkable 

-( BOOL )tileWalkable:( int )x y:( int )y {
    int tile; 
    
    // bottom tile must be solid ground
    tile = [ self tileType:x y:( y - 1 ) ];
    
    
    if ( ( tile != TILE_TYPE_SOLID ) && ( tile != TILE_TYPE_CLOUD ) ) return( NO );
    
    if (tilePos.y > 0) {
        // tile +1 above ground must be free
        tile = [ self tileType:x y:y ];
        if ( tile == TILE_TYPE_SOLID ) return( NO );
    }
        
    if (tilePos.y > 1) {
        // tile +2 above ground must be free
        tile = [ self tileType:x y:( y + 1 ) ];
        return( tile != TILE_TYPE_SOLID );
    }
    
    return ( YES );
}


// --------------------------------------------------------------
// check if a tile is jumpable

-( BOOL )tileJumpable:( int )x y:( int )y {
    if ( [ self tileType:x y:( y + 0 ) ] != TILE_TYPE_NONE ) return( NO );
    if ( [ self tileType:x y:( y + 1 ) ] != TILE_TYPE_NONE ) return( NO );
    if ( [ self tileType:x y:( y + 2 ) ] != TILE_TYPE_NONE ) return( NO );
    return( YES );
}

// --------------------------------------------------------------
// check is enemy inside game area

-( BOOL )isInsideScreen:( CGPoint )pos {
#if ENEMY_TRACK_ALWAYS == 1
    return( YES );
#else
    CGSize winSize = [ [ CCDirector sharedDirector ] winSize ];
    CGRect rect;
    
    rect = CGRectMake( -self.contentSize.width - ENEMY_TRACK_RANGE, 
                      -self.contentSize.height - ENEMY_TRACK_RANGE,
                      winSize.width + ( self.contentSize.width * 2 ) + ( ENEMY_TRACK_RANGE * 2 ),
                      winSize.height + ( self.contentSize.height * 2 ) + ( ENEMY_TRACK_RANGE * 2 ) );
    return( CGRectContainsPoint( rect , pos ) );
#endif
}

// --------------------------------------------------------------
// check for jump up solution 

-( CGPoint )jumpUpSolution {
    int tile;
    
    if ([player isJumping]) return( CGPointZero ); // ignore AI if player is jumping
    
    // check for jump capabilities
    if ( ( behaviour & ENEMY_BEHAVIOUR_JUMPING ) == ENEMY_BEHAVIOUR_NONE ) return( CGPointZero );
    // check for standing on solid ground
    tile = [ self tileType:0 y:-1 ];
    if ( ( tile != TILE_TYPE_SOLID ) && ( tile != TILE_TYPE_CLOUD ) ) return( CGPointZero );
    // check for no obstructing tile overhead
    tile = [ self tileType:0 y:2 ];
    if ( ( tile != TILE_TYPE_NONE ) && ( tile != TILE_TYPE_CLOUD ) ) return( CGPointZero );
    //tile = [ self tileType:1 y:2 ];
    //if ( ( tile != TILE_TYPE_NONE ) && ( tile != TILE_TYPE_CLOUD ) ) return( CGPointZero );
    // scan for jump solution
    for ( int y = ENEMY_JUMP_UP_LOOKUP; y > 0; y -- ) {
        for ( int x = 1; x <= ENEMY_JUMP_UP_LOOKAHEAD; x ++ ) {
            // check for usable terrain
            if ( [ self tileWalkable:x y:y ] == YES ) {
                // return jump solution
                return( ccp( x, y ) );
            }
        }
    }
    // no jump solution
    return( CGPointZero );
}

// --------------------------------------------------------------
// check for a jump horizontal solution 

-( CGPoint )jumpHorizontalSolution {
    int tile;
    
    if ([player isJumping]) return( CGPointZero ); // ignore AI if player is jumping
    
    // check for jump capabilities
    if ( ( behaviour & ENEMY_BEHAVIOUR_JUMPING ) == ENEMY_BEHAVIOUR_NONE ) return( CGPointZero );
    // check for standing on solid ground
    tile = [ self tileType:0 y:-1 ];
    if ( ( tile != TILE_TYPE_SOLID ) && ( tile != TILE_TYPE_CLOUD ) ) return( CGPointZero );
    //
    for ( int x = 2; x <= ENEMY_JUMP_HORZ_LOOKAHEAD; x ++ ) {
        if ( [ self tileWalkable:x y:0 ] == YES ) {
            // return jump solution
            return( ccp( x, 0 ) );
        }
    }
    // no jump solution
    return( CGPointZero );
}

// --------------------------------------------------------------
// check for a ump down solution

-( CGPoint )jumpDownSolution {
    int tile;
    
    if ([player isJumping]) return( CGPointZero ); // ignore AI if player is jumping
    
    // check for jump capabilities
    if ( ( behaviour & ENEMY_BEHAVIOUR_JUMPING ) == ENEMY_BEHAVIOUR_NONE ) return( CGPointZero );
    // check for standing on solid ground
    tile = [ self tileType:0 y:-1 ];
    if ( ( tile != TILE_TYPE_SOLID ) && ( tile != TILE_TYPE_CLOUD ) ) return( CGPointZero );
    //
    for ( int x = ENEMY_JUMP_DOWN_LOOKAHEAD; x > 0; x -- ) {
        for ( int y = -ENEMY_JUMP_DOWN_LOOKDOWN; y < 0; y ++ ) {
            // check for usable terrain
            if ( [ self tileWalkable:x y:y ] == YES ) {
                // return jump solution
                return( ccp( x, y ) );
            }
        }
    }
    // no jump solution
    return( CGPointZero );
}

// --------------------------------------------------------------

-(void) update:( ccTime )dt {
    deltaTime = dt;
    
    if (paused || removed) return;
   	
    // check if visible, otherwise kill all AI
	CGPoint pos = [ [ GameLayer getInstance ] convertToMapCoordinates:self.position ];
    
    if ( [ self isInsideScreen:pos ] == NO ) {
        // probably wait for ongoing jumps to expire
		if ( self.visible ) {
			self.visible = NO;
			[ self stop ];
			body->SetActive( false );
            direction = kDirectionNone; // direction controls scan
		}
		return;
    
    } else if ( self.position.y - size.height*self.anchorPoint.y < MAP_TILE_HEIGHT ) {
        // kill enemy on bottom floor
        [self die];
        
	} else {
        if ( !self.visible ) {
            self.visible = YES;
            body->SetActive( true );
        }
	}
    
    tilePos = [ self getTilePosition ];
    
    // *****************************
    // AI control version 2.0 - This is as close to a port
    // of the actionscript code as possible
    // *****************************
    
    // maintain behaviour cycle
    behaviourTimer += dt;
    currentBehaviour = [self.behaviourCycle objectAtIndex:behaviourCyclePosition];
    if (behaviourTimer >= currentBehaviour.maxDuration) {
        
        behaviourCyclePosition = (behaviourCyclePosition + 1 == [behaviourCycle count]) ? 0 : behaviourCyclePosition + 1;
        behaviourTimer = 0;
        
        // init new mode

        currentBehaviour = [behaviourCycle objectAtIndex:behaviourCyclePosition];
        //CCLOG(@"New behaviour: %i", currentBehaviour.mode);
        
        // fire init hook
        if (currentBehaviour.init != nil) {
            [self performSelector:NSSelectorFromString(currentBehaviour.init) withObject:self];
        }
    }
    
    // perform main behaviour update hook.
    
    if (currentBehaviour.update != nil) {
        [self performSelector:NSSelectorFromString(currentBehaviour.update) withObject:self];
    }
    
    if (self.position.y < player.position.y) {
        [self jumpTimer];
    }
    
    
    // ********************
    // check for ongoing jump
    // ********************
    if ((behaviour & ENEMY_BEHAVIOUR_JUMPING) > 0) {
        // if a jump is ongoing or just finished, wait for sequence to complete
        if ( jumping ) {
            // check for advanced jump handling ( ex changing direction mid jump )
            [ super update:dt ];
            return;
        }
        if ( jumpDelay > 0 ) {
            jumpDelay -= dt;
            [ super update:dt ];
            return;
        }
    }
    
    [super update:dt];
}

-(void) jumpTimer {
    // handle jumping
    if ((behaviour & ENEMY_BEHAVIOUR_JUMPING) > 0) {
        jumpDelay -= deltaTime;
        if(jumpDelay <0) {
            jumpDelay = ENEMY_JUMP_DELAY;
            [self jump];
        }
    }
}

// Check for edge of ledges and jump if that is enabled

-(void) reverseNPCsAtLedges {
    
    int belowTile = [self tileType:0 y:-1];
    int nextTileAhead = [self tileType:1 y:-1]; 
    int threeAhead = [self tileType:3 y:-1];
    int twoBelowAhead = [self tileType:1 y:-2];
    
    // if we are not falling
    if (( ( belowTile == TILE_TYPE_SOLID ) || ( belowTile == TILE_TYPE_CLOUD ) )) {
        // do some stuffs!!
        if (( nextTileAhead != TILE_TYPE_SOLID ) && ( nextTileAhead != TILE_TYPE_CLOUD ) ) {
            
            if (( twoBelowAhead != TILE_TYPE_SOLID ) && ( twoBelowAhead != TILE_TYPE_CLOUD ) ) {
                if (((behaviour & ENEMY_BEHAVIOUR_JUMPING) > 0) && ( threeAhead != TILE_TYPE_SOLID ) && ( threeAhead != TILE_TYPE_CLOUD )) {
                    jumpDelay = 0;
                    [self jumpTimer];
                } else {
                    if (facingLeft) {
                        [self faceRight];
                    } else {
                        [self faceLeft];
                    }

                }
            }
        }
    }
}

// --------------------------------------------------------------
// handle enemy behaviour callbacks

-(void) initIdle {
    //CCLOG(@"initIdle called");
    [self stop];
    // change direction toward player
    if(![self isFacingPlayer] && facingLeft) 
        [self faceRight];
    else if(![self isFacingPlayer] && !facingLeft) {
        [self faceLeft];
    }
}

-(void) idle {
    //CCLOG(@"idle called.");
    [self stop];
}

-(void) updateWalking {
    //CCLOG(@"update walking called");
    
    if (!spawned) {
        [self reverseNPCsAtLedges];
    }
    
    if (facingLeft) {
        [self moveLeft];
    } else {
        [self moveRight];
    }
}
    


// --------------------------------------------------------------
// handle enemy collisions

-( void )handleBeginCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
            
        case kGameObjectPlayer:
            [[SimpleAudioEngine sharedEngine] playEffect:@"IG Hero Damage.caf" pitch:1.0f pan:0.0f gain:1.0f];
			[ player hit:self.collideGiveDamage];
			[ self hit:self.collideTakeDamage];
           
            if (!ENEMY_BLOCKS_PLAYER || dying) data.contact->SetEnabled( false );
            else if ( data.position == CONTACT_IS_ABOVE ) [ player hitsFloor ];
            break;
        
        //case kGameObjectEnemy:
        case kGameObjectCollectable:
            data.contact->SetEnabled( false );
            break;
            
        case kGameObjectCloud:
            if ( [self isBelowCloud:object] ) data.contact->SetEnabled( false );
            else if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ];
            break;
 
        case kGameObjectMovingPlatform:
            if ( [self isBelowCloud:object] && (( MovingPlatform* )object ).isCloud ) data.contact->SetEnabled( false );
            else if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ];
            break;
        
        case kGameObjectKiller:
            [ self die ];
            break;
        
        case kGameObjectPlatform:
            // enemy landed on something
            if ( data.position == CONTACT_IS_BELOW ) {
                if ( jumping ) {
                    jumping = NO;
                    [ self stop ];
                    jumpDelay = ENEMY_JUMP_DELAY;
                }
                [ self hitsFloor ];
            }
            break;
            
        case kGameObjectBullet:                
            [ self hit:( ( Bullet* )object ).damage ];
            [ ( Bullet* )object die ];
            break;
            
        default:
            break;
    }
    
}

// presolve is mainly for disabling collision

-( void )handlePreSolve:( contactData )data manifold:(const b2Manifold *)oldManifold {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
        
        case kGameObjectPlayer:
            if (!ENEMY_BLOCKS_PLAYER || dying) data.contact->SetEnabled( false );
            break;
            
        //case kGameObjectEnemy:
        //    data.contact->SetEnabled( false );
        //    break;
            
        case kGameObjectCloud:
            if ( [self isBelowCloud:object]) data.contact->SetEnabled( false );
            else {
                b2Vec2 current = self.body->GetLinearVelocity();
                if (current.y < -0.01) [self hitsFloor];
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
        case kGameObjectPlayer:
        case kGameObjectCollectable:
            [ self restartMovement ];
            break;
            
        case kGameObjectSwitch:
            [ self setTouchingSwitch:nil ];
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
	self.behaviourCycle = nil;
    [super dealloc];
}

@end
