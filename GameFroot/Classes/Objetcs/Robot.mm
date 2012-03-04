//
//  Robot.m
//  DoubleHappy
//
//  Created by Jose Miguel on 16/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Robot.h"
#import "CJSONDeserializer.h"
#import "GameLayer.h"
#import "Bullet.h"
#import "SimpleAudioEngine.h"
#include <objc/runtime.h>

#define FLASH_VELOCITY_FACTOR	50.0f
#define DELAY_FACTOR			1000.0f

void runDelayedMessage(id self, SEL _cmd, id selector, NSDictionary *command)
{
	//[self messageSelf:command];
    [self performSelector:@selector(messageSelf:) withObject:command];
}

@implementation Robot

@synthesize solid;
@synthesize physics;
@synthesize sensor;

- (id) init
{
    self = [super init];
    if (self) {
        type = kGameObjectRobot;
    }
    
    return self;
}

-(void) _recreateBody
{
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = true;
	playerBodyDef.fixedRotation = true;
	
	// Try to use dynamic bodies, but ignoring gravity
	//playerBodyDef.type = b2_kinematicBody;
    if (!physics && solid) playerBodyDef.type = b2_staticBody;
    else playerBodyDef.type = b2_dynamicBody;
	
	playerBodyDef.position.Set(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO);
	playerBodyDef.userData = self;
	body = [GameLayer getInstance].world->CreateBody(&playerBodyDef);
	
	if (!physics) body->SetGravityScale(0.0f);
	
    sensor = [name isEqualToString:@"Teleporter"] || [name isEqualToString:@"Story-Point"] || !solid;
	
    b2PolygonShape shape;
    shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0)/PTM_RATIO);
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 1.0;
    fixtureDef.friction = 0.0;
    fixtureDef.restitution = 0.0; // bouncing
    fixtureDef.isSensor = sensor;
    body->CreateFixture(&fixtureDef);
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	size = _size;
	
	[self _recreateBody];
	
	removed = NO;
}

-(void) setupRobot:(NSDictionary *)data parameters:(NSDictionary *)params
{
	//CCLOG(@"Robot.setupRobot: %@", data);
	//CCLOG(@"Robot.setupRobot (parameters): %@", params);
    
    original = [data retain];
    parameters = [params retain];
    
	// default values
	health = 100;	
	solid = NO;
	physics = YES;
	immortal = NO;
    invisible = NO;
    freezed = NO;
	sensor = NO;
    frozen = NO;
    
	if ([data objectForKey:@"behavior"]) {
		behavior = [[data objectForKey:@"behavior"] retain];
	} else {
		behavior = [[NSArray array] retain];
	}
	
	if ([data objectForKey:@"properties"]) {
		health = [[[data objectForKey:@"properties"] objectForKey:@"health"] intValue];
		immortal = [[[data objectForKey:@"properties"] objectForKey:@"immortal"] boolValue];
		
        //Solid? (Can other things not travel through me?)
        solid = [[[data objectForKey:@"properties"] objectForKey:@"solid"] boolValue];
        
        //Physics? (Can I be moved by other things?)
		physics = [[[data objectForKey:@"properties"] objectForKey:@"physics"] boolValue];
        
        // Special atention to Story-Point and Teleporter, make them sensors and smaller hit area
		name = [[[data objectForKey:@"properties"] objectForKey:@"name"] retain];
         
		//CCLOG(@"Robot.immortal: %i", immortal);
		//CCLOG(@"Robot.solid: %i", solid);
		//CCLOG(@"Robot.physics: %i", physics);
	}
    
	facingLeft = YES;
	onMessage = NO;
	onTouchStart = NO;
	onInShot = NO;
    onOutShot = NO;
	walkNode = CGPointZero;
	
	msgCommands = [[CCArray array] retain];
	msgName = [[CCArray array] retain];
	
	andToken = [[CCArray array] retain];
	orToken = [[CCArray array] retain];
	
	timerCommands = [[CCArray array] retain];
	
	mapRect = CGRectMake(0,0,[GameLayer getInstance].mapWidth*MAP_TILE_WIDTH,[GameLayer getInstance].mapHeight*MAP_TILE_HEIGHT);
    
    int totalEvents = [behavior count];
	for (int i=0; i<totalEvents; i++) {
		NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:i];
		//CCLOG(@"%@", event);
		
		NSString *nameEvent = [event objectForKey:@"event"];
		
		if ([nameEvent isEqualToString:@"onMessage"]) {
			[msgName addObject:[event objectForKey:@"messageName"]];
			[msgCommands addObject:[event objectForKey:@"commands"]];
            
            SEL sel = sel_registerName([[NSString stringWithFormat:@"%@:command:", [event objectForKey:@"messageName"]] UTF8String]);
            class_addMethod([self class], sel, (IMP)runDelayedMessage, "v@:@@");
			
		} else if ([nameEvent isEqualToString:@"onDie"]) {
			onDieCommands = [event objectForKey:@"commands"];
			
		}
	}
}

-(void) onSpawn
{
    int totalEvents = [behavior count];
	for (int i=0; i<totalEvents; i++) {
		NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:i];
		//CCLOG(@"%@", event);
		
		NSString *nameEvent = [event objectForKey:@"event"];
		
		if ([nameEvent isEqualToString:@"onSpawn"]) {
			[self resolve:i];
        }
    }    
}

