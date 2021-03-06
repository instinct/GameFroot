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
#import "Shared.h"
#import "SimpleAudioEngine.h"
#include <objc/runtime.h>

#define FLASH_VELOCITY_FACTOR	50.0f
#define DELAY_FACTOR			1000.0f
#define MIN_DELAY               100.0f

void runDynamicMessage(id self, SEL _cmd, id selector, NSDictionary *command)
{
    [self performSelector:@selector(messageSelf:) withObject:command];
}

void runDynamicBroadcastMessage(id self, SEL _cmd, id selector, NSDictionary *command)
{
    [self performSelector:@selector(broadcastMessage:) withObject:command];
}

@implementation Robot

@synthesize solid;
@synthesize physics;
@synthesize sensor;
@synthesize parameters;
@synthesize originalData;
@synthesize shooted;

- (id) init
{
    self = [super init];
    if (self) {
        type = kGameObjectRobot;
        shootSpeed = b2Vec2_zero;
        shooted = NO;
        touchingPlayer = NO;
        touching = touchingNone;
        spray = nil;
        firework = nil;
    }
    
    return self;
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	size = _size;
	
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = true;
	playerBodyDef.fixedRotation = true;
	
	// Try to use dynamic bodies, but ignoring gravity
    if (!physics && solid) playerBodyDef.type = b2_kinematicBody; // was b2_staticBody before but then we cannot move it, need to keep an eye on this!!
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
    
    // Robots don't collide with each others at all
    fixtureDef.filter.categoryBits = 0x2;
    fixtureDef.filter.maskBits = ~0x2; // = 0xFFFD
    
    body->CreateFixture(&fixtureDef);
	
	removed = NO;
}

-(void) setupRobot:(NSDictionary *)properties
{
	//CCLOG(@"Robot.setupRobot: %@", properties);
    
    if (behavior) [behavior release];
    if (originalData) [originalData release];
    if (parameters) [parameters release];
	if (msgCommands) [msgCommands release];
	if (msgName) [msgName release];
	if (timerCommands) [timerCommands release];
	if (name) [name release];
    
    originalData = [properties retain];
    parameters = [[properties objectForKey:@"robotParameters"] retain];
    NSDictionary *data = [properties objectForKey:@"robot"];
    
    //CCLOG(@"Robot.setupRobot: %@", data);
    //CCLOG(@"Robot.setupRobot (parameters): %@", parameters);
    
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
	onTouchStart = NO;
	onInShot = NO;
    onOutShot = NO;
	walkNode = CGPointZero;
	
	msgCommands = [[CCArray array] retain];
	msgName = [[CCArray array] retain];
	
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
            class_addMethod([self class], sel, (IMP)runDynamicMessage, "v@:@@");
            
            SEL selBroadcast = sel_registerName([[NSString stringWithFormat:@"%broadcast_@:command:", [event objectForKey:@"messageName"]] UTF8String]);
            class_addMethod([self class], selBroadcast, (IMP)runDynamicBroadcastMessage, "v@:@@");
            
            
		} else if ([nameEvent isEqualToString:@"onDie"]) {
			onDieCommands = [event objectForKey:@"commands"];
			
		}
	}
}

-(BOOL) triggerEvent:(NSString *)eventName;
{
    BOOL found = NO;
    
    int totalEvents = [behavior count];
	for (int i=0; i<totalEvents; i++) {
		NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:i];
		NSString *nameEvent = [event objectForKey:@"event"];
        
        //CCLOG(@"Robot.triggerEvent: %@ == %@", nameEvent, eventName);
		if ([nameEvent isEqualToString:eventName]) {
            //CCLOG(@"Robot.%@: %@", name, event);
            
			[self resolve:i];
            
            found = YES;
        }
    }
    
    return found;
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
    
    if (shooted) {
        body->SetLinearVelocity(shootSpeed);
    }
    
    //CCLOG(@"Robot.position: %f,%f", self.position.x, self.position.y);
    
	if ( [ self isInsideScreen:pos ] == NO ) {
        if (self.visible) {
            self.visible = NO;
            //body->SetActive( false );
        }
        
        if (!onOutShot && onInShot) [self triggerEvent:@"onOutShot"];
        
        onOutShot = YES;
        onInShot = NO;
        
	} else {
		if (!self.visible) {
            if (!invisible) self.visible = YES;
            //body->SetActive( true );
        }
		
		if (!onInShot) [self triggerEvent:@"onInShot"];
        
        onInShot = YES;
        onOutShot = NO;
	}

	//if (walkNode != CGPointZero) {
    // TODO: walk node to position
	//}
	
	b2Vec2 current = body->GetLinearVelocity();
    
	if (current.x > 0) {
		facingLeft = NO;
		
	} else {
		facingLeft = YES;
	}
	
	[super update:dt];
}

-(id) runMethod:(NSString *)nameMethod withObject:(id)anObject
{
	NSString *method;
	
    //this is required since if is a reserved keyword!
	if ([nameMethod isEqualToString:@"if"]) nameMethod = @"conditionIf";
    if ([nameMethod isEqualToString:@"setOpacity"]) nameMethod = @"setTransparency";
    
	if (anObject != nil) method = [NSString stringWithFormat:@"%@:", nameMethod];
	else method = nameMethod;
	
    if (TRACE_COMMANDS) CCLOG(@"Robot: calling selector: %@ with parameter: %@", method, anObject);
    
	SEL selector = NSSelectorFromString(method);
	if ([self respondsToSelector:selector]) {
		
		id result;
		if (anObject != nil) result = [self performSelector:selector withObject:anObject];
		else result = [self performSelector:selector];
		
		return result;
		
	} else {
		CCLOG(@"Robot: undeclared selector: %@", method);
		return nil;
	}
}

