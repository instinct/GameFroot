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
    multiShotDelay = [[properties objectForKey:@"multiShotDelay"] intValue];
    collideTakeDamage = [[properties objectForKey:@"collideTakeDamage"] intValue];
    collideGiveDamage = [[properties objectForKey:@"collideGiveDamage"] intValue];
    behaviour = [[properties objectForKey:@"behaviour"] intValue];
    
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
    body->SetLinearVelocity(b2Vec2(horizontalSpeedOffset, vel.y));
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
    CGPoint jumpPos;
    CGPoint playerPos;
    
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
    
    // check for passive AI
	if ( behaviour == ENEMY_BEHAVIOUR_NONE ) {
        if ( [ self isMoonWalking ] == YES ) [ self resetForces ];
        [ super update:dt ];
        return;
    }
    
    // *****************************
    // AI control     
    // *****************************
    
    // find positions
    tilePos = [ self getTilePosition ];
    playerPos = [ player getTilePosition ];
    
    // ********************
    // check for firing solution
    // ********************
    if ((behaviour & ENEMY_BEHAVIOUR_SHOOTING) > 0) {
        if ( ( playerPos.y == tilePos.y ) || ( playerPos.y - 1 == tilePos.y ) ) {
            
            if ((behaviour & ENEMY_BEHAVIOUR_WALKING) == 0) {
                // If not walking, face player
                if (player.position.x < self.position.x) [self faceLeft];
                else if (player.position.x > self.position.x) [self faceRight];
            }
            
            // shoot if facing correct
            if ( [ self isFacingPlayer ] ) {
                shootTimer -= dt;
                if ( shootTimer <= 0 ) {
                    [ self shoot ];
                    shootTimer = shootDelay;
                } 
            }
        } else {
#if ENEMY_INITIAL_WEAPON_DELAY
            shootTimer = shootDelay;
#else
            shootTimer -= dt;
#endif
        }
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
    
    // ********************
    // handle walking
    // ********************
    if ( ((behaviour & ENEMY_BEHAVIOUR_WALKING) > 0) && ((behaviour & ENEMY_BEHAVIOUR_JUMPING) == 0) ) {
		
        if (tilePos.y == playerPos.y) {
            // Player and enemy on same horizontal level
            
            int tileType = [self tileType:1 y:-1];
            
            if ((behaviour & ENEMY_BEHAVIOUR_SHOOTING) == 0) {
                // Try to hit the player since it won't shoot
                
                if (tileType != TILE_TYPE_SPIKE) { 
                    if (player.position.x < self.position.x) {
                        [self moveLeft];
                        
                    } else if (player.position.x > self.position.x) {
                        [self moveRight];
                    }
                    
                } else {
                    // Enemy can't reach player, stop facing him
                    if (player.position.x < self.position.x) [self faceLeft];
                    else if (player.position.x > self.position.x) [self faceRight];
                }
                
            } else {
                
                // Stops ENEMY_WALKING_STOPAHEAD tiles in front of player
                if ( (tilePos.x > playerPos.x + ENEMY_WALKING_STOPAHEAD) && (tileType != TILE_TYPE_SPIKE) ) {
                    if (direction != kDirectionLeft) [self moveLeft];
                    
                } else if ( (tilePos.x < playerPos.x - ENEMY_WALKING_STOPAHEAD) && (tileType != TILE_TYPE_SPIKE) ) {
                    if (direction != kDirectionRight) [self moveRight];
                    
                } else {
                    // Enemy and player on same level and close enough, face player
                    if (player.position.x < self.position.x) [self faceLeft];
                    else if (player.position.x > self.position.x) [self faceRight];
                }
            }
            
        } else {
            // Enemy on different horizontal level
            
            b2Vec2 current = body->GetLinearVelocity();
            
            if (fabsf(roundf(current.x)) == 0) {
                // Not moving, start randomly
                int rnd = arc4random() % 2;
                if (rnd == 0) [self moveLeft];
                else [self moveRight];
                
            } else if ( ( [ self tileWalkable:1 y:0 ] == NO ) && ( [ self tileWalkable:-1 y:0 ] == YES ) ) {
                // ignore if jumping or falling
                b2Vec2 vel = body->GetLinearVelocity();
                
                if (!jumping && (fabsf(roundf(vel.y)) == 0)) {
                    int tileType = [self tileType:1 y:-1];
                    if ( !spawned || (tileType == TILE_TYPE_SPIKE) ) {
                        // Ignore ledges flag if enemy spawned
                        [ self changeDirection ];
                    }
                }
            }
        }
	}
    
    // ********************
    // jump handling
    // ********************
    // search for jump solutions
    if ((behaviour & ENEMY_BEHAVIOUR_JUMPING) > 0) {
        
        if ( ( tilePos.y != playerPos.y ) && ( direction == kDirectionNone ) ) {
            if ( self.position.x > player.position.x ) {
                [ self moveLeft ];
            } else {
                [ self moveRight ];
            }
        }
        
        jumpPos = CGPointZero;
        // check if player is above, and jump from any valid position
        if ( playerPos.y < tilePos.y ) {
            jumpPos = [ self jumpUpSolution ];
        } else if ( [ self tileWalkable:1 y:0 ] == NO ) {
            // only jump down and horizontally from end tiles
            // if player is below
            if ( playerPos.y > tilePos.y ) {
                jumpPos = [ self jumpDownSolution ];
            } else {
                jumpPos = [ self jumpHorizontalSolution ];                
            }
        }
        // check for jump
        if ( jumpPos.x != 0 ) {
            [ self jumpTo:jumpPos ];
            jumping = YES;
            
        } else {
            // no jump
            if (tilePos.y == playerPos.y) {
                // Enemy and player on same level 
                
                if ((behaviour & ENEMY_BEHAVIOUR_SHOOTING) == 0) {
                    // Try to hit the player
                    if (tilePos.y == playerPos.y) {
                        if (player.position.x < self.position.x) [self moveLeft];
                        else if (player.position.x > self.position.x) [self moveRight];
                    }
                    
                } else {
                    // Stops ENEMY_WALKING_STOPAHEAD tiles in front of player
                    if (tilePos.x > playerPos.x + ENEMY_WALKING_STOPAHEAD) {
                        if (direction != kDirectionLeft) [self moveLeft];
                        
                    } else if (tilePos.x < playerPos.x - ENEMY_WALKING_STOPAHEAD) {
                        if (direction != kDirectionRight) [self moveRight];
                        
                    } else {
                        // Enemy and player close enough, face player
                        if (player.position.x < self.position.x) [self faceLeft];
                        else if (player.position.x > self.position.x) [self faceRight];
                    }
                }
                
            } else if ( [ self tileWalkable:1 y:0 ] == NO ) {
                // ignore if jumping or falling
                b2Vec2 vel = body->GetLinearVelocity();
                if (!jumping && (fabsf(roundf(vel.y)) == 0)) [ self changeDirection ];
            }
        }
    }
    
    // done
	[super update:dt];
}

// --------------------------------------------------------------
// handle enemy collisions

-( void )handleBeginCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
            
        case kGameObjectPlayer:
			[ player hit:self.collideGiveDamage];
			[ self hit:self.collideTakeDamage];
           
            if (!ENEMY_BLOCKS_PLAYER || dying) data.contact->SetEnabled( false );
            else if ( data.position == CONTACT_IS_ABOVE ) [ player hitsFloor ];
            break;
        
        case kGameObjectEnemy:
        case kGameObjectCollectable:
            data.contact->SetEnabled( false );
            break;
            
        case kGameObjectCloud:
            if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ];
            else if ( [self isBelowCloud:object] ) data.contact->SetEnabled( false );
            break;
 
        case kGameObjectMovingPlatform:
            if ( data.position == CONTACT_IS_BELOW ) [ self hitsFloor ];
            else if ( [self isBelowCloud:object] && (( MovingPlatform* )object ).isCloud ) data.contact->SetEnabled( false );
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
            
        case kGameObjectEnemy:
            data.contact->SetEnabled( false );
            break;
            
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
            else {
                b2Vec2 current = self.body->GetLinearVelocity();
                if (current.y < -0.01) [self hitsFloor];
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
	[super dealloc];
}

@end
