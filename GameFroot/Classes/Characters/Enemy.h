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
#import "EnemyBehaviourState.h"

#define ENEMY_BEHAVIOUR_NONE            0
#define ENEMY_BEHAVIOUR_JUMPING         ( 1 << 0 )
#define ENEMY_BEHAVIOUR_WALKING         ( 1 << 1 )
#define ENEMY_BEHAVIOUR_SHOOTING        ( 1 << 2 )

// --------------------------------------------------------------
// SETTING UP EMENY AI

// defines the jump area enemies scan
#define ENEMY_JUMP_UP_LOOKAHEAD         4               // tiles to look ahead for jump up solution
#define ENEMY_JUMP_UP_LOOKUP            3               // tiles to look up for jump up solution
#define ENEMY_JUMP_HORZ_LOOKAHEAD       5               // tiles to look ahead for horizontal jump
#define ENEMY_JUMP_DOWN_LOOKAHEAD       3               // tiles to look ahead for jump down solutions
#define ENEMY_JUMP_DOWN_LOOKDOWN        3               // tiles to look down for ump down solutions

#define ENEMY_JUMP_GAIN                 2.0f           // how powerful jumps are
#define ENEMY_JUMP_DELAY                4.0f            // jump delay after jump ( should be randomized )    
#define ENEMY_INITIAL_WEAPON_DELAY      0               // firing weapon will have an initial delay
#define ENEMY_TRACK_RANGE               300             // how much to expand track range beyond visible screen
#define ENEMY_TRACK_ALWAYS              0               // track even if out of screen

#define ENEMY_BLOCKS_PLAYER             1               // sets if enemies can block player or not
#define ENEMY_WALKING_STOPAHEAD         3               // tiles to stop close to player
#define BOSS_THRESHOLD                  2000            // If the enemies health is greater than this then it is a boss

// --------------------------------------------------------------

@interface Enemy : Player {
	Player *player;
	
	CCSprite *healthBar;
	CCSprite *barLeft;
	CCSprite *barMiddle;
	CCSprite *barRight;
	
	int score;
	NSString *weaponName;
	int multiShot;
	float multiShotDelay;
	int collideTakeDamage;
	int collideGiveDamage;
	int behaviour;
    bool boss;
	
	CGPoint prevPosition;
    NSTimeInterval lastShoot;
    
    ccTime deltaTime;
    CGPoint tilePos;                    // current tile position
    float jumpDelay;                    // idle delay after jump finished
    float shootTimer;
    float jumpTimer;
    
    
    //behaviour states
    NSMutableArray *behaviourCycle;
    EnemyBehaviourState *currentBehaviour;
    int behaviourCyclePosition;
    float behaviourTimer;
    
}

@property (nonatomic,assign) int collideTakeDamage;
@property (nonatomic,assign) int collideGiveDamage;
@property (nonatomic, retain) NSMutableArray *behaviourCycle;

-(void) setupEnemy:(int)_enemyID properties:(NSDictionary *)properties player:(Player *)_player;
-(void) faceRight;
-(void) faceLeft;
-(void) changeDirection;
-(void) restart;
-(void) reverseNPCsAtLedges;
-(void) jumpTimer;
-(BOOL) isFacingPlayer;
@end