-(void) runCommand: (NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.runCommand: %@", command);
    
	//Run the first command within the list:
	NSString *action = [command objectForKey:@"action"];
	
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
			
			[self runMethod:actionTrue withObject:action];
		}
		
	} else {
		
		NSArray *onFalse = [command objectForKey:@"onFalse"];
		for (uint i = 0; i < [onFalse count]; i++){
			NSDictionary *action = (NSDictionary *)[onFalse objectAtIndex:i];
			NSString *actionTrue = [action objectForKey:@"action"];
			
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
    if (TRACE_COMMANDS) CCLOG(@"Robot.isSolid: %i", solid);
    
	return solid;
}

-(BOOL) beNotSolid:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.beNotSolid");
    
	solid = NO;
    [self markToRecreateBody:size];
    
	return solid;
}

-(BOOL) beSolid:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.beSolid");
    
	solid = YES;
    [self markToRecreateBody:size];
	
	return solid;
}

-(void) say:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.say: %@", obj);
    
    if ([[obj objectForKey:@"words"] isKindOfClass:[NSDictionary class]]) {
        NSString *token = [[obj objectForKey:@"words"] objectForKey:@"token"];
		NSString *msg = [self runMethod:token withObject:[obj objectForKey:@"words"]];
        [[GameLayer getInstance] say:msg];
        
    } else  if ([[obj objectForKey:@"words"] isKindOfClass:[NSString class]]) {
        [[GameLayer getInstance] say:[obj objectForKey:@"words"]];
        
    } else  if ([[obj objectForKey:@"sentence"] isKindOfClass:[NSDictionary class]]) {
        NSString *token = [[obj objectForKey:@"sentence"] objectForKey:@"token"];
		NSString *msg = [self runMethod:token withObject:[obj objectForKey:@"sentence"]];
        [[GameLayer getInstance] say:msg];
        
    } else  if ([[obj objectForKey:@"sentence"] isKindOfClass:[NSString class]]) {
        [[GameLayer getInstance] say:[obj objectForKey:@"sentence"]];
    }
}

-(void) think:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.think: %@", obj);
    
    [self say:obj];
}

-(void) sayInChatPanel:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.sayInChatPanel: %@", obj);
    
    [self say:obj];
}

-(void) askMultichoice:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.askMultichoice: %@", command);
    
    [[GameLayer getInstance] askMultichoice:command robot:self];
}

-(void) gotoLevel:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.gotoLevel: %@", command);
    
    int gameID = [[command objectForKey:@"level"] intValue];
    [[GameLayer getInstance] loadNextLevel:gameID];
}

-(void) completeLevelAndGoto:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.completeLevelAndGoto: %@", command);
    
    int gameID = [[command objectForKey:@"level"] intValue];
    [[GameLayer getInstance] completeAndLoadNextLevel:(int)gameID withTitle:[command objectForKey:@"text"]];
}

-(void) endGameSuccess:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.endGameSuccess: %@", command);
    
    [[GameLayer getInstance] winGameWithText:[command objectForKey:@"text"]];
}

-(void) endGameFailure:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.endGameFailure: %@", command);
    
    [[GameLayer getInstance] loseGameWithText:[command objectForKey:@"text"]];
}

-(NSNumber *) isVisible:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.isVisible: %i", invisible);
    
	return [NSNumber numberWithBool:!invisible];
}

-(NSNumber *) goVisible:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.goVisible");
    
	self.opacity = 0xFF;
    invisible = NO;
	return [NSNumber numberWithBool:!invisible];
}

-(NSNumber *) goInvisible:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.goInvisible");
    
	self.opacity = 0x00;
    invisible = YES;
	return [NSNumber numberWithBool:!invisible];
}

-(void) setTransparency:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.setOpacity");
    
    int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		amount = [num intValue];
		
	} else {
		amount = [[command objectForKey:@"amount"] intValue];
	}
    
	self.opacity = 0xFF * ((float)amount / 100.0f);
}

-(NSNumber *) facingLeft:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.facingLeft: %i", facingLeft);
    
	return [NSNumber numberWithBool:facingLeft];
}

-(NSNumber *) facingRight:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.facingRight: %i", !facingLeft);
    
	return [NSNumber numberWithBool:!facingLeft];
}

-(void) faceLeft:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.faceLeft");
    
    self.scaleX = -1;
    facingLeft = YES;
}

-(void) faceRight:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.faceRight");
    
    self.scaleX = 1;
    facingLeft = NO;
}

-(void) faceObject:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.faceObject");
    
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
    //if (TRACE_COMMANDS) CCLOG(@"Robot.coordinateXOfNode: %@", command);
    
    NSDictionary *node = [command objectForKey:@"node"];
    NSMutableArray *position = [self runMethod:[node objectForKey:@"token"] withObject:node];
    
    float x = [[position objectAtIndex:0] floatValue];
    float y = [[position objectAtIndex:0] floatValue];
    CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:ccp(x,y)];
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.coordinateXOfNode: %f", pos.x);
    return [NSNumber numberWithFloat:pos.x];
}

-(NSNumber *) coordinateYOfNode:(NSDictionary *)command 
{
    //if (TRACE_COMMANDS) CCLOG(@"Robot.coordinateYOfNode: %@", command);
    
    NSDictionary *node = [command objectForKey:@"node"];
    NSMutableArray *position = [self runMethod:[node objectForKey:@"token"] withObject:node];
    
    float x = [[position objectAtIndex:0] floatValue];
    float y = [[position objectAtIndex:1] floatValue];
    CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:ccp(x,y)];
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.coordinateYOfNode: %f", pos.y);
    return [NSNumber numberWithFloat:pos.y];
}