-(void) inShot
{
    int totalEvents = [behavior count];
    for (int i=0; i<totalEvents; i++) {
        NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:i];
        //CCLOG(@"%@", event);
        
        NSString *nameEvent = [event objectForKey:@"event"];
        
        if ([nameEvent isEqualToString:@"onInShot"]) {
            [self resolve:i];
        }
        
        onInShot = YES;
        onOutShot = NO;
    }
}

-(void) outShot
{
    int totalEvents = [behavior count];
    for (int i=0; i<totalEvents; i++) {
        NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:i];
        //CCLOG(@"%@", event);
        
        NSString *nameEvent = [event objectForKey:@"event"];
        
        if ([nameEvent isEqualToString:@"onOutShot"]) {
            [self resolve:i];
        }
        
        onOutShot = YES;
        onInShot = NO;
    }
}

-( BOOL )isInsideScreen:( CGPoint )pos {
#if ROBOT_TRACK_ALWAYS == 1
    return( YES );
#else
    CGSize winSize = [ [ CCDirector sharedDirector ] winSize ];
    CGRect rect;
    
    rect = CGRectMake( -self.contentSize.width - ROBOT_TRACK_RANGE, 
                      -self.contentSize.height - ROBOT_TRACK_RANGE,
                      winSize.width + ( self.contentSize.width * 2 ) + ( ROBOT_TRACK_RANGE * 2 ),
                      winSize.height + ( self.contentSize.height * 2 ) + ( ROBOT_TRACK_RANGE * 2 ) );
    return( CGRectContainsPoint( rect , pos ) );
#endif
}

-(void) update:(ccTime)dt
{
	if (removed) return;
	
	CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:self.position];
	
	//if (!CGRectContainsPoint(mapRect, self.position)) {
	//	[self remove];
	//}
    
    if (freezed && (body->IsActive())) body->SetActive(NO);
    else if (!freezed && (!body->IsActive())) body->SetActive(YES);
    
    //CCLOG(@"Robot.position: %f,%f", self.position.x, self.position.y);
    
	if ( [ self isInsideScreen:pos ] == NO ) {
        if (self.visible) {
			self.visible = NO;
            body->SetActive( false );
			onInShot = NO;
		}
        
        if (!onOutShot) [self outShot];
        
	} else {
		if (!self.visible) {
            if (!invisible) self.visible = YES;
            body->SetActive( true );
        }
		
		if (!onInShot) [self inShot];
	}

	//if (walkNode != CGPointZero) {
    // TODO: walk node to position
	//}
	
	b2Vec2 current = body->GetLinearVelocity();
	if (current.x > 0) {
		facingLeft = NO;
		
	} else if (current.x < 0) {
		facingLeft = YES;
	}
	
	[super update:dt];
}

-(id) runMethod:(NSString *)nameMethod withObject:(id)anObject
{
	NSString *method;
	
	if (anObject != nil) method = [NSString stringWithFormat:@"%@:", nameMethod];
	else method = nameMethod;
	
	SEL selector = NSSelectorFromString(method);
	if ([self respondsToSelector:selector]) {
		
		id result;
		if (anObject != nil) result = [self performSelector:selector withObject:anObject];
		else result = [self performSelector:selector];
		
		//CCLOG(@"Robot: calling selector: %@ with parameter: %@ and result: %@", method, anObject, result);
		//CCLOG(@"Robot: calling selector: %@ with parameter: %@", method, anObject);
		return result;
		
	} else {
		CCLOG(@"Robot: undeclared selector: %@", method);
		return nil;
	}
}

-(void) runCommand: (NSDictionary *)command
{
	
	//Run the first command within the list:
	NSString *action = [command objectForKey:@"action"];
	
	//this is required since if is a reserved keyword!
	if ([action isEqualToString:@"if"])
		action = @"conditionIf";
	
	[andToken removeAllObjects];
	
	tempObject = command;
	
	[self runMethod:action withObject:command];
	
}

-(void) resolve: (int)num
{
		
	NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:num];
	NSArray *commands = [event objectForKey:@"commands"];
	int totalCommands = [commands count];

	int n = 0;
	while(n < totalCommands){
		NSDictionary *command = (NSDictionary *)[commands objectAtIndex:n];
		[self runCommand:command];
		n++;
	}
}

-(void) execute: (NSString *)eventType type:(GameObjectType)isType
{
	
	int l = 0;
	int totalEvents = [behavior count];
		
	while (l < totalEvents) {
		NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:l];
		NSString *nameEvent = [event objectForKey:@"event"];
		
		if ([nameEvent isEqualToString:eventType]) {
			
			if (![nameEvent isEqualToString:@"onTouchStart"]) {
				[self resolve:l];
				
			} else {
				NSDictionary *instance = [event objectForKey:@"instance"];
				NSString *token = [instance objectForKey:@"token"];
				
				if ([token isEqualToString:@"player"]) {
					if (isType == kGameObjectPlayer) {
						[self resolve:l];
					}
				}
			}
			
		}
		l++;
	}
}

#pragma mark -
#pragma mark Functions

-(void) conditionIf:(NSDictionary *)command
{
	NSDictionary *condition = [command objectForKey:@"condition"];
	NSString *token = [condition objectForKey:@"token"];
	
	if ([[self runMethod:token withObject:condition] boolValue]) {
		
		NSArray *onTrue = [command objectForKey:@"onTrue"];
		for (uint i = 0; i < [onTrue count]; i++){
			NSDictionary *action = (NSDictionary *)[onTrue objectAtIndex:i];
			NSString *actionTrue = [action objectForKey:@"action"];
			
			tempObject = action;
			
			[self runMethod:actionTrue withObject:action];
		}
	}  
}

