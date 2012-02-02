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
#import "SimpleAudioEngine.h"

#define FLASH_VELOCITY_FACTOR	50.0f
#define DELAY_FACTOR			2000.0f

@implementation Robot

@synthesize solid;
@synthesize ignoreGravity;

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
	playerBodyDef.type = b2_dynamicBody;
	
	playerBodyDef.position.Set(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO);
	playerBodyDef.userData = self;
	body = [GameLayer getInstance].world->CreateBody(&playerBodyDef);
	
	if (ignoreGravity) body->SetGravityScale(0.0f);
	
	//if (solid) {
		b2PolygonShape shape;
		shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0)/PTM_RATIO);
		b2FixtureDef fixtureDef;
		fixtureDef.shape = &shape;
		fixtureDef.density = 1.0;
		fixtureDef.friction = 0.0;
		fixtureDef.restitution = 0.0; // bouncing
		fixtureDef.isSensor = false;
		body->CreateFixture(&fixtureDef);
	/*	
	} else {
		b2PolygonShape shape;
		shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
		b2FixtureDef fixtureDef;
		fixtureDef.shape = &shape;
		fixtureDef.density = 1.0;
		fixtureDef.friction = 0.0;
		fixtureDef.restitution = 0.0; // bouncing
		fixtureDef.isSensor = true;
		body->CreateFixture(&fixtureDef);
	 }
	 */
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	size = _size;
	
	[self _recreateBody];
	
	removed = NO;
}

-(void) setupRobot:(NSDictionary *)data
{
	//CCLOG(@"Robot.setupRobot: %@", data);
	
	// default values
	health = 100;	
	solid = NO;
	ignoreGravity = YES;
	immortal = NO;
	
	if ([data objectForKey:@"behavior"]) {
		behavior = [[data objectForKey:@"behavior"] retain];
	} else {
		behavior = [[NSArray array] retain];
	}
	
	if ([data objectForKey:@"properties"]) {
		health = [[[data objectForKey:@"properties"] objectForKey:@"health"] intValue];
		immortal = [[[data objectForKey:@"properties"] objectForKey:@"immortal"] boolValue];
		solid = [[[data objectForKey:@"properties"] objectForKey:@"solid"] boolValue];
		ignoreGravity = ![[[data objectForKey:@"properties"] objectForKey:@"physics"] boolValue];
		
		CCLOG(@"Robot.immortal: %i", immortal);
		CCLOG(@"Robot.solid: %i", solid);
		CCLOG(@"Robot.ignoreGravity: %i", ignoreGravity);
	}
	
	facingLeft = YES;
	
	onMessage = NO;
	onTouchStart = NO;
	onInShot = NO;
	
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
		
		NSString *name = [event objectForKey:@"event"];
		
		if ([name isEqualToString:@"onSpawn"]) {
			[self resolve:i];
			
		} else if ([name isEqualToString:@"onMessage"]) {
			[msgName addObject:[event objectForKey:@"messageName"]];
			[msgCommands addObject:[event objectForKey:@"commands"]];
			
		} else if ([name isEqualToString:@"onDie"]) {
			onDieCommands = [event objectForKey:@"commands"];
			
		}
	}
}

-(void) update:(ccTime)dt
{
	if (removed) return;
	
	CGSize winsize = [[CCDirector sharedDirector] winSize];
	CGPoint pos = [[GameLayer getInstance] convertToMapCoordinates:self.position];
	
	if (!CGRectContainsPoint(mapRect, self.position)) {
		[self remove];
	}
	
	if (pos.x + self.contentSize.width < 0) {
		if (self.visible) {
			self.visible = NO;
			onInShot = NO;
			[self stopAllActions];
			
		}
		return;
		
		
	} else if (pos.x - self.contentSize.width > winsize.width) {
		if (self.visible) {
			self.visible = NO;
			onInShot = NO;
			[self stopAllActions];
		}
		return;
		
	} else if (pos.y + self.contentSize.height < 0) {
		if (self.visible) {
			self.visible = NO;
			onInShot = NO;
			[self stopAllActions];
			
		}
		return;
		
		
	} else if (pos.y - self.contentSize.height > winsize.height) {
		if (self.visible) {
			self.visible = NO;
			onInShot = NO;
			[self stopAllActions];
		}
		return;
		
	} else {
		if (!self.visible) self.visible = YES;
		
		if (!onInShot) {
			int totalEvents = [behavior count];
			for (int i=0; i<totalEvents; i++) {
				NSDictionary *event = (NSDictionary *)[behavior objectAtIndex:i];
				//CCLOG(@"%@", event);
				
				NSString *name = [event objectForKey:@"event"];
				
				if ([name isEqualToString:@"onInShot"]) {
					[self resolve:i];
				}
				
				onInShot = YES;
			}
		}
	}

	//if (walkNode != CGPointZero) {
	//}
	
	b2Vec2 current = body->GetLinearVelocity();
	if (current.x > 0) {
		facingLeft = NO;
		
	} else if (current.x < 0) {
		facingLeft = YES;
	}
	
	[super update:dt];
}