-(NSMutableArray *) thisLocation:(NSDictionary *)obj
{
    //CGPoint position = [[GameLayer getInstance] convertToMapCoordinates:self.position];
    CGPoint position = self.position;
    
	NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
	[pos addObject:[NSNumber numberWithFloat:position.x - MAP_TILE_WIDTH]];
	[pos addObject:[NSNumber numberWithFloat:position.y - MAP_TILE_HEIGHT]];
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.thisLocation: %f,%f", position.x - MAP_TILE_WIDTH/2, position.y - MAP_TILE_HEIGHT);
    
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
		x += [num floatValue] / CC_CONTENT_SCALE_FACTOR();
		
	} else {
		x += [[obj objectForKey:@"xMod"] floatValue] / CC_CONTENT_SCALE_FACTOR();
	}
	
    if (x > ([GameLayer getInstance].mapWidth * MAP_TILE_WIDTH)) x = [GameLayer getInstance].mapWidth * MAP_TILE_WIDTH;
    if (x < MAP_TILE_WIDTH) x = MAP_TILE_WIDTH;
        
	if ([[obj objectForKey:@"yMod"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[obj objectForKey:@"yMod"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[obj objectForKey:@"yMod"]];
		y -= [num floatValue] / CC_CONTENT_SCALE_FACTOR();
		
	} else {
		y -= [[obj objectForKey:@"yMod"] floatValue] / CC_CONTENT_SCALE_FACTOR();
	}		
	
    if (y > ([GameLayer getInstance].mapHeight * MAP_TILE_HEIGHT)) x = [GameLayer getInstance].mapHeight * MAP_TILE_HEIGHT;
    if (y < MAP_TILE_HEIGHT + MAP_TILE_HEIGHT/2) y = MAP_TILE_HEIGHT + MAP_TILE_HEIGHT/2;
    
	
	NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
	[pos addObject:[NSNumber numberWithFloat:x]];
	[pos addObject:[NSNumber numberWithFloat:y]];
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.adjustNodeByCoords: %f,%f", x, y);
    
	return pos;
}

-(NSNumber *) randomNumberRange:(NSDictionary *)obj
{	
	int high = [[obj objectForKey:@"max"] intValue];
	int low = [[obj objectForKey:@"min"] intValue];

    //float rnd;
	//if (high == low) rnd = (float)high;
	//else rnd = (float)(arc4random()%high) + low;
    
    float rnd = floorf( ((arc4random()%1000) / 1000.0f) * (1 + high-low) ) + low;
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.randomNumberRange: %f", rnd);
    //CCLOG(@"Robot.randomNumberRange: [%i / %i] -> %f", high, low, rnd);
    
    return [NSNumber numberWithFloat:rnd];
}

-(NSMutableArray *) locationOfInstance:(NSDictionary *)obj 
{
    //CCLOG(@"Robot.locationOfInstance: %@", obj);
    
	NSDictionary *instance = [obj objectForKey:@"instance"];
	NSString *token = [instance objectForKey:@"token"];
	
	if ([token isEqualToString:@"player"]) {
		//CGPoint position = [[GameLayer getInstance] convertToMapCoordinates:[[GameLayer getInstance] playerPosition]];
        CGPoint position = [[GameLayer getInstance] playerPosition];
        
        NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
        [pos addObject:[NSNumber numberWithFloat:position.x]];
        [pos addObject:[NSNumber numberWithFloat:position.y]];
        
        if (TRACE_COMMANDS) CCLOG(@"Robot.locationOfInstance: %f,%f", position.x, position.y);
        
		return pos;
        
	} else {
        NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
        [pos addObject:[NSNumber numberWithFloat:0]];
        [pos addObject:[NSNumber numberWithFloat:0]];
        
        if (TRACE_COMMANDS) CCLOG(@"Robot.locationOfInstance: %f,%f", 0.0f, 0.0f);
        
		return pos;
	}
}

-(void) changeScore:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeScore: %@", command);
    
	int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		amount = [num intValue];
		
	} else {
		amount = [[command objectForKey:@"amount"] intValue];
	}
    
	[[GameLayer getInstance] increasePoints:amount];
}

-(void) die:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.die: %@", command);
    
	for (uint i = 0; i < [onDieCommands count]; i++) {
		[self runCommand:[onDieCommands objectAtIndex:i]];
	}
	
    NSString *permanent;
    if ((permanent = [parameters objectForKey:@"permanent"]) == nil) permanent = @"0";
    BOOL isPermanent = [permanent intValue] == 1;
    
    //CCLOG(@"Robot.die: %i", isPermanent);
    
	if (!isPermanent) {
        // If spawend then we need to destroy
        if (spawned) [self destroy];
        else [self remove];
    }
}

-(NSNumber *) changeHealth:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeHealth: %@", command);
    
	int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		amount = [num intValue];
		
	} else {
		amount = [[command objectForKey:@"amount"] intValue];
	}
    
    health += amount;		
    
    if (health < 0) health = 0;
	if (health == 0) [self die:nil];
        
	return [NSNumber numberWithInt:health];
}

-(void) inflictDamage:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.inflictDamage: %@", command);
    
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
            if (touchingPlayer) [[SimpleAudioEngine sharedEngine] playEffect:@"IG Hero Damage.caf" pitch:1.0f pan:0.0f gain:1.0f];
			[[GameLayer getInstance] decreaseHealth:amount];
			
		} else {
			[[GameLayer getInstance] increaseHealth:amount];
		}
	}
}

-(NSNumber *) myHealth:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.myHealth: %@", obj);
	
	return [NSNumber numberWithInt:health];
}

-(void) changeLives:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeLives: %@", command);
    
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
    if (TRACE_COMMANDS) CCLOG(@"Robot.timeStart");
    
    [[GameLayer getInstance] enableTimer];
}

-(void) timePause:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.timePause");
    
    [[GameLayer getInstance] pauseTimer];
}

-(void) timeStop:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.timeStop");
    
    [[GameLayer getInstance] disableTimer];
}

-(void) setTime:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.setTime: %@", command);
    
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
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeTime: %@", command);
        
    int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
        amount = [num intValue];
		
	} else {
        amount = [[command objectForKey:@"amount"] intValue];
	}
    
	[[GameLayer getInstance] increaseTime:amount];
}

-(void) showClock:(id)obj
{
    [[GameLayer getInstance] showClock];
}

-(void) hideClock:(id)obj
{
    [[GameLayer getInstance] hideClock];
}

-(void) hideHealth:(id)obj
{
    [[GameLayer getInstance] hideHealth];
}

-(void) hideScore:(id)obj
{
    [[GameLayer getInstance] hideScore];
}

-(void) showHealth:(id)obj
{
    [[GameLayer getInstance] showHealth];
}

-(void) showScore:(id)obj
{
    [[GameLayer getInstance] showScore];
}

-(NSNumber *) timeLeft:(id)obj
{
	return [NSNumber numberWithInt:[[GameLayer getInstance] timeLeft]];
}