-(void) ifElse:(NSDictionary *)command
{
	NSDictionary *condition = [command objectForKey:@"condition"];
	NSString *token = [condition objectForKey:@"token"];

	if ([[self runMethod:token withObject:condition] boolValue]) {
		
		NSArray *onTrue = [command objectForKey:@"onTrue"];
		for (uint i = 0; i < [onTrue count]; i++){
			NSDictionary *action = (NSDictionary *)[onTrue objectAtIndex:i];
			NSString *actionTrue = [action objectForKey:@"action"];
			
			tempObject = action;
			
			[self runMethod:actionTrue withObject:action];
		}
		
	} else {
		
		NSArray *onFalse = [command objectForKey:@"onFalse"];
		for (uint i = 0; i < [onFalse count]; i++){
			NSDictionary *action = (NSDictionary *)[onFalse objectAtIndex:i];
			NSString *actionTrue = [action objectForKey:@"action"];
			
			tempObject = action;
			
			[self runMethod:actionTrue withObject:action];
		}
		
	}
}

-(NSNumber *) opBooleanAnd: (NSDictionary *)command
{
	NSDictionary *operand1 = [command objectForKey:@"operand1"];
	NSDictionary *operand2 = [command objectForKey:@"operand2"];
	
	NSString *token1 = [operand1 objectForKey:@"token"];
	NSString *token2 = [operand2 objectForKey:@"token"];
	
	BOOL op1 = [[self runMethod:token1 withObject:operand1] boolValue];
	BOOL op2 = [[self runMethod:token2 withObject:operand2] boolValue];
	
	if (op1 && op2)
		return [NSNumber numberWithBool:YES];
	else
		return [NSNumber numberWithBool:NO];
}

-(NSNumber *) opBooleanOr: (NSDictionary *)command
{
	NSDictionary *operand1 = [command objectForKey:@"operand1"];
	NSDictionary *operand2 = [command objectForKey:@"operand2"];
	
	NSString *token1 = [operand1 objectForKey:@"token"];
	NSString *token2 = [operand2 objectForKey:@"token"];
	
	BOOL op1 = [[self runMethod:token1 withObject:operand1] boolValue];
	BOOL op2 = [[self runMethod:token2 withObject:operand2] boolValue];
	
	if (op1 || op2)
		return [NSNumber numberWithBool:YES];
	else
		return [NSNumber numberWithBool:NO];
}

-(NSNumber *) opBooleanNot: (NSDictionary *)command
{
	NSDictionary *operand1 = [command objectForKey:@"operand1"];
	
	NSString *token1 = [operand1 objectForKey:@"token"];
	
	BOOL op1 = [[self runMethod:token1 withObject:operand1] boolValue];
	
    return [NSNumber numberWithBool:!op1];
}

-(BOOL) isSolid:(id)obj
{
	return solid;
}

-(BOOL) beNotSolid:(id)obj
{
	solid = NO;
	
    [self scheduleOnce:@selector(_changeBody) delay:1.0/60.0];
    
	return solid;
}

-(BOOL) beSolid:(id)obj
{
	solid = YES;
	
	[self scheduleOnce:@selector(_changeBody) delay:1.0/60.0];
	
	return solid;
}

-(void) _changeBody
{
	[GameLayer getInstance].world->DestroyBody(body);
	
	[self _recreateBody];
}

-(void) say:(id)obj
{
    //CCLOG(@"Robot.say: %@", obj);
    if ([[obj objectForKey:@"words"] isKindOfClass:[NSDictionary class]]) {
        NSString *token = [[obj objectForKey:@"words"] objectForKey:@"token"];
		NSString *msg = [self runMethod:token withObject:[obj objectForKey:@"words"]];
        [[GameLayer getInstance] say:msg];
        
    } else  if ([[obj objectForKey:@"words"] isKindOfClass:[NSString class]]) {
        [[GameLayer getInstance] say:[obj objectForKey:@"words"]];
    }
}

-(void) think:(id)obj
{
    //CCLOG(@"Robot.think: %@", obj);
    [self say:obj];
}

-(void) sayInChatPanel:(id)obj
{
    //CCLOG(@"Robot.sayInChatPanel: %@", obj);
    [self say:obj];
}

-(void) askMultichoice:(NSDictionary *)command
{
    //CCLOG(@"Robot.askMultichoice: %@", command);
    [[GameLayer getInstance] askMultichoice:command robot:self];
}

-(void) gotoLevel:(NSDictionary *)command
{
    //CCLOG(@"Robot.gotoLevel: %@", command);
    int gameID = [[command objectForKey:@"level"] intValue];
    [[GameLayer getInstance] loadNextLevel:gameID];
}

-(void) completeLevelAndGoto:(NSDictionary *)command
{
    //CCLOG(@"Robot.completeLevelAndGoto: %@", command);
    int gameID = [[command objectForKey:@"level"] intValue];
    [[GameLayer getInstance] completeAndLoadNextLevel:(int)gameID withTitle:[command objectForKey:@"text"]];
}

-(void) endGameSuccess:(NSDictionary *)command
{
    //CCLOG(@"Robot.endGameSuccess: %@", command);
    [[GameLayer getInstance] winGameWithText:[command objectForKey:@"text"]];
}

-(void) endGameFailure:(NSDictionary *)command
{
    //CCLOG(@"Robot.endGameFailure: %@", command);
    [[GameLayer getInstance] loseGameWithText:[command objectForKey:@"text"]];
}

