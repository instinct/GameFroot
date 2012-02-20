//
//  ContactListener.m
//  Scroller
//
//  Created by min on 1/16/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "ContactListener.h"
#import "Constants.h"
#import "Player.h"
#import "Enemy.h"
#import "Bullet.h"
#import "GameLayer.h"
#import "MovingPlatform.h"
#import "Switch.h"
#import "Robot.h"

/*
#define IS_PLAYER(x, y)					(x.type == kGameObjectPlayer || y.type == kGameObjectPlayer)
#define IS_ENEMY(x, y)					(x.type == kGameObjectEnemy || y.type == kGameObjectEnemy)
#define IS_PLATFORM(x, y)				(x.type == kGameObjectPlatform || y.type == kGameObjectPlatform)
#define IS_CLOUD(x, y)					(x.type == kGameObjectCloud || y.type == kGameObjectCloud)
#define IS_KILLER(x, y)					(x.type == kGameObjectKiller || y.type == kGameObjectKiller)
#define IS_COLLECTABLE(x, y)			(x.type == kGameObjectCollectable || y.type == kGameObjectCollectable)
#define IS_BULLET(x, y)					(x.type == kGameObjectBullet || y.type == kGameObjectBullet)
#define IS_BULLET_ENEMY(x, y)			(x.type == kGameObjectBulletEnemy || y.type == kGameObjectBulletEnemy)
#define IS_MOVING_PLATFORM(x, y)		(x.type == kGameObjectMovingPlatform || y.type == kGameObjectMovingPlatform)
#define IS_SWITCH(x, y)					(x.type == kGameObjectSwitch || y.type == kGameObjectSwitch)
#define IS_ROBOT(x, y)					(x.type == kGameObjectRobot || y.type == kGameObjectRobot)
#define ARE_ENEMIES(x, y)				(x.type == kGameObjectEnemy && y.type == kGameObjectEnemy)
#define ARE_ROBOTS(x, y)				(x.type == kGameObjectRobot && y.type == kGameObjectRobot)
*/

ContactListener::ContactListener() {
}

ContactListener::~ContactListener() {
}