-(void) pauseBgm:(id)obj
{
    [[GameLayer getInstance] pauseBgm];
}

-(void) resumeBgm:(id)obj
{
    [[GameLayer getInstance] resumeBgm];
}

-(void) restartBgm:(id)obj
{
    [[GameLayer getInstance] restartBgm];
}

-(void) godModeOff:(id)obj
{
    [[GameLayer getInstance] godModeOff];
}

-(void) godModeOn:(id)obj
{
    [[GameLayer getInstance] godModeOn];
}

-(void) changeMaxHealth:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeMaxHealth: %@", command);
    
    int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
        amount = [num intValue];
		
	} else {
        amount = [[command objectForKey:@"amount"] intValue];
	}
    
    topHealth = amount;
	//[[GameLayer getInstance] changeMaxHealth:amount];
}


-(void) setScore:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.setScore: %@", command);

    int amount = [[command objectForKey:@"amount"] intValue];
	[[GameLayer getInstance] setPoints:amount];
}

-(NSNumber *) getScore:(id)obj
{
	return [NSNumber numberWithInt:[GameLayer getInstance].points];
}

-(void) triggerCheckpoint:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.triggerCheckpoint: %@", command);
    CGPoint mapPos = [self getTilePosition];
    [[GameLayer getInstance] changeInitialPlayerPositionToX:mapPos.x andY:mapPos.y];
}

-(void) teleport:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
    id result = [self runMethod:token withObject:location];
    
    // Reset onTouch event
    onTouchStart = NO;
     
    float auxX, auxY;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *position = (NSDictionary *)result;
        auxX = [[position objectForKey:@"xpos"] floatValue];
        auxY = [[position objectForKey:@"ypos"] floatValue];
        
        CGPoint pos = ccp(auxX * MAP_TILE_WIDTH, ([GameLayer getInstance].mapHeight - auxY - 1) * MAP_TILE_HEIGHT);
        pos.x += MAP_TILE_WIDTH/2.0f;
        pos.y += MAP_TILE_HEIGHT/2.0f;
        
        if (TRACE_COMMANDS) CCLOG(@"Robot.teleport: %f, %f", pos.x, pos.y);
        
        [self markToTransformBody:b2Vec2((pos.x/PTM_RATIO), pos.y/PTM_RATIO) angle:body->GetAngle()];
        self.position = pos;
        
	} else if ([result isKindOfClass:[NSArray class]]) {
        NSArray *position = (NSArray *)result;
        auxX = [[position objectAtIndex:0] floatValue];
        auxY = [[position objectAtIndex:1] floatValue];
        
        if (TRACE_COMMANDS) CCLOG(@"Robot.teleport: %f, %f", auxX, auxY);
        
        CGPoint pos = ccp(auxX, auxY);
        [self markToTransformBody:b2Vec2((pos.x/PTM_RATIO), pos.y/PTM_RATIO) angle:body->GetAngle()];
        self.position = pos;
    }
}

-(void) teleportInstance:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
    id result = [self runMethod:token withObject:location];
    
    // Reset onTouch event
    onTouchStart = NO;
    
    float auxX, auxY;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *position = (NSDictionary *)result;
        auxX = [[position objectForKey:@"xpos"] floatValue];
        auxY = [[position objectForKey:@"ypos"] floatValue];
        
        if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
            
            if (TRACE_COMMANDS) CCLOG(@"Robot.teleportInstance (map position): %f, %f", auxX, auxY);
            
            // This is the only case where we need to run the hardcoded teleport animation
            [[GameLayer getInstance] runTeleportAnimation:self.position];
            
            [[SimpleAudioEngine sharedEngine] playEffect:@"IG Transporter.caf"];
            [[GameLayer getInstance] transportPlayerToX:auxX andY:auxY];
        }
        
	} else if ([result isKindOfClass:[NSArray class]]) {
        NSArray *position = (NSArray *)result;
        auxX = [[position objectAtIndex:0] floatValue];
        auxY = [[position objectAtIndex:1] floatValue];
       
        if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
            
            if (TRACE_COMMANDS) CCLOG(@"Robot.teleportInstance (screen position): %f, %f", auxX, auxY);
            
            [[GameLayer getInstance] transportPlayerToPosition:ccp(auxX, auxY)];
            //[[GameLayer getInstance] transportPlayerToX:auxX andY:auxY];
        }
    }
}

-(void) walkToNode:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
	NSMutableArray *node = [self runMethod:token withObject:location];
	
	float x = [[node objectAtIndex:0] floatValue];
	float y = [[node objectAtIndex:1] floatValue];
	
	walkNode = ccp(x,y);
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.walkToNode: %f, %f", x, y);
}

-(NSNumber *) walkSpeed:(id)obj
{
	b2Vec2 current = body->GetLinearVelocity();
	float speed = current.x * FLASH_VELOCITY_FACTOR;
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.walkSpeed: %f", speed);
    
    return [NSNumber numberWithFloat:speed];
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.setWalkSpeed: %f", speed);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.setXvelocity: %f", speed);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.setYvelocity: %f", speed);
    
	b2Vec2 current = body->GetLinearVelocity();
	b2Vec2 velocity = b2Vec2(current.x, -speed / FLASH_VELOCITY_FACTOR);
	body->SetLinearVelocity(velocity);
    wasMoving = YES;
}

-(void) changeXvelocity:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeXvelocity: %@", command);
    
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
    if (TRACE_COMMANDS) CCLOG(@"Robot.changeYvelocity: %@", command);
    
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
    float speed = current.x * FLASH_VELOCITY_FACTOR;
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.xVelocity: %f", speed);
    
    return [NSNumber numberWithFloat:speed];
}

-(NSNumber *) yVelocity:(id)obj 
{
	b2Vec2 current = body->GetLinearVelocity();
    float speed = -current.y * FLASH_VELOCITY_FACTOR;
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.yVelocity: %f", speed);
    
    return [NSNumber numberWithFloat:speed];
}

-(void) lockPlayerYSpeed:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.lockPlayerYSpeed: %@", command);
    
	float speed;
	
	if ([[command objectForKey:@"speed"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"speed"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"speed"]];
        speed = [num floatValue];
		
	} else {
        speed = [[command objectForKey:@"speed"] floatValue];
	}
	
	
    [[GameLayer getInstance] lockPlayerYSpeed:speed];
}