-(NSNumber *) isVisible:(id)obj
{
	return [NSNumber numberWithBool:!invisible];
}

-(NSNumber *) goVisible:(id)obj
{
	self.visible = YES;
    invisible = NO;
	return [NSNumber numberWithBool:!invisible];
}

-(NSNumber *) goInvisible:(id)obj
{
	self.visible = NO;
    invisible = YES;
	return [NSNumber numberWithBool:!invisible];
}

-(NSNumber *) facingLeft:(id)obj
{
	return [NSNumber numberWithBool:facingLeft];
}

-(NSNumber *) facingRight:(id)obj
{
	return [NSNumber numberWithBool:!facingLeft];
}

-(void) faceObject:(NSDictionary *)command
{
	NSString *token = [[command objectForKey:@"objinstance"] objectForKey:@"token"];
	if ([token isEqualToString:@"player"]) {
		CGPoint pos = [[GameLayer getInstance] playerPosition];
		if (pos.x > self.position.x) {
			
			self.scaleX = 1;
			facingLeft = NO;
			
		} else {
			self.scaleX = -1;
			facingLeft = YES;
		}
	}
	
}

-(void) repeatCount:(NSDictionary *)command
{
	int count = [[command objectForKey:@"count"] intValue];
	timerCommands = [command objectForKey:@"repeatedActions"];
	
	id action = [CCSequence actions:
					[CCRepeat actionWithAction:
					 [CCCallFunc actionWithTarget:self selector:@selector(_timeDelay)]
					times: count],
					nil];
		
	[self runAction:action];
	
}

-(void) _timeDelay
{
	for (uint i = 0; i < [timerCommands count]; i++){
		NSDictionary *command = (NSDictionary *)[timerCommands objectAtIndex:i];
		NSString *action = [command objectForKey:@"action"];
		
		id condition = [command objectForKey:@"condition"];
		id amount = [command objectForKey:@"amount"];
		id message = [command objectForKey:@"message"];
		id count = [command objectForKey:@"count"];
		id question = [command objectForKey:@"question"];
		
		if ((command != nil) || (condition != nil) || (amount != nil) || (message != nil) || (count != nil)|| (question != nil) ) {
			[self runMethod:action withObject:command];
			
		} else {
			[self runMethod:action withObject:nil];
		}
		
		
	}
}

-(NSNumber *) coordinateXOfNode:(NSDictionary *)command 
{
    //CCLOG(@"Robot.coordinateXOfNode: %@", command);
    
    NSDictionary *node = [command objectForKey:@"node"];
    NSMutableArray *position = [self runMethod:[node objectForKey:@"token"] withObject:node];
    
    float x = [[position objectAtIndex:0] floatValue];
    
    //CCLOG(@"Robot.coordinateXOfNode: %f", x);
    return [NSNumber numberWithFloat:x];
}

-(NSNumber *) coordinateYOfNode:(NSDictionary *)command 
{
    //CCLOG(@"Robot.coordinateYOfNode: %@", command);
    
    NSDictionary *node = [command objectForKey:@"node"];
    NSMutableArray *position = [self runMethod:[node objectForKey:@"token"] withObject:node];
    
    float y = [[position objectAtIndex:1] floatValue];
    
    //CCLOG(@"Robot.coordinateYOfNode: %f", y);
    return [NSNumber numberWithFloat:y];
}

-(NSMutableArray *) thisLocation:(NSDictionary *)obj
{
    CGPoint position = [[GameLayer getInstance] convertToMapCoordinates:self.position];
     
	NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
	[pos addObject:[NSNumber numberWithFloat:position.x]];
	[pos addObject:[NSNumber numberWithFloat:position.y]];
    
	return pos;
}

-(NSMutableArray *) adjustNodeByCoords:(NSDictionary *)obj 
{
	NSDictionary *location = [obj objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
	NSMutableArray *node = [self runMethod:token withObject:location];
	
	float x = [[node objectAtIndex:0] floatValue];
	float y = [[node objectAtIndex:1] floatValue];
	
	if ([[obj objectForKey:@"xMod"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"xMod"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"xMod"]];
		x += [num floatValue];
		
	} else {
		x += [[obj objectForKey:@"xMod"] floatValue];
	}
	
	if ([[obj objectForKey:@"yMod"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"yMod"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"yMod"]];
		y -= [num floatValue];
		
	} else {
		y -= [[obj objectForKey:@"yMod"] floatValue];
	}		
	
	//node.y += int(obj.yMod) * -1;
	
	NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
	[pos addObject:[NSNumber numberWithFloat:x]];
	[pos addObject:[NSNumber numberWithFloat:y]];
	
	return pos;
}

-(NSNumber *) randomNumberRange:(NSDictionary *)obj
{	
	int high = [[obj objectForKey:@"max"] intValue];
	int low = [[obj objectForKey:@"min"] intValue];

	if (high == low) return [NSNumber numberWithFloat:(float)high];
	else return [NSNumber numberWithFloat:(float)(arc4random()%high) + low];
}

-(NSMutableArray *) locationOfInstance:(NSDictionary *)obj 
{
    //CCLOG(@"Robot.locationOfInstance: %@", obj);
    
	NSDictionary *instance = [obj objectForKey:@"instance"];
	NSString *token = [instance objectForKey:@"token"];
	
	if ([token isEqualToString:@"player"]) {
		CGPoint position = [[GameLayer getInstance] convertToMapCoordinates:[[GameLayer getInstance] playerPosition]];
        
        NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
        [pos addObject:[NSNumber numberWithFloat:position.x]];
        [pos addObject:[NSNumber numberWithFloat:position.y]];
        
		return pos;
        
	} else {
        NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
        [pos addObject:[NSNumber numberWithFloat:0]];
        [pos addObject:[NSNumber numberWithFloat:0]];
        
		return pos;
	}
}

-(void) changeScore:(NSDictionary *)command
{
	int amount = [[command objectForKey:@"amount"] intValue];
	[[GameLayer getInstance] increasePoints:amount];
}

-(void) die:(NSDictionary *)command 
{
	for (uint i = 0; i < [onDieCommands count]; i++) {
		[self runCommand:[onDieCommands objectAtIndex:i]];
	}
	
    NSString *permanent;
    if ((permanent = [parameters objectForKey:@"permanent"]) == nil) permanent = @"0";
    BOOL isPermanent = [permanent intValue] == 1;
    
    //CCLOG(@"Robot.die: %i", isPermanent);
    
	if (!isPermanent) [self remove];
}

-(NSNumber *) changeHealth:(NSDictionary *)command 
{
	int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		amount = [num intValue];
		
	} else {
		amount = [[command objectForKey:@"amount"] intValue];
	}
	
	if (amount < 0) {
		int changeAmount = amount * -1;
		health -= changeAmount;
		
	} else {
		health += amount;
	}		

	if ((health < 0) && (!immortal)) [self die:nil];
	
	return [NSNumber numberWithInt:health];
}

