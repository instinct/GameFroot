//
//  Robot.h
//  DoubleHappy
//
//  Created by Jose Miguel on 16/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameObject.h"

#define ROBOT_TRACK_RANGE               300             // how much to expand track range beyond visible screen
#define ROBOT_TRACK_ALWAYS              0               // track even if out of screen

@interface Robot : GameObject {
	NSArray *behavior;
    NSDictionary *original;
	NSDictionary *parameters;
    
	int health;
	BOOL facingLeft;
	
	CCArray *msgCommands;
	CCArray *msgName;
	
	BOOL onMessage;
	BOOL onTouchStart;
	BOOL onInShot;
    BOOL onOutShot;
	
	NSArray *onDieCommands;
	
	NSDictionary *tempObject;
	
	CCArray *andToken;
	CCArray *orToken;
	
	float auxX, auxY;
	
	CCArray *timerCommands;
	
	BOOL solid;
	BOOL physics;
	BOOL immortal;
	
	CGPoint walkNode;
	
	NSDictionary *delayedMessage;
	
	CGRect mapRect;
    
    BOOL wasMoving;
    
    BOOL invisible;
    BOOL freezed;
    BOOL sensor;
    BOOL frozen;
    
    NSString *name;
    BOOL paused;
}

@property (nonatomic, assign) BOOL solid;
@property (nonatomic, assign) BOOL physics;
@property (nonatomic, assign) BOOL sensor;
@property (nonatomic, assign) NSDictionary *original;
@property (nonatomic, assign) NSDictionary *parameters;

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size;

-(void) setupRobot:(NSDictionary *)data parameters:(NSDictionary *)params;
-(void) onSpawn;
-(void) update:(ccTime)dt;

-(void) runCommand: (NSDictionary *)command;
-(void) resolve: (int)num;
-(void) execute: (NSString *)eventType type:(GameObjectType)isType;

-(void) receiveMessage:(NSString *)msg;

-(void) touched:(id)sender;
-(void) finished:(id)sender;
-(void) hit:(int)force;

-(void) pause;
-(void) resume;

@end
