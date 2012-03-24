//
//  GameObject.m
//  SimpleBox2dScroller
//
//  Created by min on 3/17/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

#import "GameObject.h"
#import "GameLayer.h"

@implementation GameObject

@synthesize type;
@synthesize body;
@synthesize size;
@synthesize removed;
@synthesize spawned;

- (id)init
{
    self = [super init];
    if (self) {
        type = kGameObjectNone;
		firstTimeAdded = YES;
        spawned = NO;
    }
    
    return self;
}

-(void) createBox2dObject:(b2World*)world size:(CGSize)_size
{
	size = _size;
	
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = true;
	playerBodyDef.fixedRotation = true;
	playerBodyDef.type = b2_staticBody;
	playerBodyDef.position.Set(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO);
	playerBodyDef.userData = self;
	
	body = world->CreateBody(&playerBodyDef);
	
    // Define the box shape as edges
	b2Vec2 lowerLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), 0 - (size.height/2.0f/PTM_RATIO));
	b2Vec2 lowerRight = b2Vec2(size.width/2.0f/PTM_RATIO, 0 - (size.height/2.0f/PTM_RATIO));
	b2Vec2 upperRight = b2Vec2(size.width/2.0f/PTM_RATIO, size.height/2.0f/PTM_RATIO);
	b2Vec2 upperLeft = b2Vec2(0 - (size.width/2.0f/PTM_RATIO), size.height/2.0f/PTM_RATIO);
    
	b2EdgeShape groundBox;		
	
	// bottom
	groundBox.Set(lowerLeft, lowerRight);
	body->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(upperRight, upperLeft);
	body->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(upperLeft, lowerLeft);
	body->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(lowerRight, upperRight);
	body->CreateFixture(&groundBox,0);
    
    // add extra edges to avoid bullets going through on single tile blocks
    if (size.width > MAP_TILE_WIDTH) {
        // left
        groundBox.Set(upperLeft + b2Vec2(MAP_TILE_WIDTH/PTM_RATIO, 0), lowerLeft + b2Vec2(MAP_TILE_WIDTH/PTM_RATIO, 0));
        body->CreateFixture(&groundBox,0);
        
        // right
        groundBox.Set(lowerRight - b2Vec2(MAP_TILE_WIDTH/PTM_RATIO, 0), upperRight - b2Vec2(MAP_TILE_WIDTH/PTM_RATIO, 0));
        body->CreateFixture(&groundBox,0);
        
    } else {
        // Add cross edge to avoid bullets going through
        groundBox.Set(lowerRight, upperRight - b2Vec2(MAP_TILE_WIDTH/PTM_RATIO, 0));
        body->CreateFixture(&groundBox,0); 
        
        groundBox.Set(lowerRight - b2Vec2(MAP_TILE_WIDTH/PTM_RATIO, 0), upperRight);
        body->CreateFixture(&groundBox,0); 
    }
    
    /*
	b2PolygonShape shape;
	shape.SetAsBox((size.width/2.0)/PTM_RATIO, (size.height/2.0f)/PTM_RATIO);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0;
	fixtureDef.restitution = 0.0; // bouncing
	body->CreateFixture(&fixtureDef);
	*/
    
	removed = NO;
}

/* Handles lock box2d actions */
-(BOOL) applyPendingBox2dActions
{
    if (flagToDestroyBody) {
        flagToDestroyBody = NO;
        [GameLayer getInstance].world->DestroyBody(body);
        
        return NO;
    }  
    
    if (flagToTransformBody) {
        flagToTransformBody = NO;
        body->SetTransform(tranformPosition, tranformAngle);
    }
    
    if (flagToRecreateBody) {
        flagToRecreateBody = NO;
        [GameLayer getInstance].world->DestroyBody(body);
        [self createBox2dObject:[GameLayer getInstance].world size:recreateSize];
    }
    
    return YES;
}

/* Marks the box2d body to be destroyed */
-(void) markToDestroyBody
{
    flagToDestroyBody = YES;
}

/* Marks the box2d body to be transformed */
-(void) markToTransformBody:(b2Vec2)position angle:(float)angle
{
    flagToTransformBody = YES;
    tranformPosition = position;
    tranformAngle = angle;
}

/* Marks the box2d body to be destroyed and recreated with new size */
-(void) markToRecreateBody:(CGSize)newSize
{
    flagToRecreateBody = YES;
    recreateSize = newSize;
}

/* Remove the object fron scene but keep it hidden for reset */
-(void) remove
{
    self.visible = NO;
    [self stopAllActions];
    
    if (removed) return;

	removed = YES;
	body->SetLinearVelocity(b2Vec2(0.0f, 0.0f));
    [self markToDestroyBody];
}

/* Completely remove the object from scene */
-(void) destroy {
    [self remove];
    [self removeFromParentAndCleanup:YES];
}

/* Restart makes the object to reapear on scene on original place with original status */
-(void) restart
{   
	if (removed) {
		[self createBox2dObject:[GameLayer getInstance].world size:size];
		self.position = originalPosition;
        [self markToTransformBody:b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO) angle:0.0];
		self.visible = YES;
		removed = NO;
		
	} else {
		self.position = originalPosition;
        [self markToTransformBody:b2Vec2(self.position.x/PTM_RATIO, self.position.y/PTM_RATIO) angle:0.0];
	}
}

-(void) setPosition:(CGPoint)pos
{
	[super setPosition:pos];
	
	if (firstTimeAdded) {
		originalPosition = self.position;
		firstTimeAdded = NO;
	}
}

-(BOOL) interacted { 
    return NO;
}

-(CGPoint) getTilePosition 
{
    int dx = self.position.x * CC_CONTENT_SCALE_FACTOR() / MAP_TILE_WIDTH * CC_CONTENT_SCALE_FACTOR();
    int dy = [ GameLayer getInstance ].mapHeight - ( self.position.y * CC_CONTENT_SCALE_FACTOR() / MAP_TILE_HEIGHT * CC_CONTENT_SCALE_FACTOR() );
    
    return ccp(dx,dy);
}

-(void) update:(ccTime)dt
{
	if (body->GetType() != b2_staticBody) {
		self.position = ccp(body->GetPosition().x * PTM_RATIO, body->GetPosition().y * PTM_RATIO);
		//self.rotation =  -1 * CC_RADIANS_TO_DEGREES(body->GetAngle()); // We don't rotate, so we can save this
        //body->SetTransform(body->GetPosition(), 0);
	}
}

// override for functionality
-( void )handleBeginCollision:( contactData )data { }
-( void )handlePreSolve:( contactData )data manifold:(const b2Manifold *)oldManifold { }
-( void )handlePostSolve:( contactData )data impulse:(const b2ContactImpulse *)impulse { }
-( void )handleEndCollision:( contactData )data { }

- (void)dealloc
{
    [super dealloc];
}

@end