-(void) inflictDamage:(NSDictionary *)command 
{
	int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		 amount = [num intValue];
		
	} else {
		 amount = [[command objectForKey:@"amount"] intValue];
	}
	
	NSString *token = [[command objectForKey:@"instance"] objectForKey:@"token"];
	if ([token isEqualToString:@"player"]) {
		if (amount < 0) {
			[[GameLayer getInstance] decreaseHealth:amount];
			
		} else {
			[[GameLayer getInstance] increaseHealth:amount];
		}
	}
}

-(void) changeLives:(NSDictionary *)command 
{
	int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
        amount = [num intValue];
		
	} else {
        amount = [[command objectForKey:@"amount"] intValue];
	}
    
    if (amount < 0){
        int changeAmount = amount*-1;
        [[GameLayer getInstance] decreaseLive:changeAmount];
        
    } else {
        [[GameLayer getInstance] increaseLive:amount];
    }
}

-(void) timeStart:(id)obj
{
    //CCLOG(@"Robot.timeStart");
    [[GameLayer getInstance] enableTimer];
}

-(void) timePause:(id)obj
{
    //CCLOG(@"Robot.timePause");
    [[GameLayer getInstance] pauseTimer];
}

-(void) timeStop:(id)obj
{
    [[GameLayer getInstance] disableTimer];
}

-(void) setTime:(NSDictionary *)command 
{
    //CCLOG(@"Robot.setTime: %@", command);
    int time;
	
	if ([[command objectForKey:@"time"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"time"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"time"]];
        time = [num intValue];
		
	} else {
        time = [[command objectForKey:@"time"] intValue];
	}
    
    [[GameLayer getInstance] setTime:time]; 
}
    
-(void) changeTime:(NSDictionary *)command 
{
    int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
        amount = [num intValue];
		
	} else {
        amount = [[command objectForKey:@"amount"] intValue];
	}
    
	[[GameLayer getInstance] setTime:amount];
}

-(void) triggerCheckpoint:(NSDictionary *)command 
{
    //CCLOG(@"Robot.triggerCheckpoint: %@", command);
    CGPoint mapPos = [self getTilePosition];
    [[GameLayer getInstance] changeInitialPlayerPositionToX:mapPos.x andY:mapPos.y];
}

-(void) teleport:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
    id result = [self runMethod:token withObject:location];
    BOOL found = NO;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *position = (NSDictionary *)result;
        auxX = [[position objectForKey:@"xpos"] floatValue];
        auxY = [[position objectForKey:@"ypos"] floatValue];
        found = YES;
        
	} else if ([result isKindOfClass:[NSArray class]]) {
        NSArray *position = (NSArray *)result;
        auxX = [[position objectAtIndex:0] floatValue];
        auxY = [[position objectAtIndex:1] floatValue];
        found = YES;
    }
         
    if (found) {        
        [self scheduleOnce:@selector(_changeToPosition) delay:1.0/60.0];
    }
}

-(void) teleportInstance:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
    id result = [self runMethod:token withObject:location];
    BOOL found = NO;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *position = (NSDictionary *)result;
        auxX = [[position objectForKey:@"xpos"] floatValue];
        auxY = [[position objectForKey:@"ypos"] floatValue];
        found = YES;
        
	} else if ([result isKindOfClass:[NSArray class]]) {
        NSArray *position = (NSArray *)result;
        auxX = [[position objectAtIndex:0] floatValue];
        auxY = [[position objectAtIndex:1] floatValue];
        found = YES;
    }
    
    if (found) {
	
        if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
            [self scheduleOnce:@selector(_changePlayerPosition) delay:1.0/60.0];
        }
    }
}

-(void) _changePosition
{
	CGPoint pos = ccp(auxX, auxY);
	body->SetTransform(b2Vec2(((pos.x - 30)/PTM_RATIO), (pos.y + 0)/PTM_RATIO),0);
	
	self.position = pos;
}