-(void) lockPlayerXSpeed:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.lockPlayerXSpeed: %@", command);
    
	float speed;
	
	if ([[command objectForKey:@"speed"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"speed"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"speed"]];
        speed = [num floatValue];
		
	} else {
        speed = [[command objectForKey:@"speed"] floatValue];
	}
	
	
    [[GameLayer getInstance] lockPlayerXSpeed:speed];
}

-(void) spawnNewObject:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.spawnNewObject: %@", command);
    
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
    NSString *objClass = [[command objectForKey:@"objclass"] objectForKey:@"token"];
    
    if ([objClass isEqualToString:@"thisType"]) {
        NSMutableArray *node = [self runMethod:token withObject:location];
        //float dx = roundf([[node objectAtIndex:0] floatValue] / 48.0);
        //float dy = roundf([[node objectAtIndex:1] floatValue] / 48.0);
        float dx = [[node objectAtIndex:0] floatValue];
        float dy = [[node objectAtIndex:1] floatValue];
        [[GameLayer getInstance] spawnRobot:self.textureRect data:[originalData copy] pos:ccp(dx,dy) direction:0.0f speed:0.0f];
        
    } else if ([objClass isEqualToString:@"enemy"]) {
        //int dx = [[originalData objectForKey:@"positionX"] intValue];
        //int dy = [[originalData objectForKey:@"positionY"] intValue];
        NSMutableArray *node = [self runMethod:token withObject:location];
        float dx = [[node objectAtIndex:0] floatValue];
        float dy = [[node objectAtIndex:1] floatValue];
        
        [[GameLayer getInstance] spawnEnemy:ccp(dx,dy)];
    }
}

-(void) shootNewObject:(NSDictionary *)command 
{
	if (TRACE_COMMANDS) CCLOG(@"Robot.shootNewObject: %@", command);
    
    float direction;
    
	if ([[command objectForKey:@"direction"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"direction"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"direction"]];
		direction = [num floatValue];
		
	} else {
		direction = [[command objectForKey:@"direction"] floatValue];
	}
    
    float speed;
    
	if ([[command objectForKey:@"speed"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"speed"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"speed"]];
		direction = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"speed"] floatValue];
	}
    
    NSString *objClass = [[command objectForKey:@"objclass"] objectForKey:@"token"];
    
    if ([objClass isEqualToString:@"thisType"]) {
        // Spawn from robot position
        float dx = self.position.x;
        float dy = self.position.y;
        
        [[GameLayer getInstance] spawnRobot:self.textureRect data:[originalData copy] pos:ccp(dx,dy) direction:direction speed:speed];
        
    }
}

-(NSNumber *) isFalling:(id)obj
{
	b2Vec2 current = body->GetLinearVelocity();
	BOOL falling = current.y < -0.01;
    
    if (TRACE_COMMANDS) CCLOG(@"Robot.isFalling: %i", falling);
        
    return [NSNumber numberWithBool:falling];
}

-(void) freezePlayer:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.freezePlayer");
    
    body->SetLinearVelocity(b2Vec2(0,0));
    body->SetAngularVelocity(0);
    
    freezed = YES;
    wasMoving = NO;
}

-(void) unfreezePlayer:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.unfreezePlayer");
    
    freezed = NO;
}

-(NSNumber *) playerHealth:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.playerHealth: %@", obj);
	
	return [NSNumber numberWithInt:[[GameLayer getInstance] playerHealth]];
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
    if (TRACE_COMMANDS) CCLOG(@"Robot.isPhysicsFrozen: %i", frozen);
    
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
    if (TRACE_COMMANDS) CCLOG(@"Robot.receiveMessage: %@", msg);
    
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
}

-(void) broadcastMessage:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.broadcastMessage: %@", command);
    
	[[GameLayer getInstance] broadcastMessageToRobots:command];
}

-(void) messageSelf:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.messageSelf: %@", command);
    
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
	
    if (delay < MIN_DELAY) delay = MIN_DELAY; // Just for security in case someone sets a very low delay!!
    
    NSString *message = [command objectForKey:@"message"];
    if (TRACE_COMMANDS) CCLOG(@"Robot.messageSelfAfterDelay: %@ (%f)", message, delay/DELAY_FACTOR);
    
    SEL sel = sel_registerName([[NSString stringWithFormat:@"%@:command:", message] UTF8String]);
                               
    id action = [CCSequence actions:
                 [CCDelayTime actionWithDuration:delay/DELAY_FACTOR],
                 [CCCallFuncND actionWithTarget:self selector:sel data:command],
                 nil];
	[self runAction: action];
}


-(void) broadcastMessageAfterDelay:(NSDictionary *)command 
{
	float delay;
	
	if ([[command objectForKey:@"delay"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delay"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"delay"]];
		delay = [num floatValue];
		
	} else {
		delay = [[command objectForKey:@"delay"] floatValue];
	}
    
    if (delay < MIN_DELAY) delay = MIN_DELAY; // Just for security in case someone sets a very low delay!!
    
    NSString *message = [command objectForKey:@"message"];
    if (TRACE_COMMANDS) CCLOG(@"Robot.broadcastMessageAfterDelay: %@ (%f)", message, delay/DELAY_FACTOR);
    
    SEL sel = sel_registerName([[NSString stringWithFormat:@"broadcast_%@:command:", message] UTF8String]);
    
    id action = [CCSequence actions:
                 [CCDelayTime actionWithDuration:delay/DELAY_FACTOR],
                 [CCCallFuncND actionWithTarget:self selector:sel data:command],
                 nil];
	[self runAction: action];
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opSin: %f", sinf(amount));
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opCos: %f", cosf(amount));
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opRound: %f", roundf(amount));
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opTan: %f", tanf(amount));
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opAddition: %f", amount1+amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opSubtraction: %f", amount1-amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opMultiplication: %f", amount1*amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opDivision: %f", amount1/amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opGreaterThan: %f > %f is %i", amount1, amount2, amount1>amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opLessThan: %f < %f is %i", amount1, amount2, amount1<amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.opEqual: %f == %f is %i", amount1, amount2, amount1==amount2);
    
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
	
    if (TRACE_COMMANDS) CCLOG(@"Robot.distanceToInstance: %f", ccpDistance(point1, point2));
    
	return [NSNumber numberWithFloat:ccpDistance(point1, point2)];
}

-(void) stopCameraMove:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.stopCameraMove: %@", command);
    
    [[GameLayer getInstance] stopCameraMove];
}

-(void) cameraOnPlayer:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.cameraOnPlayer: %@", command);
    
    [[GameLayer getInstance] cameraOnPlayer];
}