/*
bool ContactListener::Above(b2Contact *contact) {
    b2WorldManifold worldManifold;
    contact->GetWorldManifold(&worldManifold);
    b2Vec2 worldNormal = worldManifold.normal;
    //CCLOG(@"-----> contact normal: %d, %d", lround(worldNormal.x), lround(worldNormal.y));

    return (lround(worldNormal.y) == 1);
    
    //CCLOG(@"ContactListener.Above: %f >= %f",o1.position.y - o1.size.height*o1.anchorPoint.y, o2.position.y + o2.size.height*(1.0f-o2.anchorPoint.y));
    //return (o1.position.y - o1.size.height*o1.anchorPoint.y >= o2.position.y + o2.size.height*(1.0f-o2.anchorPoint.y));
}

bool ContactListener::Below(b2Contact *contact) {
    b2WorldManifold worldManifold;
    contact->GetWorldManifold(&worldManifold);
    b2Vec2 worldNormal = worldManifold.normal;
    //CCLOG(@"-----> contact normal: %d, %d", lround(worldNormal.x), lround(worldNormal.y));
    
    return (lround(worldNormal.y) == -1);
    
    //CCLOG(@"ContactListener.Below: %f <= %f",o1.position.y + o1.size.height*(1.0f-o1.anchorPoint.y), o2.position.y - o2.size.height*o2.anchorPoint.y);
    //return (o1.position.y + o1.size.height*(1.0f-o1.anchorPoint.y) <= o2.position.y - o2.size.height*o2.anchorPoint.y);    
}

bool ContactListener::BelowPos(GameObject *o1, GameObject *o2) {
    //CCLOG(@"ContactListener.BelowPos: %f <= %f",o1.position.y + o1.size.height*(1.0f-o1.anchorPoint.y), o2.position.y - o2.size.height*o2.anchorPoint.y);
    return (o1.position.y + o1.size.height*(1.0f-o1.anchorPoint.y) <= o2.position.y - o2.size.height*o2.anchorPoint.y);    
}

bool ContactListener::BelowCloud(GameObject *o1, GameObject *o2) {
    //CCLOG(@"ContactListener.BelowCloud: %f < %f",o1.position.y - o1.size.height*o1.anchorPoint.y, o2.position.y + o2.size.height*(1.0f-o2.anchorPoint.y));
    return (o1.position.y - o1.size.height*o1.anchorPoint.y < o2.position.y + o2.size.height*(1.0f-o2.anchorPoint.y));    
}

bool ContactListener::Right(b2Contact *contact) {
    b2WorldManifold worldManifold;
    contact->GetWorldManifold(&worldManifold);
    b2Vec2 worldNormal = worldManifold.normal;
    //CCLOG(@"-----> contact normal: %d, %d", lround(worldNormal.x), lround(worldNormal.y));
    
    return (lround(worldNormal.x) == 1);
    
    //CCLOG(@"ContactListener.Right: %f >= %f",o1.position.x - o1.size.width*o1.anchorPoint.x, o2.position.x + o2.size.width*(1.0f-o2.anchorPoint.y));
    //return (o1.position.x - o1.size.width*o1.anchorPoint.x  >= o2.position.x + o2.size.width*(1.0f-o2.anchorPoint.y));
}

bool ContactListener::Left(b2Contact *contact) {
    b2WorldManifold worldManifold;
    contact->GetWorldManifold(&worldManifold);
    b2Vec2 worldNormal = worldManifold.normal;
    //CCLOG(@"-----> contact normal: %d, %d", lround(worldNormal.x), lround(worldNormal.y));
    
    return (lround(worldNormal.x) == -1);
    
    //CCLOG(@"ContactListener.Left: %f <= %f",o1.position.x + o1.size.width*(1.0f-o1.anchorPoint.x) , o2.position.x - o2.size.width*o2.anchorPoint.y);
    //return (o1.position.x + o1.size.width*(1.0f-o1.anchorPoint.x) <= o2.position.x - o2.size.width*o2.anchorPoint.y);
}

void ContactListener::BeginContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
	if (o1.removed || o2.removed) {
		contact->SetEnabled(false);
		return;
	}
	
    if (!contact->IsTouching()) return;
    
	if ((IS_PLATFORM(o1, o2) || IS_CLOUD(o1, o2) || IS_ENEMY(o1, o2)) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with platform, cloud or enemy!");
		
		Player *player;
		GameObject *tile;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			tile = o2;
			
		} else {
			player = (Player *)o2;
			tile = o1;
		}
		
		if (Above(contact)) {
            [player hitsFloor];
		}
		
		if (IS_CLOUD(o1, o2)) {
			if (BelowCloud(player, tile)) {
				contact->SetEnabled(false);
			}
			
		} else if (IS_ENEMY(o1, o2)) {
			//CCLOG(@"-----> Player made contact with enemy!");
			Enemy *enemy;
			if (o1.type == kGameObjectEnemy) {
				enemy = (Enemy *)o1;
				
			} else {
				enemy = (Enemy *)o2;
			}
			
			[player hit:enemy.collideGiveDamage];
			[enemy hit:enemy.collideTakeDamage];
			[enemy resetForces];
		}
	
	} else if ((IS_PLATFORM(o1, o2) || IS_CLOUD(o1, o2) || IS_KILLER(o1, o2)) && IS_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with block!");
		
		Enemy *enemy;
		GameObject *tile;
		
		if (o1.type == kGameObjectEnemy) {
			enemy = (Enemy *)o1;
			tile = o2;
			
		} else {
			enemy = (Enemy *)o2;
			tile = o1;
		}

        if (Above(contact)) {
            [enemy hitsFloor];
		}
			
		
    } else if (IS_KILLER(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with killer item!");
		if (o1.type == kGameObjectCollectable) {
			Player *player = (Player *)o1;
			[player die];
		} else {
			Player *player = (Player *)o2;
			[player die];
		}
	
	} else if (IS_COLLECTABLE(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with collectable item!");

		if (o1.type == kGameObjectCollectable) {
			[o1 remove];
		} else {
			[o2 remove];
		}
	
	} else if (IS_ROBOT(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with robot item!");
		
		Robot *robot;
		Player *player;
		if (o1.type == kGameObjectRobot) {
			robot = (Robot *)o1;
			player = (Player *)o2;
			
		} else {
			robot = (Robot *)o2;
			player = (Player *)o1;
		}
		
		if (!robot.physics && !robot.solid) contact->SetEnabled(false);
		[robot touched:player];
		
		if (Above(contact)) {
			b2Vec2 vel = robot.body->GetLinearVelocity();
			
			if (vel.y != 0) {
				player.ignoreGravity = YES;
			}
			
			[player hitsFloor];
			
			if (vel.x != 0) {
				[player displaceHorizontally:vel.x];
			}
			
		}
		
	} else if (IS_BULLET(o1, o2) && IS_ROBOT(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with robot!");
		
		Robot *robot;
		Bullet *bullet;
		if (o1.type == kGameObjectRobot) {
			robot = (Robot *)o1;
			bullet  = (Bullet *)o2;
		} else {
			robot = (Robot *)o2;
			bullet  = (Bullet *)o1;
		}
		
		if ((robot.physics || robot.solid) && (!robot.sensor)) {
			[robot hit:bullet.damage];
			[bullet die];
		}
		
	} else if (ARE_ROBOTS(o1, o2)) {
		//CCLOG(@"-----> Robot made contact with another robot!");
		
		Robot *robot1;
		Robot *robot2;
		if (o1.type == kGameObjectRobot) {
			robot1 = (Robot *)o1;
			robot2  = (Robot *)o2;
		} else {
			robot1 = (Robot *)o2;
			robot2  = (Robot *)o1;
		}
		
		if ((!robot1.physics && !robot1.solid) || (!robot2.physics && !robot2.solid)) contact->SetEnabled(false);
		
	} else if (IS_ROBOT(o1, o2)) {
		//CCLOG(@"-----> Robot made contact with something!");
        Robot *robot;
		if (o1.type == kGameObjectRobot) {
			robot = (Robot *)o1;			
		} else {
			robot = (Robot *)o2;
		}
        if (!robot.physics && !robot.solid) contact->SetEnabled(false);
			   
	} else if (IS_COLLECTABLE(o1, o2) && IS_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with collectable item!");
		
	} else if (IS_BULLET_ENEMY(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with player!");
		contact->SetEnabled(false);
		
		if (o1.type == kGameObjectPlayer) {
			Player *player = (Player *)o1;
			Bullet *bullet = (Bullet *)o2;

			if ((player.action != PRONE) || (BelowPos(bullet, player))) {
				[player hit:bullet.damage];
				[bullet die];
			}
			
		} else {
			Player *player = (Player *)o2;
			Bullet *bullet = (Bullet *)o1;
			
			if ((player.action != PRONE) || (BelowPos(bullet, player))) {
				[player hit:bullet.damage];
				[bullet die];
			}
		}
		
	} else if (IS_BULLET(o1, o2) && IS_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with enemy!");
		contact->SetEnabled(false);
		
		if (o1.type == kGameObjectEnemy) {
			Enemy *enemy = (Enemy *)o1;
			Bullet *bullet = (Bullet *)o2;
			
			if ((enemy.action != PRONE) || (BelowPos(bullet, enemy))) {
				[enemy hit:bullet.damage];
				[bullet die];
			}
			
		} else {
			Enemy *enemy = (Enemy *)o2;
			Bullet *bullet = (Bullet *)o1;
			
			if ((enemy.action != PRONE) || (BelowPos(bullet, enemy))) {
				[enemy hit:bullet.damage];
				[bullet die];
			}
		}
	
	} else if (IS_BULLET(o1, o2) && IS_BULLET_ENEMY(o1, o2)) {
		///CCLOG(@"-----> Bullet made contact with bullet!");
		//contact->SetEnabled(false);
        
        Bullet *bullet1 = (Bullet *)o1;
        [bullet1 die];

        Bullet *bullet2 = (Bullet *)o2;
        [bullet2 die];
		
	} else if ((IS_BULLET(o1, o2) || IS_BULLET_ENEMY(o1, o2)) && IS_PLATFORM(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with platform!");
		
		if (o1.type == kGameObjectPlatform) {
			Bullet *bullet = (Bullet *)o2;
			[bullet die];
			
		} else {
			Bullet *bullet = (Bullet *)o1;
			[bullet die];
		}
			
	//} else if (IS_BULLET(o1, o2) || IS_BULLET_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with anything else!");
		//contact->SetEnabled(false);
		
		
	} else if (IS_MOVING_PLATFORM(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player contact with moving platform!");
        
		Player *player;
		MovingPlatform *platform;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			platform = (MovingPlatform *)o2;
		} else {
			player = (Player *)o2;
			platform = (MovingPlatform *)o1;
		}
		
        if (Above(contact)) {
            
            //CCLOG(@"Player hits moving platform from above!");
			b2Vec2 vel = platform.body->GetLinearVelocity();
            
			if (platform.velocity.y != 0) {
				player.ignoreGravity = YES;
			}
			
			[player hitsFloor];
			
			if (platform.velocity.x != 0) {
				[player displaceHorizontally:vel.x];
			}
			
		} else if (Below(contact)) {
                
			//CCLOG(@"Player hits moving platform from below!");
			b2Vec2 current = platform.body->GetLinearVelocity();
			if (current.y < 0) {
				[platform changeDirection];
			}
			
		} else if (Left(contact)) {

			//CCLOG(@"Player hits moving platform from left!");
			b2Vec2 current = platform.body->GetLinearVelocity();
			if (current.x < 0) {
				[platform changeDirection];
			}
			
		} else if (Right(contact)) {
		
            //CCLOG(@"Player hits moving platform from right!");
			b2Vec2 current = platform.body->GetLinearVelocity();
			if (current.x > 0) {
				[platform changeDirection];
			}
		}
	
	} else if (IS_SWITCH(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player contact with switch!");
		
		Player *player;
		Switch *touchingSwitch;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			touchingSwitch = (Switch *)o2;
			
		} else {
			player = (Player *)o2;
			touchingSwitch = (Switch *)o1;
		}
		
		[player setTouchingSwitch:touchingSwitch];
	
	} else if (ARE_ENEMIES(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with another enemy!");
		contact->SetEnabled(false);
		
		//Enemy *enemy = (Enemy *)o1;
		//[enemy resetForces];
		
	} else if (IS_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with something, problaby sensor or other tile!");
		
		Enemy *enemy;
		GameObject *anything;
		if (o1.type == kGameObjectEnemy) {
			enemy = (Enemy *)o1;
			anything = o2;
		} else {
			enemy = (Enemy *)o2;
			anything = o1;
		}
		
		if (anything.type == 0) {
			//CCLOG(@"-----> Enemy made contact with sensor!");
			// Hits sensor
			[enemy changeDirection];
			
		} else {
			//CCLOG(@"-----> Enemy made contact with other tile!");
			// Hits block tile
		}
		
	} else {
		//CCLOG(@"-----> Something made contact with something else! (%i with %i)", o1.type, o2.type);
	}
}

void ContactListener::PreSolve(b2Contact *contact, const b2Manifold *oldManifold) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
    if (!contact->IsTouching()) return;
    
	if (IS_CLOUD(o1, o2) && IS_PLAYER(o1, o2)) {
        //CCLOG(@"-----> Player contact with cloud!");
		
		Player *player;
		GameObject *tile;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			tile = o2;
			
		} else {
			player = (Player *)o2;
			tile = o1;
		}
		
		if (BelowCloud(player, tile)) {
			contact->SetEnabled(false);
			
		} else {
            b2Vec2 current = player.body->GetLinearVelocity();
            if (current.y < 0) [player hitsFloor];
		}
		
	} else if (IS_BULLET_ENEMY(o1, o2) && IS_PLAYER(o1, o2)) {
		///CCLOG(@"-----> Bullet made contact with player!");
		contact->SetEnabled(false);
		
	} else if (IS_BULLET(o1, o2) && IS_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with enemy!");
		contact->SetEnabled(false);
	
	} else if (IS_BULLET(o1, o2) && IS_BULLET_ENEMY(o1, o2)) {
		///CCLOG(@"-----> Bullet made contact with bullet!");
		contact->SetEnabled(false);
		
	} else if (IS_ENEMY(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with enemy!");

		Enemy *enemy;
		if (o1.type == kGameObjectEnemy) {
			enemy = (Enemy *)o1;
			
		} else {
			enemy = (Enemy *)o2;
		}
		[enemy resetForces];
		
	} else if (IS_MOVING_PLATFORM(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player contact with horizontal platform!");
        
		Player *player;
		MovingPlatform *platform;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			platform = (MovingPlatform *)o2;
		} else {
			player = (Player *)o2;
			platform = (MovingPlatform *)o1;
		}
		
        if (Above(contact)) {
			if (platform.velocity.x != 0) {
				b2Vec2 vel = platform.body->GetLinearVelocity();
				[player displaceHorizontally:vel.x];
			}
		}
		
	} else if (ARE_ENEMIES(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with another enemy!");
		contact->SetEnabled(false);
		
		//Enemy *enemy = (Enemy *)o1;
		//[enemy resetForces];
		
		
	} else if (IS_ROBOT(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with robot item!");
		
		Robot *robot;
		Player *player;
		if (o1.type == kGameObjectRobot) {
			robot = (Robot *)o1;
			player = (Player *)o2;
			
		} else {
			robot = (Robot *)o2;
			player = (Player *)o1;
		}
		
		if (!robot.physics && !robot.solid) contact->SetEnabled(false);
		else if (Above(contact)) {
			b2Vec2 vel = robot.body->GetLinearVelocity();
			if (vel.x != 0) {
				[player displaceHorizontally:vel.x];
			}
		}
		
	} else if (IS_ROBOT(o1, o2)) {
		//CCLOG(@"-----> Robot made contact with something!");
		Robot *robot;
		if (o1.type == kGameObjectRobot) {
			robot = (Robot *)o1;			
		} else {
			robot = (Robot *)o2;
		}
        if (!robot.physics && !robot.solid) contact->SetEnabled(false);
		
	}
}

void ContactListener::PostSolve(b2Contact *contact, const b2ContactImpulse *impulse) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
    if (!contact->IsTouching()) return;
    
	if (IS_CLOUD(o1, o2) && IS_PLAYER(o1, o2)) {
        //CCLOG(@"-----> Player contact with cloud!");
		
		Player *player;
		GameObject *tile;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			tile = o2;
			
		} else {
			player = (Player *)o2;
			tile = o1;
		}
		
		if (BelowCloud(player, tile)) {
			contact->SetEnabled(false);
		}
		
	}
}

void ContactListener::EndContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
    
	if (IS_MOVING_PLATFORM(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player contact ended with moving platform!");
		
		Player *player;
		MovingPlatform *platform;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			platform = (MovingPlatform *)o2;
		} else {
			player = (Player *)o2;
			platform = (MovingPlatform *)o1;
		}
		
		if (platform.velocity.y != 0) {
			player.ignoreGravity = NO;
		}
		
		if (platform.velocity.x != 0) {
			[player displaceHorizontally:0.0f];
		}
		
		[player restartMovement];
		
	} else if ((IS_PLATFORM(o1, o2) || IS_CLOUD(o1, o2)) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player contact ended with platform!");
		
		Player *player;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
		} else {
			player = (Player *)o2;
		}
		
		[player restartMovement];
	
	} else if (IS_SWITCH(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player ended contact with switch");
		
		Player *player;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			
		} else {
			player = (Player *)o2;
		}
		
		[player setTouchingSwitch:nil];
	
	} else if (IS_ROBOT(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player ended contact with robot item!");
		
		Robot *robot;
		Player *player;
		if (o1.type == kGameObjectRobot) {
			robot = (Robot *)o1;
			player = (Player *)o2;
			
		} else {
			robot = (Robot *)o2;
			player = (Player *)o1;
		}
	
		[robot finished:player];
		
		b2Vec2 vel = robot.body->GetLinearVelocity();
		
		if (vel.y != 0) {
			player.ignoreGravity = NO;
		}
		
		if (vel.x != 0) {
			[player displaceHorizontally:0.0f];
		}
		
		[player restartMovement];
        
    } else if (ARE_ROBOTS(o1, o2)) {
		//CCLOG(@"-----> Robot ended contact with another robot!");
		
		Robot *robot1;
		Robot *robot2;
		if (o1.type == kGameObjectRobot) {
			robot1 = (Robot *)o1;
			robot2  = (Robot *)o2;
		} else {
			robot1 = (Robot *)o2;
			robot2  = (Robot *)o1;
		}
		
		if (!robot1.physics && !robot1.solid) [robot1 finished:robot2];
        if (!robot2.physics && !robot2.solid) [robot2 finished:robot1];
	}
}
*/