-(void) _changePlayerPosition
{
    [[GameLayer getInstance] transportPlayerToX:auxX andY:auxY];
}

-(void) walkToNode:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
	NSMutableArray *node = [self runMethod:token withObject:location];
	
	float x = [[node objectAtIndex:0] floatValue];
	float y = [[node objectAtIndex:1] floatValue];
	
	walkNode = ccp(x,y);
}

-(void) setWalkSpeed:(NSDictionary *)command 
{
	float speed;
	
	if ([[command objectForKey:@"speed"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"speed"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"speed"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"speed"] floatValue];
	}
	
	b2Vec2 current = body->GetLinearVelocity();
	b2Vec2 velocity = b2Vec2(speed / FLASH_VELOCITY_FACTOR, current.y);
	body->SetLinearVelocity(velocity);
    wasMoving = YES;
}

-(void) setXvelocity:(NSDictionary *)command 
{
	float speed;
	
	if ([[command objectForKey:@"velocity"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"velocity"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"velocity"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"velocity"] floatValue];
	}
	
	b2Vec2 current = body->GetLinearVelocity();
	b2Vec2 velocity = b2Vec2(speed / FLASH_VELOCITY_FACTOR, current.y);
	body->SetLinearVelocity(velocity);
    wasMoving = YES;
}

-(void) setYvelocity:(NSDictionary *)command 
{
	float speed;
	
	if ([[command objectForKey:@"velocity"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"velocity"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"velocity"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"velocity"] floatValue];
	}
	
	b2Vec2 current = body->GetLinearVelocity();
	b2Vec2 velocity = b2Vec2(current.x, -speed / FLASH_VELOCITY_FACTOR);
	body->SetLinearVelocity(velocity);
    wasMoving = YES;
}

-(void) changeXvelocity:(NSDictionary *)command 
{
    //CCLOG(@"Robot.changeXvelocity: %@", command);
	float speed;
	
	if ([[command objectForKey:@"delta"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delta"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"velocity"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"delta"] floatValue];
	}
	
    b2Vec2 current = body->GetLinearVelocity();
    //CCLOG(@"Robot.changeXvelocity: %f to %f", current.x, current.x - speed / FLASH_VELOCITY_FACTOR);
	
	b2Vec2 velocity = b2Vec2(current.x + speed / FLASH_VELOCITY_FACTOR, current.y);
	body->SetLinearVelocity(velocity);
    wasMoving = YES;
}

-(void) changeYvelocity:(NSDictionary *)command 
{
    //CCLOG(@"Robot.changeYvelocity: %@", command);
	float speed;
	
	if ([[command objectForKey:@"delta"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delta"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"velocity"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"delta"] floatValue];
	}
	
	b2Vec2 current = body->GetLinearVelocity();
    //CCLOG(@"Robot.changeYvelocity: %f to %f", current.y, current.y - speed / FLASH_VELOCITY_FACTOR);
    
	b2Vec2 velocity = b2Vec2(current.x, current.y + speed / FLASH_VELOCITY_FACTOR);
	body->SetLinearVelocity(velocity);
    wasMoving = YES;
}

-(NSNumber *) xVelocity:(id)obj 
{
	b2Vec2 current = body->GetLinearVelocity();
	return [NSNumber numberWithFloat:current.x * FLASH_VELOCITY_FACTOR];
}

-(NSNumber *) yVelocity:(id)obj 
{
	b2Vec2 current = body->GetLinearVelocity();
	return [NSNumber numberWithFloat:-current.y * FLASH_VELOCITY_FACTOR];
}

-(void) spawnNewObject:(NSDictionary *)command 
{
	//TODO:
	/*
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
	NSMutableArray *node = [self runMethod:token withObject:location];
	
	float x = [[node objectAtIndex:0] floatValue];
	float y = [[node objectAtIndex:1] floatValue];
	*/
	
	/*
	var pos:Point = this[command.location.token](command.location);
	
	var content:Object = this.obj; 
	content.xpos = pos.x/48;
	content.ypos = pos.y/48;
	
	if(command.objclass.token == "thisType"){
		play_state.spawnNewObject(content,pos,"robot",this.Solid); 
		
	}
	*/
}

-(void) shootNewObject:(NSDictionary *)command 
{
	//TODO: pending
}

-(NSNumber *) isFalling:(id)obj
{
	b2Vec2 current = body->GetLinearVelocity();
	return [NSNumber numberWithBool:current.y < 0];
}

-(void) freezePlayer:(id)obj
{
    body->SetLinearVelocity(b2Vec2(0,0));
    body->SetAngularVelocity(0);
    
    freezed = YES;
    wasMoving = NO;
}

-(void) unfreezePlayer:(id)obj
{
    freezed = NO;
}

-(void) freezePhysics:(id)obj
{
    //TODO: pending
    frozen = YES;
}

-(void) unfreezePhysics:(id)obj
{
    //TODO: pending
    frozen = NO;
}

-(NSNumber *) isPhysicsFrozen:(id)obj
{
    return [NSNumber numberWithBool:frozen];
}

-(void) freezeLevelPhysics:(id)obj
{
    //TODO: pending
}

-(void) unfreezeLevelPhysics:(id)obj
{
    //TODO: pending
}

-(NSNumber *) isLevelPhysicsFrozen:(id)obj
{
    //TODO: pending
    return [NSNumber numberWithBool:frozen];
}

-(void) playAnimationOnce:(NSDictionary *)command
{
	//TODO: pending
    
    //CCLOG(@"Robot.playAnimationOnce: %@", command);
    [self receiveMessage:[command objectForKey:@"message"]];
}

-(void) switchAnimation:(NSDictionary *)command
{
    //TODO: pending
}

-(void) receiveMessage:(NSString *)msg
{
	//if (onMessage) {
		for (uint i = 0; i < [msgName count]; i++) {
		
			if ([[msgName objectAtIndex:i] isEqualToString:msg]) {
				
				NSArray *commands = [msgCommands objectAtIndex:i];
				
				for (uint j = 0; j < [commands count]; j++) {
					NSDictionary *command = [commands objectAtIndex:j];
					
					if (command != nil) {
						[self runCommand:command];
					}
				}
			}
		}
	//}
}

-(void) broadcastMessage:(NSDictionary *)command
{
	[[GameLayer getInstance] broadcastMessageToRobots:command];
}

-(void) messageSelf:(NSDictionary *)command 
{
    //CCLOG(@"Robot.messageSelf: %@", command);
	[self receiveMessage:[command objectForKey:@"message"]];
}

-(void) messageSelfAfterDelay:(NSDictionary *)command 
{	
	float delay;
	
	if ([[command objectForKey:@"delay"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delay"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"delay"]];
		delay = [num floatValue];
		
	} else {
		delay = [[command objectForKey:@"delay"] floatValue];
	}
	
    NSString *message = [command objectForKey:@"message"];
    SEL sel = sel_registerName([[NSString stringWithFormat:@"%@:command:", message] UTF8String]);
    
    //CCLOG(@"Robot.messageSelfAfterDelay: %@", message);
    
    id action = [CCSequence actions:
                 [CCDelayTime actionWithDuration:delay/DELAY_FACTOR],
                 [CCCallFuncND actionWithTarget:self selector:sel data:command],
                 nil];
	[self runAction: action];
}

-(void) _delayedMessage
{
	[self messageSelf:delayedMessage];
}

-(void) broadcastMessageAfterDelay:(NSDictionary *)command 
{
	delayedMessage = command;
	
	float delay;
	
	if ([[command objectForKey:@"delay"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delay"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"delay"]];
		delay = [num floatValue];
		
	} else {
		delay = [[command objectForKey:@"delay"] floatValue];
	}
    
    [self scheduleOnce:@selector(_delayedBroadcast) delay:delay/DELAY_FACTOR];
}

-(void) _delayedBroadcast
{
	[self broadcastMessage:delayedMessage];
}

-(NSNumber *) opSin:(id)obj
{
	float amount;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount = [num floatValue];
		
	} else {
		amount = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	return [NSNumber numberWithFloat:sinf(amount)];
}

-(NSNumber *) opCos:(id)obj
{
	float amount;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount = [num floatValue];
		
	} else {
		amount = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	return [NSNumber numberWithFloat:cosf(amount)];
}

-(NSNumber *) opRound:(id)obj
{
	float amount;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount = [num floatValue];
		
	} else {
		amount = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	return [NSNumber numberWithFloat:roundf(amount)];
}

-(NSNumber *) opTan:(id)obj
{
	float amount;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount = [num floatValue];
		
	} else {
		amount = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	return [NSNumber numberWithFloat:tanf(amount)];
}

-(NSNumber *) opAddition:(id)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithFloat:amount1+amount2];
}

-(NSNumber *) opSubtraction:(id)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithFloat:amount1-amount2];
}

-(NSNumber *) opMultiplication:(NSDictionary *)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithFloat:amount1*amount2];
}

-(NSNumber *) opDivision:(id)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithFloat:amount1/amount2];
}

