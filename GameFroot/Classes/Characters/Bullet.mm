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
	NSString *skin;
    
    if (_weapon == 0) {
        skin = @"bullet1.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
        spriteWidth = spriteSheet.texture.contentSize.width / 8;
    
    } else if (_weapon == 1) {
        skin = @"bullet1.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
		spriteWidth = spriteSheet.texture.contentSize.width / 8;
        
	} else if (_weapon == 2) {
        skin = @"bullet_laser.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
		spriteWidth = spriteSheet.texture.contentSize.width / 8;
	
    } else if (_weapon == 3) {
        skin = @"bullet1.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
        spriteWidth = spriteSheet.texture.contentSize.width / 8;
    
    } else if (_weapon == 4) {
        skin = @"bullet1.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
        spriteWidth = spriteSheet.texture.contentSize.width / 8;
        
    } else if (_weapon == 5) {
        skin = @"bullet1.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
        spriteWidth = spriteSheet.texture.contentSize.width / 8;
        
	} else if (_weapon == 6) {
        skin = @"rocketsheet.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
		spriteWidth = spriteSheet.texture.contentSize.width / 13;
	
    } else if (_weapon == 69) {
        skin = @"bullet_ray.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
		spriteWidth = spriteSheet.texture.contentSize.width / 8;
    
    } else if (_weapon == 70) {
        skin = @"bullet_ray.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
		spriteWidth = spriteSheet.texture.contentSize.width / 8;
        
	} else {
        skin = @"bullet_ray.png";
        spriteSheet = [[GameLayer getInstance] addBullet:skin];
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
    
    bullet.spawned = YES;
	
	if (REDUCE_FACTOR != 1.0f) [spriteSheet.textureAtlas.texture setAntiAliasTexParameters];
	else [spriteSheet.textureAtlas.texture setAliasTexParameters];
	
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
	bulletBodyDef.bullet = true;
	bulletBodyDef.type = b2_dynamicBody;
	
	bulletBodyDef.position = b2Vec2((self.position.x/PTM_RATIO), self.position.y/PTM_RATIO);
	bulletBodyDef.userData = self;
	body = world->CreateBody(&bulletBodyDef);
	
	body->SetGravityScale(0.0f);
	
	b2PolygonShape shape;
	shape.SetAsBox((32.0f/3.0f)/(PTM_RATIO*CC_CONTENT_SCALE_FACTOR()), (20.0f/6.0f)/(PTM_RATIO*CC_CONTENT_SCALE_FACTOR()));
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
    
    size = self.contentSize;
}

-(void) setAngle:(float)angle
{
    b2Vec2 velocity = body->GetLinearVelocity();
    body->SetLinearVelocity(b2Vec2(velocity.x, angle));
}

-(void) die {
	if (!removed) {
		
		[self unschedule:@selector(update:)];
		
		[self remove];
        
        // if rocket then go boom!
        if(weapon == 6) {
            [[SimpleAudioEngine sharedEngine] playEffect:@"W Rocket launcher boom.caf"];
        }
        
        // Bullets always have to be destroyed (spawend)
		id dieAction = [CCSequence actions:
                        [CCShow action],
						[CCAnimate actionWithAnimation:explosion],
						[CCHide action],
						[CCCallFunc actionWithTarget:self selector:@selector(destroy)],
						nil];
		[self runAction:dieAction];
	}
}

// --------------------------------------------------------------
// check is bullet inside game area

-( BOOL )isInsideScreen:( CGPoint )pos {
    CGSize winSize = [ [ CCDirector sharedDirector ] winSize ];
    CGRect rect;
    
    rect = CGRectMake( -self.contentSize.width - BULLET_TRACK_RANGE, 
                      -self.contentSize.height - BULLET_TRACK_RANGE,
                      winSize.width + ( self.contentSize.width * 2 ) + ( BULLET_TRACK_RANGE * 2 ),
                      winSize.height + ( self.contentSize.height * 2 ) + ( BULLET_TRACK_RANGE * 2 ) );
    return( CGRectContainsPoint( rect , pos ) );
}

-(void) update:(ccTime)dt
{
    // check if visible, otherwise kill it
	CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:self.position];
		
	if ( [ self isInsideScreen:pos ] == NO ) {
		[self die];
		return;
	}
	
	[super update:dt];
}

// handle bullet collisions
-( void )handleBeginCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {

        case kGameObjectBullet:
            if (self.type == kGameObjectBulletEnemy) {
                [ ( Bullet* )object die ];
                [ self die ];
            }
            break;
        
        case kGameObjectBulletEnemy:    
            if (self.type == kGameObjectBullet) {
                [ ( Bullet* )object die ];
                [ self die ];
            }
            break;
            
        case kGameObjectPlatform:
            [ self die ];
            break;
            
        default:
            break;
    }
}

@end
