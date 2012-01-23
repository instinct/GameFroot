//
//  Robot.h
//  DoubleHappy
//
//  Created by Jose Miguel on 16/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GameObject.h"

@interface Robot : GameObject {
	NSArray *behavior;
	
	int health;
	BOOL facingLeft;
	
	CCArray *msgCommands;
	CCArray *msgName;
	
	BOOL onMessage;
	BOOL onTouchStart;
	BOOL onInShot;
	
	NSArray *onDieCommands;
	
	NSDictionary *tempObject;
	
	CCArray *andToken;
	CCArray *orToken;
	
	float auxX, auxY;
	
	CCArray *timerCommands;
	
	BOOL solid;
	BOOL ignoreGravity;
	BOOL immortal;
	
	CGPoint walkNode;
	
	NSDictionary *delayedMessage;
	
	CGRect mapRect;
}

@property (nonatomic, assign) BOOL solid;
@property (nonatomic, assign) BOOL ignoreGravity;

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size;

-(void) setupRobot:(NSDictionary *)data;
-(void) update:(ccTime)dt;

-(void) runCommand: (NSDictionary *)command;
-(void) resolve: (int)num;
-(void) execute: (NSString *)eventType type:(GameObjectType)isType;

-(void) receiveMessage:(NSString *)msg;

-(void) touched:(id)sender;
-(void) finished:(id)sender;
-(void) hit:(int)force;

@end