-(NSNumber *) opGreaterThan:(id)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithBool:amount1>amount2];
}

-(NSNumber *) opLessThan:(id)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithBool:amount1<amount2];
}

-(NSNumber *) opEqual:(id)obj
{
	float amount1;
	float amount2;
	
	if ([[obj objectForKey:@"operand1"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand1"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand1"]];
		amount1 = [num floatValue];
		
	} else {
		amount1 = [[obj objectForKey:@"operand1"] floatValue];
	}
	
	if ([[obj objectForKey:@"operand2"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"operand2"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"operand2"]];
		amount2 = [num floatValue];
		
	} else {
		amount2 = [[obj objectForKey:@"operand2"] floatValue];
	}
	
	return [NSNumber numberWithBool:amount1==amount2];
}

-(NSNumber *) distanceToInstance:(NSDictionary *)command 
{
	CGPoint point1 = CGPointZero;
	CGPoint point2 = CGPointZero;
	
	if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
		point1 = [[GameLayer getInstance] playerPosition];
	}
	
	if ([[[command objectForKey:@"location"] objectForKey:@"token"] isEqualToString:@"thisLocation"]) {
		point2 = self.position;
		
	} else {
		NSDictionary *location = [command objectForKey:@"location"];
		NSString *token = [location objectForKey:@"token"];
		
		NSMutableArray *node = [self runMethod:token withObject:location];
		
		float x = [[node objectAtIndex:0] floatValue];
		float y = [[node objectAtIndex:1] floatValue];
		
		point2 = ccp(x,y);
	}
	
	return [NSNumber numberWithFloat:ccpDistance(point1, point2)];
}

-(void) quakeCamera:(NSDictionary *)command 
{
    //CCLOG(@"Robot.quakeCamera: %@", command);
    
    int intensity = [[command objectForKey:@"intensity"] intValue];
    int time = [[command objectForKey:@"time"] intValue];
    
    [[GameLayer getInstance] quakeCameraWithIntensity:intensity during:time];
}

