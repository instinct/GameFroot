//
//  Player.h
//  DoubleHappy
//
//  Created by Jose Miguel on 08/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"
#import "Switch.h"

@interface Player : GameObject {
	
	CCAnimation *stand;
	CCAnimation *walk;
	CCAnimation *crouch;
	CCAnimation *prone;
	CCAnimation *jump;
	CCAnimation *die;
	
	CCSpriteBatchNode *weaponSpriteSheet;
	CCSprite *weapon;
	CCAnimation *standWeapon;
	CCAnimation *walkWeapon;
	CCAnimation *crouchWeapon;
	CCAnimation *proneWeapon;
	CCAnimation *jumpWeapon;
	
	int playerID;
	int weaponID;
	GameObjectDirection direction;	
	int action;
	
	int initialX, initialY, originalX, originalY;
	
	BOOL dying;
	BOOL immortal;
	
	BOOL canJump;
	BOOL jumping;
	BOOL jumpingMoving;
	BOOL moving;
	
	float horizontalSpeedOffset;
	BOOL ignoreGravity;
	BOOL facingLeft;
	
	int lives;
	int health;
	
	int auxX, auxY;
	CGPoint auxPos;
	
	Switch *touchingSwitch;
	
	BOOL lose;
	BOOL win;
	
	float shootDelay;
	int shootDamage;
	float bulletOffsetY;
	
	BOOL jetpackCollected;
	BOOL jetpackActivated;
	CCSpriteBatchNode *jetpackSpriteSheet;
	CCSprite *jetpack;
	CCAnimation *standJetpack;
	CCAnimation *walkJetpack;
	CCAnimation *crouchJetpack;
	CCAnimation *proneJetpack;
	CCAnimation *jumpJetpack;
	CCParticleSystem *particle;
	int fuel;
	
	float scrollOnProne, scrollOnProneMax;
	
	BOOL pressedJump;
	
	BOOL helpFall;
}

@property (nonatomic,assign) int action;
@property (nonatomic, assign) BOOL ignoreGravity;
@property (nonatomic, assign) float shootDelay;
@property (nonatomic,assign) int shootDamage;

-(void) setupPlayer:(int)_playerID initialX:(int)dx initialY:(int)dy;
-(void) changeWeapon:(int)_weaponID;
-(void) setState:(int) anim;
-(void) jump;
-(void) jumpDirection:(GameObjectDirection)dir;
-(void) resetJump;
-(void) moveRight;
-(void) moveLeft;
-(void) restartMovement;
-(void) stop;
-(void) crouch;
-(void) prone;
-(void) shoot;
-(void) addJetpack;
-(void) removeJetpack;
-(void) increaseHealth:(int)amount;
-(void) decreaseHealth:(int)amount;
-(void) increaseLive:(int)amount;
-(void) decreaseLive:(int)amount;
-(void) immortal;
-(void) hit:(int)force;
-(void) die;
-(void) lose;
-(void) win;
-(void) hitsFloor;
-(void) displaceHorizontally:(float)speed;
-(void) changePositionX:(int)dx andY:(int)dy;
-(void) changeInitialPositionX:(int)dx andY:(int)dy;
-(void) changeToPosition:(CGPoint)pos;
-(void) setTouchingSwitch:(Switch *) touchingSwitch_;
-(void) resetForces;

-(void) pause;
-(void) resume;

@end

