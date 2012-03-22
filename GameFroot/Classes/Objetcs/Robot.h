//
//  Robot.h
//  DoubleHappy
//
//  Created by Jose Miguel on 16/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameObject.h"

#define ROBOT_TRACK_RANGE               0               // how much to expand track range beyond visible screen
#define ROBOT_TRACK_ALWAYS              0               // track even if out of screen

#define TRACE_COMMANDS                  1               // Traces all robot scripts commands on the terminal

enum RobotTouchingType{
    touchingNone,
    touchingFloor,
    touchingWall,
    touchingSomethingLeft,
    touchingSomethingRight,
    touchingSomethingTop
};

@interface Robot : GameObject {
	NSArray *behavior;

	NSDictionary *parameters;
    NSDictionary *originalData;
    
	int health;
	BOOL facingLeft;
	
	CCArray *msgCommands;
	CCArray *msgName;
	
	BOOL onMessage;
	BOOL onTouchStart;
	BOOL onInShot;
    BOOL onOutShot;
	
	NSArray *onDieCommands;
	
	CCArray *timerCommands;
	
	BOOL solid;
	BOOL physics;
	BOOL immortal;
	
	CGPoint walkNode;
	
	CGRect mapRect;
    
    BOOL wasMoving;
    
    BOOL invisible;
    BOOL freezed;
    BOOL sensor;
    BOOL frozen;
    
    NSString *name;
    BOOL paused;
    
    BOOL shooted;
    b2Vec2 shootSpeed;
    
    BOOL touchingPlayer;
    RobotTouchingType touching;
}

@property (nonatomic, assign) BOOL solid;
@property (nonatomic, assign) BOOL physics;
@property (nonatomic, assign) BOOL sensor;
@property (nonatomic, assign) BOOL shooted;
@property (nonatomic, assign) NSDictionary *parameters;
@property (nonatomic, assign) NSDictionary *originalData;

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size;

-(void) setupRobot:(NSDictionary *)properties;
-(void) onSpawn;
-(void) update:(ccTime)dt;

-(void) runCommand: (NSDictionary *)command;
-(void) resolve: (int)num;
-(void) execute: (NSString *)eventType type:(GameObjectType)isType;

-(void) receiveMessage:(NSString *)msg;

-(void) touched:(id)sender;
-(void) finished:(id)sender;
-(void) hit:(int)force;

-(void) shootTo:(b2Vec2)vel;

-(void) pause;
-(void) resume;

@end
