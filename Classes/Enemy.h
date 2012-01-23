//
//  Enemy.h
//  DoubleHappy
//
//  Created by Jose Miguel on 30/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"
#import "Player.h"

@interface Enemy : Player {
	Player *player;
	
	CCSprite *healthBar;
	CCSprite *barLeft;
	CCSprite *barMiddle;
	CCSprite *barRight;
	
	int topHealth;
	
	int score;
	NSString *weaponName;
	int shotDelay;
	int speed;
	int multiShot;
	int multiShotDelay;
	int collideTakeDamage;
	int collideGiveDamage;
	int behaviour;
	
	CGPoint prevPosition;
}

@property (nonatomic,assign) int score;
@property (nonatomic,assign) NSString *weaponName;
@property (nonatomic,assign) int shotDelay;
@property (nonatomic,assign) int speed;
@property (nonatomic,assign) int multiShot;
@property (nonatomic,assign) int multiShotDelay;
@property (nonatomic,assign) int collideTakeDamage;
@property (nonatomic,assign) int collideGiveDamage;
@property (nonatomic,assign) int behaviour;

-(void) setupEnemy:(int)_enemyID initialX:(int)dx initialY:(int)dy health:(int)_health player:(Player *)_player;
-(void) faceRight;
-(void) faceLeft;
-(void) changeDirection;
-(void) restartPosition;

@end