-(void) panToLocation:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.panToLocation: %@", command);
    
    NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
    id result = [self runMethod:token withObject:location];
    
    float auxX, auxY;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *position = (NSDictionary *)result;
        auxX = [[position objectForKey:@"xpos"] floatValue];
        auxY = [[position objectForKey:@"ypos"] floatValue];
        
        [[GameLayer getInstance] panToLocation:ccp(auxX, auxY)];
        
	} else if ([result isKindOfClass:[NSArray class]]) {
        NSArray *position = (NSArray *)result;
        auxX = [[position objectAtIndex:0] floatValue];
        auxY = [[position objectAtIndex:1] floatValue];
        
        [[GameLayer getInstance] panToLocation:ccp(auxX, auxY)];
    }
}

-(void) snapToLocation:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.snapToLocation: %@", command);
    
    NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
    id result = [self runMethod:token withObject:location];
    
    float auxX, auxY;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *position = (NSDictionary *)result;
        auxX = [[position objectForKey:@"xpos"] floatValue];
        auxY = [[position objectForKey:@"ypos"] floatValue];
        
        [[GameLayer getInstance] snapToLocation:ccp(auxX, auxY)];
        
	} else if ([result isKindOfClass:[NSArray class]]) {
        NSArray *position = (NSArray *)result;
        auxX = [[position objectAtIndex:0] floatValue];
        auxY = [[position objectAtIndex:1] floatValue];
        
        [[GameLayer getInstance] snapToLocation:ccp(auxX, auxY)];
    }
}

-(void) cameraLockdown:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.cameraLockdown: %@", command);
}

-(void) cameraPlatformer:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.cameraPlatformer: %@", command);
}

-(void) offsetCameraY:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.offsetCameraY: %@", command);
    
    int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		amount = [num intValue];
		
	} else {
		amount = [[command objectForKey:@"amount"] intValue];
	}
    
    [[GameLayer getInstance] offsetCameraY:amount];
}

-(void) offsetCameraX:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.offsetCameraX: %@", command);
    
    int amount;
	
	if ([[command objectForKey:@"amount"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"amount"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"amount"]];
		amount = [num intValue];
		
	} else {
		amount = [[command objectForKey:@"amount"] intValue];
	}
    
    [[GameLayer getInstance] offsetCameraX:amount];
}

-(void) createSprayWithColor:(NSString *)color amount:(int)amount frequency:(float)frequency life:(float)life velocity:(float)velocity
{
    if (spray == nil) {
        spray=[[[CCParticleSystemQuad alloc] initWithTotalParticles:amount] autorelease];
        spray.emissionRate=amount * frequency;
        spray.angle=90.0;
        spray.angleVar=360.0;
        ccBlendFunc blendFunc={GL_ONE,GL_ONE_MINUS_SRC_ALPHA};
        spray.blendFunc=blendFunc;
        spray.duration=-1.00;
        spray.emitterMode=kCCParticleModeGravity;
        ccColor4F startColor=ccc4FFromccc4B([Shared colorForHex:color withTransparency:255]);
        spray.startColor=startColor;
        ccColor4F startColorVar={0.00,0.00,0.00,0.00};
        spray.startColorVar=startColorVar;
        ccColor4F endColor=ccc4FFromccc4B([Shared colorForHex:color withTransparency:255]);
        spray.endColor=endColor;
        ccColor4F endColorVar={0.00,0.00,0.00,0.00};
        spray.endColorVar=endColorVar;
        spray.startSize=5.00 / CC_CONTENT_SCALE_FACTOR();
        spray.startSizeVar=0.00;
        spray.endSize=-1.00;
        spray.endSizeVar=0.00;
        spray.gravity=ccp(0.00,0.00);
        spray.radialAccel=0.00;
        spray.radialAccelVar=0.00;
        spray.speed=velocity;
        spray.speedVar= 0;
        spray.tangentialAccel= 0;
        spray.tangentialAccelVar= 0;
        spray.totalParticles=amount;
        spray.life=life / CC_CONTENT_SCALE_FACTOR();
        spray.lifeVar=0.00;
        spray.startSpin=0.00;
        spray.startSpinVar=0.00;
        spray.endSpin=0.00;
        spray.endSpinVar=0.00;
        spray.position=self.position;
        spray.posVar=ccp(0.00,0.00);
        spray.positionType = kCCPositionTypeGrouped;
        
        [[GameLayer getInstance] addObject:spray withZOrder:LAYER_PLAYER-1];
        
    } else {
        [spray resetSystem];
    }
}