-(id) runMethod:(NSString *)name withObject:(id)anObject
{
	NSString *method;
	
	if (anObject != nil) method = [NSString stringWithFormat:@"%@:", name];
	else method = name;
	
	SEL selector = NSSelectorFromString(method);
	if ([self respondsToSelector:selector]) {
		
		id result;
		if (anObject != nil) result = [self performSelector:selector withObject:anObject];
		else result = [self performSelector:selector];
		
		//CCLOG(@"Robot: calling selector: %@ with parameter: %@ and result: %@", method, anObject, result);
		//CCLOG(@"Robot: calling selector: %@ with parameter: %@", method, anObject);
		return result;
		
	} else {
		//CCLOG(@"Robot: undeclared selector: %@", method);
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
		NSString *name = [event objectForKey:@"event"];
		
		if ([name isEqualToString:eventType]) {
			
			if (![name isEqualToString:@"onTouchStart"]) {
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

-(BOOL) isSolid:(id)obj
{
	return solid;
}

-(BOOL) beNotSolid:(id)obj
{
	solid = NO;

	/*
	id action = [CCSequence actions:
			 [CCDelayTime actionWithDuration:1.0/60.0],
			 [CCCallFunc actionWithTarget:self selector:@selector(_changeBody)],
			 nil];

	[self runAction:action];
	*/
	
	return solid;
}

-(BOOL) beSolid:(id)obj
{
	solid = YES;
	
	/*
	id action = [CCSequence actions:
			 [CCDelayTime actionWithDuration:1.0/60.0],
			 [CCCallFunc actionWithTarget:self selector:@selector(_changeBody)],
			 nil];

	[self runAction:action];
	*/
	
	return solid;
}

/*
-(void) _changeBody
{
	[GameLayer getInstance].world->DestroyBody(body);
	
	[self _recreateBody];
}
*/

-(void) say:(id)obj
{
	//TODO: pending
}

-(void) think:(id)obj
{
	//TODO: pending
}

-(void) askMultichoice:(NSDictionary *)comman
{
	//TODO: pending
}

-(NSNumber *) isVisible:(id)obj
{
	return [NSNumber numberWithBool:self.visible];
}

-(NSNumber *) goVisible:(id)obj
{
	self.visible = YES;
	return [NSNumber numberWithBool:self.visible];
}

-(NSNumber *) goInvisible:(id)obj
{
	self.visible = NO;
	return [NSNumber numberWithBool:self.visible];
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

-(NSMutableArray *) thisLocation:(NSDictionary *)obj
{
	NSMutableArray *pos = [NSMutableArray arrayWithCapacity:2];
	[pos addObject:[NSNumber numberWithFloat:self.position.x]];
	[pos addObject:[NSNumber numberWithFloat:self.position.y]];
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

-(CGPoint) locationOfInstance:(NSDictionary *)obj 
{
	NSDictionary *instance = [obj objectForKey:@"instance"];
	NSString *token = [instance objectForKey:@"token"];
	
	if ([token isEqualToString:@"player"]) {
		return [[GameLayer getInstance] playerPosition];
		
	} else {
		return CGPointZero;
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
	
	if (!immortal) [self remove];
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

	if (health < 0) [self remove];
	
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
	//TODO: pending
}

-(void) changeTime:(NSDictionary *)command 
{
	//TODO: pending
}

-(void) teleport:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
	NSMutableArray *position = [self runMethod:token withObject:location];
	
	auxX = [[position objectAtIndex:0] floatValue];
	auxY = [[position objectAtIndex:1] floatValue];
	
	id action = [CCSequence actions:
					  [CCDelayTime actionWithDuration:1.0/60.0],
					  [CCCallFunc actionWithTarget:self selector:@selector(_changePosition)],
					  nil];
	
	[self runAction:action];
}

-(void) teleportInstance:(NSDictionary *)command 
{
	NSDictionary *location = [command objectForKey:@"location"];
	NSString *token = [location objectForKey:@"token"];
	
	NSMutableArray *position = [self runMethod:token withObject:location];
	
	auxX = [[position objectAtIndex:0] floatValue];
	auxY = [[position objectAtIndex:1] floatValue];
	
	if ([[[command objectForKey:@"instance"] objectForKey:@"token"] isEqualToString:@"player"]) {
	
		id action = [CCSequence actions:
				 [CCDelayTime actionWithDuration:1.0/60.0],
				 [CCCallFunc actionWithTarget:self selector:@selector(_changePosition)],
				 nil];
	
		[self runAction:action];
	}
}

-(void) _changePosition
{
	CGPoint pos = ccp(auxX, auxY);
	body->SetTransform(b2Vec2(((pos.x - 30)/PTM_RATIO), (pos.y + 0)/PTM_RATIO),0);
	
	self.position = pos;
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
}

-(void) changeXvelocity:(NSDictionary *)command 
{
	float speed;
	
	if ([[command objectForKey:@"delta"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delta"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"velocity"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"delta"] floatValue];
	}
	
	b2Vec2 current = body->GetLinearVelocity();
	b2Vec2 velocity = b2Vec2(current.x + speed / FLASH_VELOCITY_FACTOR, current.y);
	body->SetLinearVelocity(velocity);
}

-(void) changeYvelocity:(NSDictionary *)command 
{
	float speed;
	
	if ([[command objectForKey:@"delta"] isKindOfClass:[NSDictionary class]]) {
		
		NSString *token = [[command objectForKey:@"delta"] objectForKey:@"token"];
		NSNumber *num = [self runMethod:token withObject:[command objectForKey:@"velocity"]];
		speed = [num floatValue];
		
	} else {
		speed = [[command objectForKey:@"delta"] floatValue];
	}
	
	b2Vec2 current = body->GetLinearVelocity();
	b2Vec2 velocity = b2Vec2(current.x, current.y - speed / FLASH_VELOCITY_FACTOR);
	body->SetLinearVelocity(velocity);
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

-(void) freezePhysics:(id)obj
{
	//TODO: pending
}

-(void) unfreezePhysics:(id)obj
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
	[self receiveMessage:[command objectForKey:@"message"]];
}

-(void) messageSelfAfterDelay:(NSDictionary *)command 
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
	
	id action = [CCSequence actions:
				 [CCDelayTime actionWithDuration:delay/DELAY_FACTOR],
				 [CCCallFunc actionWithTarget:self selector:@selector(_delayedMessage)],
				 nil];
	
	[self runAction:action];
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
	
	id action = [CCSequence actions:
				 [CCDelayTime actionWithDuration:delay/DELAY_FACTOR],
				 [CCCallFunc actionWithTarget:self selector:@selector(_delayedBroadcast)],
				 nil];
	
	[self runAction:action];
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

#pragma mark -
#pragma mark Events

-(void) touched:(id)sender
{
	//CCLOG(@"Robot.touched: %@", behavior);
	if (!onTouchStart) {
		[self execute:@"onTouchStart" type:kGameObjectPlayer];
		onTouchStart = YES;
	}
    
    b2Vec2 current = body->GetLinearVelocity();
    if ((current.x == 0) && (current. y == 0)) {
        wasMoving = NO;
    } else {
        wasMoving = YES;
    }
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
	
	if (health < 0) [self die:nil];
}


#pragma mark -
#pragma mark Reset

-(void) resetPosition
{
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
}

-(void) remove
{
	[self stopAllActions];
	[super remove];
}

- (void)dealloc
{
	[behavior release];
	[msgCommands release];
	[msgName release];
	[andToken release];
	[orToken release];
	[timerCommands release];
	
    [super dealloc];
}

@end