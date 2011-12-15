//
//  ContactListener.m
//  Scroller
//
//  Created by min on 1/16/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "ContactListener.h"
#import "Constants.h"
#import "GameObject.h"
#import "Player.h"
#import "Enemy.h"
#import "Bullet.h"
#import "GameLayer.h"
#import "MovingPlatform.h"
#import "Switch.h"
#import "Robot.h"

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

ContactListener::ContactListener() {
}

ContactListener::~ContactListener() {
}

void ContactListener::BeginContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
	if (o1.removed || o2.removed) {
		contact->SetEnabled(false);
		return;
	}
	
	if ((IS_PLATFORM(o1, o2) || IS_CLOUD(o1, o2) || IS_ENEMY(o1, o2)) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with platform or enemy!");
		
		Player *player;
		GameObject *tile;
		
		if (o1.type == kGameObjectPlayer) {
			player = (Player *)o1;
			tile = o2;
			
		} else {
			player = (Player *)o2;
			tile = o1;
		}
		
		//CCLOG(@"Check if floor: %f , %f", player.position.y - player.size.height*player.anchorPoint.y, tile.position.y + tile.size.height/2.0f);
		if (player.position.y - player.size.height*player.anchorPoint.y >= tile.position.y + tile.size.height/2.0f) {
			
			//CCLOG(@"%f , %f", player.position.x + player.size.width*(1.0f-player.anchorPoint.x), tile.position.x - tile.size.width/2.0f);
			//CCLOG(@"%f , %f", player.position.x - player.size.width*player.anchorPoint.x, tile.position.x + tile.size.width/2.0f);
			
			if ((player.position.x + player.size.width*(1.0f-player.anchorPoint.x) - ADJUSTMENT_COLLISION_X >= tile.position.x - tile.size.width/2.0f)
				&& (player.position.x - player.size.width*player.anchorPoint.x + ADJUSTMENT_COLLISION_X <= tile.position.x + tile.size.width/2.0f) ) {
				
				[player hitsFloor];
				
			} else {
				contact->SetEnabled(false);	
			}
		}
		
		if (IS_CLOUD(o1, o2)) {
			if (player.position.y - player.size.height*player.anchorPoint.y < tile.position.y + tile.size.height/2.0f) {
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

		if (enemy.position.y - enemy.size.height*enemy.anchorPoint.y >= tile.position.y + tile.size.height/2.0f) {
					
			if ((enemy.position.x + enemy.size.width*(1.0f-enemy.anchorPoint.x) - ADJUSTMENT_COLLISION_X >= tile.position.x - tile.size.width/2.0f)
				&& (enemy.position.x - enemy.size.width*enemy.anchorPoint.x + ADJUSTMENT_COLLISION_X <= tile.position.x + tile.size.width/2.0f) ) {
						
				[enemy hitsFloor];
			
			} else {
				contact->SetEnabled(false);	
				
			}
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
		//contact->SetEnabled(false);
		
		if (o1.type == kGameObjectCollectable) {
			[o1 remove];
		} else {
			[o2 remove];
		}
	
	} else if (IS_ROBOT(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player made contact with robot item!");
		//contact->SetEnabled(false);
		
		if (o1.type == kGameObjectRobot) {
			[(Robot *)o1 touched:o2];
		} else {
			[(Robot *)o2 touched:o1];
		}
		
	} else if (IS_COLLECTABLE(o1, o2) && IS_ENEMY(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with collectable item!");
		
	} else if (IS_BULLET_ENEMY(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Bullet made contact with player!");
		contact->SetEnabled(false);
		
		if (o1.type == kGameObjectPlayer) {
			Player *player = (Player *)o1;
			Bullet *bullet = (Bullet *)o2;

			if ((player.action != PRONE) || (bullet.position.y < player.position.y - player.size.height*player.anchorPoint.y)) {
				[player hit:bullet.damage];
				[bullet die];
			}
			
		} else {
			Player *player = (Player *)o2;
			Bullet *bullet = (Bullet *)o1;
			
			if ((player.action != PRONE) || (bullet.position.y < player.position.y - player.size.height*player.anchorPoint.y)) {
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
			
			if ((enemy.action != PRONE) || (bullet.position.y < enemy.position.y - enemy.size.height*enemy.anchorPoint.y)) {
				[enemy hit:bullet.damage];
				[bullet die];
			}
			
		} else {
			Enemy *enemy = (Enemy *)o2;
			Bullet *bullet = (Bullet *)o1;
			
			if ((enemy.action != PRONE) || (bullet.position.y < enemy.position.y - enemy.size.height*enemy.anchorPoint.y)) {
				[enemy hit:bullet.damage];
				[bullet die];
			}
		}
	
	} else if (IS_BULLET(o1, o2) && IS_BULLET_ENEMY(o1, o2)) {
		///CCLOG(@"-----> Bullet made contact with bullet!");
		contact->SetEnabled(false);
		
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
			
		if (player.position.y - player.size.height*player.anchorPoint.y >= platform.position.y + platform.size.height/2.0f) {
			b2Vec2 vel = platform.body->GetLinearVelocity();
			
			if (platform.velocity.y != 0) {
				player.ignoreGravity = YES;
			}
			
			[player hitsFloor];
			
			if (platform.velocity.x != 0) {
				[player displaceHorizontally:vel.x];
			}
			
		//} else if (player.position.y - player.size.height*player.anchorPoint.y < platform.position.y + platform.size.height/2.0f) {
		//	contact->SetEnabled(false);
			
		} else if (player.position.y + player.size.height*(1.0f-player.anchorPoint.y) <= platform.position.y - platform.size.height/2.0f) {
			//CCLOG(@"Player hits moving platform from below!");
			b2Vec2 current = platform.body->GetLinearVelocity();
			if (current.y < 0) {
				[platform changeDirection];
			}
			
		} else if (player.position.x + player.size.width*(1.0f-player.anchorPoint.x) - ADJUSTMENT_COLLISION_X <= platform.position.x - platform.size.width/2.0f) {
			//CCLOG(@"Player hits moving platform from left!");
			b2Vec2 current = platform.body->GetLinearVelocity();
			if (current.x < 0) {
				[platform changeDirection];
			}
			
		} else if (player.position.x - player.size.width*player.anchorPoint.x + ADJUSTMENT_COLLISION_X >= platform.position.x + platform.size.width/2.0f) {
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
		
		Enemy *enemy = (Enemy *)o1;
		[enemy resetForces];
		
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
		
		if (player.position.y - player.size.height*player.anchorPoint.y < tile.position.y + tile.size.height/2.0f) {
			contact->SetEnabled(false);
			
		} else {
			//CCLOG(@"Check if floor (presolve): %f , %f", player.position.y - player.size.height*player.anchorPoint.y, tile.position.y + tile.size.height/2.0f);
			
			if ((player.position.x + player.size.width*(1.0f-player.anchorPoint.x) - ADJUSTMENT_COLLISION_X >= tile.position.x - tile.size.width/2.0f)
				&& (player.position.x - player.size.width*player.anchorPoint.x + ADJUSTMENT_COLLISION_X <= tile.position.x + tile.size.width/2.0f) ) {
				
				b2Vec2 current = player.body->GetLinearVelocity();
				if (current.y < 0) [player hitsFloor];
				
			} else {
				b2Vec2 current = player.body->GetLinearVelocity();
				if (current.y < 0) contact->SetEnabled(false);
			}
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
		
		if (player.position.y + player.size.height*(1.0f-player.anchorPoint.y) >= platform.position.y - platform.size.height/2.0f) {
			if (platform.velocity.x != 0) {
				b2Vec2 vel = platform.body->GetLinearVelocity();
				[player displaceHorizontally:vel.x];
			}
			
		//} else if (player.position.y - player.size.height*player.anchorPoint.y < platform.position.y + platform.size.height/2.0f) {
		//	contact->SetEnabled(false);
		
		}
		
	} else if (ARE_ENEMIES(o1, o2)) {
		//CCLOG(@"-----> Enemy made contact with another enemy!");
		
		Enemy *enemy = (Enemy *)o1;
		[enemy resetForces];
	}
}

void ContactListener::PostSolve(b2Contact *contact, const b2ContactImpulse *impulse) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
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
		
		if (player.position.y - player.size.height*player.anchorPoint.y < tile.position.y + tile.size.height/2.0f) {
			contact->SetEnabled(false);
		}
		
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
		
	}
}

void ContactListener::EndContact(b2Contact *contact) {
	GameObject *o1 = (GameObject*)contact->GetFixtureA()->GetBody()->GetUserData();
	GameObject *o2 = (GameObject*)contact->GetFixtureB()->GetBody()->GetUserData();
	
	if (IS_MOVING_PLATFORM(o1, o2) && IS_PLAYER(o1, o2)) {
		//CCLOG(@"-----> Player contact ended with horizontal platform!");
		
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

		if (o1.type == kGameObjectRobot) {
			[(Robot *)o1 finished:o2];
		} else {
			[(Robot *)o2 finished:o1];
		}
	}
}