-(void) flashScreen:(NSDictionary *)command 
{
    //CCLOG(@"Robot.flashScreen: %@", command);
    
    int color = [[command objectForKey:@"color"] intValue];
    int time = [[command objectForKey:@"time"] intValue];
    
    [[GameLayer getInstance] flashScreenWithColor:color during:time];
}

-(NSNumber *) angleToInstance:(NSDictionary *)command 
{
	CGPoint point1 = CGPointZero;
	CGPoint point2 = CGPointZero;
	
	if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
		point1 = [[GameLayer getInstance] playerPosition];
	}
	
	if ([[[command objectForKey:@"location"] objectForKey:@"token"] isEqualToString:@"thisLocation"]) {
		point2 = self.position;
		
	} else {
		NSDictionary *location = [command objectForKey:@"location"];
		NSString *token = [location objectForKey:@"token"];
		
		NSMutableArray *node = [self runMethod:token withObject:location];
		
		float x = [[node objectAtIndex:0] floatValue];
		float y = [[node objectAtIndex:1] floatValue];
		
		point2 = ccp(x,y);
	}
	
	float degrees = atan2(point2.x - point1.x, point2.y - point1.y) * (180 / M_PI);
	//degrees = degrees < 0 ? degrees + 360 : degrees;
	//degrees += 90;
		
	//CCLOG(@">>>> %f (%f,%f) - (%f,%f)", degrees, point1.x, point1.y, point2.x, point2.y);
	return [NSNumber numberWithFloat:degrees];
}

-(NSString *) customString:(NSDictionary *)command
{
    //CCLOG(@"Robot.customString: %@", command);
    
    NSString *variable = [command objectForKey:@"variable"];
    
    NSString *string;
    if ((string = [parameters objectForKey:variable]) != nil) return string;
    else return @"";
}

-(NSNumber *) customBoolean:(NSDictionary *)command
{
    //CCLOG(@"Robot.customBoolean: %@", command);
    
    NSString *variable = [command objectForKey:@"variable"];
    
    NSString *string;
    if ((string = [parameters objectForKey:variable]) != nil) return [NSNumber numberWithBool:[string intValue] == 1];
    else return [NSNumber numberWithBool:NO];
}

-(NSDictionary *) customNode:(NSDictionary *)command
{
    //CCLOG(@"Robot.customNode: %@", command);
    
    NSString *variable = [command objectForKey:@"variable"];
    
    NSDictionary *values;
    if ((values = [parameters objectForKey:variable]) != nil) return values;
    else return [NSDictionary dictionary];
}


#pragma mark -
#pragma mark Events

-(void) resume 
{
	[self resumeSchedulerAndActions];
	paused = NO;
}

-(void) pause 
{
	[self pauseSchedulerAndActions];	
	paused = YES;
}

-(void) touched:(id)sender
{
	//CCLOG(@"Robot.touched: %@", behavior);
	if (!onTouchStart) {
		[self execute:@"onTouchStart" type:kGameObjectPlayer];
		onTouchStart = YES;
	}
    
    /*
    b2Vec2 current = body->GetLinearVelocity();
    if ((current.x == 0) && (current. y == 0)) {
        wasMoving = NO;
    } else {
        wasMoving = YES;
    }
    */
}

-(void) finished:(id)sender
{
	//CCLOG(@"Robot.finished: %@", behavior);
	onTouchStart = NO;
    
    if (!wasMoving) {
        body->SetLinearVelocity(b2Vec2(0,0));
        body->SetAngularVelocity(0);
    }
}

-(void) hit:(int)force 
{
	health -= force;
	
	if (health < 0 && !immortal) [self die:nil];
}


#pragma mark -
#pragma mark Reset

-(void) resetPosition
{
    [self setupRobot:original parameters:parameters];
    
	if (removed) {
		[self _recreateBody];
		self.position = originalPosition;
		body->SetTransform(b2Vec2(((self.position.x)/PTM_RATIO), (self.position.y)/PTM_RATIO),0);
		self.visible = YES;
		removed = NO;
		
	} else {
		self.position = originalPosition;
		body->SetTransform(b2Vec2(((self.position.x)/PTM_RATIO), (self.position.y)/PTM_RATIO),0);
	}
	
	onMessage = NO;
	onTouchStart = NO;
	onInShot = NO;
    onOutShot = YES;
    
    [self onSpawn];
}

-(void) remove
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"collect.caf" pitch:1.0f pan:0.0f gain:1.0f];
    
	[self stopAllActions];
	[super remove];
}

// collision handling
-( void )handleBeginCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
            
        case kGameObjectPlayer:
            [ self touched:object ];
            break;
            
        case kGameObjectBullet:
            if ( ( self.physics || self.solid) && ( !self.sensor ) ) {
                [ self hit:( ( Bullet* )object ).damage ];
                [ ( Bullet* )object die ];
            }
            break;
            
        default:
            break;
    }
}

-( void )handlePreSolve:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
            
        default:    
            if ( !self.physics && !self.solid ) data.contact->SetEnabled( false );
            break;
            
    }
}

- (void)dealloc
{
	[behavior release];
    [parameters release];
    [original release];
	[msgCommands release];
	[msgName release];
	[andToken release];
	[orToken release];
	[timerCommands release];
	[name release];
    
    [super dealloc];
}

@end
