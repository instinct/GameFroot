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
	
	CGPoint walkNode;
	
	NSDictionary *delayedMessage;
	
	CGRect mapRect;
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size solid:(BOOL)_solid;

-(void) setupRobot:(NSArray *)array;
-(void) update:(ccTime)dt;

-(void) runCommand: (NSDictionary *)command;
-(void) resolve: (int)num;
-(void) execute: (NSString *)eventType type:(GameObjectType)isType;

-(void) receiveMessage:(NSString *)msg;

-(void) touched:(id)sender;
-(void) finished:(id)sender;

@end