-(void) createFireworkWithColor:(NSString *)color amount:(int)amount frequency:(float)frequency life:(float)life velocity:(float)velocity
{
    if (firework == nil) {
        firework=[[[CCParticleSystemQuad alloc] initWithTotalParticles:amount] autorelease];
        firework.emissionRate=amount / frequency;
        firework.angle=90.0;
        firework.angleVar=360.0;
        ccBlendFunc blendFunc={GL_ONE,GL_ONE_MINUS_SRC_ALPHA};
        firework.blendFunc=blendFunc;
        firework.duration=life;
        firework.emitterMode=kCCParticleModeGravity;
        ccColor4F startColor=ccc4FFromccc4B([Shared colorForHex:color withTransparency:255]);
        firework.startColor=startColor;
        ccColor4F startColorVar={0.00,0.00,0.00,0.00};
        firework.startColorVar=startColorVar;
        ccColor4F endColor=ccc4FFromccc4B([Shared colorForHex:color withTransparency:255]);
        firework.endColor=endColor;
        ccColor4F endColorVar={0.00,0.00,0.00,0.00};
        firework.endColorVar=endColorVar;
        firework.startSize=5.00 / CC_CONTENT_SCALE_FACTOR();
        firework.startSizeVar=0.00;
        firework.endSize=-1.00;
        firework.endSizeVar=0.00;
        firework.gravity=ccp(0.00,0.00);
        firework.radialAccel=0.00;
        firework.radialAccelVar=0.00;
        firework.speed=velocity;
        firework.speedVar= 0;
        firework.tangentialAccel= 0;
        firework.tangentialAccelVar= 0;
        firework.totalParticles=amount;
        firework.life=life / CC_CONTENT_SCALE_FACTOR();
        firework.lifeVar=0.00;
        firework.startSpin=0.00;
        firework.startSpinVar=0.00;
        firework.endSpin=0.00;
        firework.endSpinVar=0.00;
        firework.position=self.position;
        firework.posVar=ccp(0.00,0.00);
        firework.positionType = kCCPositionTypeGrouped;
        
        [[GameLayer getInstance] addObject:firework withZOrder:LAYER_PLAYER-1];
        
    } else {
        [firework resetSystem];
    }
}

-(void) sprayParticles:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.sprayParticles: %@", command);
    
    NSString *color = [command objectForKey:@"color"];
    int amount = [[command objectForKey:@"amount"] intValue];
    float frequency = [[command objectForKey:@"frequency"] floatValue];
    float life = [[command objectForKey:@"life"] floatValue];
    float velocity = [[command objectForKey:@"velocity"] floatValue];
    
    [self createSprayWithColor:color amount:amount frequency:frequency life:life velocity:velocity];
}

-(void) fireWorks:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.fireWorks: %@", command);
    
    NSString *color = [command objectForKey:@"color"];
    int amount = [[command objectForKey:@"amount"] intValue];
    float frequency = [[command objectForKey:@"frequency"] floatValue];
    float life = [[command objectForKey:@"life"] floatValue];
    float velocity = [[command objectForKey:@"velocity"] floatValue];
    
    [self createFireworkWithColor:color amount:amount frequency:frequency life:life velocity:velocity];
}

-(void) playerSmokeOn:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.playerSmokeOn");
    
    [[GameLayer getInstance] playerSmokeOn];
    
}

-(void) playerSmokeOff:(id)obj
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.playerSmokeOff");
    
    [[GameLayer getInstance] playerSmokeOff];
    
}

-(void) quakeCamera:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.quakeCamera: %@", command);
    
    int intensity = [[command objectForKey:@"intensity"] intValue];
    int time = [[command objectForKey:@"time"] intValue];
    
    [[GameLayer getInstance] quakeCameraWithIntensity:intensity during:time];
}

-(void) flashScreen:(NSDictionary *)command 
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.flashScreen: %@", command);
    
    NSString *color = [command objectForKey:@"color"];
    int time = [[command objectForKey:@"time"] intValue];
    
    [[GameLayer getInstance] flashScreenWithColor:color during:time];
}

-(NSNumber *) angleToInstance:(NSDictionary *)command 
{
	CGPoint point1 = CGPointZero;
	CGPoint point2 = CGPointZero;
	
	if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
		point1 = [[GameLayer getInstance] playerPosition];
        
        // Aim the head
        point1.y += MAP_TILE_HEIGHT*1.6f;
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
		
    if (TRACE_COMMANDS) CCLOG(@"Robot.angleToInstance: %f", degrees);
    
	return [NSNumber numberWithFloat:degrees];
}

-(NSString *) customString:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.customString: %@", command);
    
    NSString *variable = [command objectForKey:@"variable"];
    
    NSString *string;
    if ((string = [parameters objectForKey:variable]) != nil) return string;
    else return @"";
}

-(NSNumber *) customBoolean:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.customBoolean: %@", command);
    
    NSString *variable = [command objectForKey:@"variable"];
    
    NSString *string;
    if ((string = [parameters objectForKey:variable]) != nil) return [NSNumber numberWithBool:[string intValue] == 1];
    else return [NSNumber numberWithBool:NO];
}

-(NSDictionary *) customNode:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.customNode: %@", command);
    
    NSString *variable = [command objectForKey:@"variable"];
    
    NSDictionary *values;
    if ((values = [parameters objectForKey:variable]) != nil) return values;
    else return [NSDictionary dictionary];
}

-(void) changePlayerWeapon:(NSDictionary *)command
{
    if (TRACE_COMMANDS) CCLOG(@"Robot.changePlayerWeapon: %@", command);
    
    NSString *weapon = [command objectForKey:@"weapon"];
    
    if ([weapon isEqualToString:@"pistol"]) {
		[[GameLayer getInstance] changeWeapon:0];
        
	} else if ([weapon isEqualToString:@"autoshotgun"]) {
		[[GameLayer getInstance] changeWeapon:1];
        
	} else if ([weapon isEqualToString:@"laser"]) {		
		[[GameLayer getInstance] changeWeapon:2];
		
	} else if ([weapon isEqualToString:@"musket"]) {		
		[[GameLayer getInstance] changeWeapon:3];
    
    } else if ([weapon isEqualToString:@"ak47"]) {		
		[[GameLayer getInstance] changeWeapon:4];
        
    } else if ([weapon isEqualToString:@"m60"]) {		
		[[GameLayer getInstance] changeWeapon:5];
    
    } else if ([weapon isEqualToString:@"rocket"]) {		
		[[GameLayer getInstance] changeWeapon:6];
	}
}

-(NSNumber *) touchingPlayer:(NSDictionary *)command
{
    return [NSNumber numberWithBool:touchingPlayer];
}

-(NSNumber *) touchingFloor:(NSDictionary *)command
{
    return [NSNumber numberWithBool:touching == touchingFloor];
}

-(NSNumber *) touchingWall:(NSDictionary *)command
{
    return [NSNumber numberWithBool:touching == touchingWall];
}

-(NSNumber *) touchingSomethingLeft:(NSDictionary *)command
{
    return [NSNumber numberWithBool:touching == touchingSomethingLeft];
}

