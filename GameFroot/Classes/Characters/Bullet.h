//
//  Bullet.h
//  DoubleHappy
//
//  Created by Derek Doucett on 11-01-24.
//  Copyright 2011 Ravenous Games. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"
#import "SimpleAudioEngine.h"

@interface Bullet : GameObject
{
	CCSpriteBatchNode *spriteSheet;
	GameObjectDirection direction;
	
	float spriteWidth;
	float spriteHeight;
	
	CCAnimation *left;
	CCAnimation *right;
	CCAnimation *explosion;
	
	BOOL removing;
	int damage;
	int weapon;
	
	int numFrames;
	int numFramesExplosion;
}

@property (nonatomic,assign) CCSpriteBatchNode *spriteSheet;
@property (nonatomic,assign) int damage;
@property (nonatomic,assign) BOOL removing;

+(Bullet *)bullet:(GameObjectDirection)dir weapon:(int)_weapon;
-(void) initWithDirection:(GameObjectDirection)dir weapon:(int)_weapon;

-(void) createBox2dObject:(b2World*)world;
-(void) setAngle:(float)angle;
-(void) die;

@end