CONTACT_IS ContactListener::solveContactPosition( b2Contact* contact ) {
    b2WorldManifold worldManifold;
    contact->GetWorldManifold(&worldManifold);
    b2Vec2 worldNormal = worldManifold.normal;
    
    // check
    if ( lround( worldNormal.y ) ==  1 ) return( CONTACT_IS_BELOW );
    if ( lround( worldNormal.y ) == -1 ) return( CONTACT_IS_ABOVE );
    if ( lround( worldNormal.x ) ==  1 ) return( CONTACT_IS_LEFT );
    if ( lround( worldNormal.x ) == -1 ) return( CONTACT_IS_RIGHT );
    return( CONTACT_IS_UNDEFINED );
}

// PreSolve can be called several times
// Primary use is to ignore collisions

void ContactListener::PreSolve(b2Contact *contact, const b2Manifold *oldManifold) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
    if (!contact->IsTouching()) return;
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handlePreSolve:data ];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handlePreSolve:data ];
    
}

// BeginContact is only called once

void ContactListener::BeginContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
	if ( o1.removed || o2.removed ) {
		contact->SetEnabled( false ); // <- NO EFFECT
		return;
	}
	
    if (!contact->IsTouching()) return;
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handleBeginCollision:data ];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handleBeginCollision:data ];
    
}

// EndContact is only called once

void ContactListener::EndContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
    
    contactData data;
    
    data.contact = contact;
    data.position = solveContactPosition( contact );
    
    // handle o1 contact
    data.object = o2;
    [ o1 handleEndCollision:data ];
    
    // handle o2 contact
    data.object = o1;
    [ o2 handleEndCollision:data ];
    
}

void ContactListener::PostSolve(b2Contact *contact, const b2ContactImpulse *impulse) {
    
}