-(NSNumber *) touchingSomethingRight:(NSDictionary *)command
{
    return [NSNumber numberWithBool:touching == touchingSomethingRight];
}

-(NSNumber *) touchingSomethingTop:(NSDictionary *)command
{
    return [NSNumber numberWithBool:touching == touchingSomethingTop];
}

-(NSNumber *) isFloorInFront:(NSDictionary *)command
{
    CGPoint tilePos = [self getTilePosition];
 
    int side;
    if ( facingLeft ) side = -1;
    else side = 1;
    
    BOOL tile = NO;
    
    if ( [ [ GameLayer getInstance ] getTileAt:ccp( tilePos.x + side, tilePos.y + 1 ) ] != TILE_TYPE_NONE ) tile = YES;
    
    return [NSNumber numberWithBool:tile];
}

-(NSNumber *) isWallInFront:(NSDictionary *)command
{
    
    CGPoint tilePos = [self getTilePosition];
    
    int side;
    if ( facingLeft ) side = -1;
    else side = 1;
    
    BOOL tile = NO;
    
    if ( [ [ GameLayer getInstance ] getTileAt:ccp( tilePos.x + side, tilePos.y ) ] != TILE_TYPE_NONE ) tile = YES;
    
    return [NSNumber numberWithBool:tile];
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

-(BOOL) interacted {
    if (removed) return NO;
    
    return [self triggerEvent:@"onInteract"];
}

-(void) touched:(id)sender
{
    if (removed) return;
    
	//CCLOG(@"Robot.touched: %@ (%i)", behavior, onTouchStart);
	if (!onTouchStart) {
        onTouchStart = YES;
        [self triggerEvent:@"onTouchStart"];
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
    [self triggerEvent:@"onTouchEnd"];
    
    if (!wasMoving) {
        body->SetLinearVelocity(b2Vec2(0,0));
        body->SetAngularVelocity(0);
    }
}

-(void) hit:(int)force 
{
    if (!immortal) {
        health -= force;
	
        if (health < 0) health = 0;
        if (health == 0) [self die:nil];
    }
    
    [self triggerEvent:@"onDamage"];
}

-(void) shootTo:(b2Vec2)vel
{
    shootSpeed = vel;
    shooted = YES;
}


#pragma mark -
#pragma mark Reset

-(void) restart
{
    [self setupRobot:originalData];
    
	if (removed) {
		[self createBox2dObject:[GameLayer getInstance].world size:size];
		self.position = originalPosition;
        [self markToTransformBody:b2Vec2(((self.position.x)/PTM_RATIO), (self.position.y)/PTM_RATIO) angle:body->GetAngle()];
        
		self.visible = YES;
		removed = NO;
		
	} else {
		self.position = originalPosition;
        [self markToTransformBody:b2Vec2(((self.position.x)/PTM_RATIO), (self.position.y)/PTM_RATIO) angle:body->GetAngle()];
	}
	
	onTouchStart = NO;
	onInShot = NO;
    onOutShot = NO;
    
    self.opacity = 0xff;
    if (spray != nil) [spray stopSystem];
    if (firework != nil) [firework stopSystem];
    
    body->SetLinearVelocity(b2Vec2(0,0));
    body->SetAngularVelocity(0);
    
    [self stopAllActions];
    
    [self triggerEvent:@"onSpawn"];

}

-(void) remove
{
    if (shooted) {
        [super remove];
        
        // Bullets always have to be destroyed (spawend)
		id dieAction = [CCSequence actions:
                        [CCFadeOut actionWithDuration:0.2f],
						[CCHide action],
						[CCCallFunc actionWithTarget:self selector:@selector(destroy)],
						nil];
		[self runAction:dieAction];
        
    } else {
        
        if (![name isEqualToString:@"Teleporter"] && ![name isEqualToString:@"Story-Point"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"IG Star and gem.caf" pitch:1.0f pan:0.0f gain:1.0f];
        [super remove];
    }
}

-(void) destroy
{
    [self remove];
	[[GameLayer getInstance] removeRobot:self];
}

-(void) die {
	if (!removed) {
		[self unschedule:@selector(update:)];
	}
}

// collision handling
-( void )handleBeginCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
        
        case kGameObjectNone:
            if (shooted) [ self remove ]; // Remove when we hit map edges since we cannot let it go through
            break;
            
        case kGameObjectPlayer:
            touchingPlayer = YES;
            [ self touched:object ];
            break;
            
        case kGameObjectBullet:
            if ( ( self.physics || self.solid) && ( !self.sensor ) ) {
                [ self hit:( ( Bullet* )object ).damage ];
                [ ( Bullet* )object die ];
            }
            break;
            
        default:
            if ( data.position == CONTACT_IS_BELOW ) touching = touchingFloor;
            else if ( data.position == CONTACT_IS_ABOVE ) touching = touchingSomethingTop;
            else if ( data.position == CONTACT_IS_LEFT ) touching = touchingSomethingLeft;
            else if ( data.position == CONTACT_IS_RIGHT ) touching = touchingSomethingRight;
            
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

-( void )handleEndCollision:( contactData )data {
    GameObject* object = ( GameObject* )data.object;
    
    // case handling
    switch ( object.type ) {
            
        case kGameObjectPlayer:
            touchingPlayer = NO;
            break;
            
        default:
            if ( ( data.position == CONTACT_IS_BELOW ) && ( touching == touchingFloor ) ) touching = touchingNone; 
            else if ( ( data.position == CONTACT_IS_ABOVE ) && ( touching == touchingSomethingTop ) ) touching = touchingNone;
            else if ( ( data.position == CONTACT_IS_LEFT ) && ( touching == touchingSomethingLeft ) ) touching = touchingNone;
            else if ( ( data.position == CONTACT_IS_RIGHT ) && ( touching == touchingSomethingRight ) ) touching = touchingNone;
            
            break;
    }
}

- (void)dealloc
{
	[behavior release];
    [originalData release];
    [parameters release];
	[msgCommands release];
	[msgName release];
	[timerCommands release];
	[name release];
    
    [super dealloc];
}

@end
