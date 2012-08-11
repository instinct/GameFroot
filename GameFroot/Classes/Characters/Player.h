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
#import "SimpleAudioEngine.h"
#import "SimpleAudioEngine+playEffectLoop.h"

enum ANIM { STAND = 0, WALK, CROUCH, PRONE, JUMPING, FALLING };

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
	
    float horizontalSpeed;
	BOOL dying;
	BOOL immortal;
	BOOL paused;
    
	BOOL canJump;
	BOOL jumping;
	BOOL jumpingMoving;
	BOOL moving;
	
	float horizontalSpeedOffset;
	BOOL ignoreGravity;
	BOOL facingLeft;
	
	int lives, initialLives;
	int health, initialHealth;
	int topHealth;
    
	int auxX, auxY;
	CGPoint auxPos;
	
	Switch *touchingSwitch;
    GameObject *interact;
	
	BOOL lose;
	BOOL win;
	
	float shootDelay;
	int shootDamage;
    
    float weaponOffsetX;
    float weaponOffsetY;
	float bulletOffsetX;
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
	
	float scrollOnProne, scrollOnProneMax, scrollOnProneDelay, scrollOnProneDelayCount;
	
	BOOL pressedJump;
    
    BOOL startsWithWeapon;
    BOOL hasWeapon;
    BOOL startsWithJetpack;
    int defaultWeapon;
    int jetpackSoundHandle;
    
    CGPoint safePositon;
    BOOL autoSafepoint;
    
    int debugImmortal;
    
    BOOL touchingSomeone;
    
    BOOL immune;
    
    float fixedXSpeed, fixedYSpeed;
    
    BOOL smokeOn;
    
    float inertia;
    
    BOOL isCustomWeapon;
    CGSize customWeaponSize;
}

@property (nonatomic,assign) int action;
@property (nonatomic, assign) BOOL ignoreGravity;
@property (nonatomic, assign) float shootDelay;
@property (nonatomic,assign) int shootDamage;
@property (nonatomic,assign) BOOL autoSafepoint;
@property (nonatomic,assign) int health;
@property (nonatomic,assign) int initialHealth;
@property (nonatomic,assign) int topHealth;
@property (nonatomic,assign) BOOL immune;
@property (nonatomic,assign) float fixedXSpeed;
@property (nonatomic,assign) float fixedYSpeed;

-(void) setupPlayer:(int)_playerID properties:(NSDictionary *)properties;
-(void) removeWeapon;
-(void) changeWeapon:(int)_weaponID;
-(void) setState:(int) anim;
-(void) jump;
-(void) jumpDirection:(GameObjectDirection)dir;
-(void) resetJump;
-(void) moveRight;
-(void) moveLeft;
-(void) restartMovement;
-(void) resetVerticalSpeed;
-(void) resetHorizontalSpeed;
-(void) stop;
-(void) crouch;
-(void) prone;
-(void) shoot;
-(void) displaySmoke;
-(void) removeSmoke;
-(void) addJetpack;
-(void) removeJetpack;
-(void) increaseHealth:(int)amount;
-(void) decreaseHealth:(int)amount;
-(void) setMaxHealth:(int)amount;
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
-(void) changeToPosition:(CGPoint)pos;
-(void) changeInitialPositionX:(int)dx andY:(int)dy;
-(void) setTouchingSwitch:(Switch *) touchingSwitch_;
-(void) resetForces;
-(BOOL) isBelowCloud:(GameObject *) object;
-(BOOL) isMoonWalking;
-(BOOL) isJumping;

-(void) restart;
-(void) pause;
-(void) resume;

@end

