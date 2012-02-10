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
    
    NSTimeInterval lastShoot;
}

@property (nonatomic,assign) int collideTakeDamage;
@property (nonatomic,assign) int collideGiveDamage;

-(void) setupEnemy:(int)_enemyID properties:(NSDictionary *)properties player:(Player *)_player;
-(void) faceRight;
-(void) faceLeft;
-(void) changeDirection;
-(void) restartPosition;

@end