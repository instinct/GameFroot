//
//  GameLayer.m
//  DoubleHappy
//
//  Created by Jose Miguel on 08/09/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "GameLayer.h"
#import "GameMenu.h"
#import "HomeLayer.h"
#import "Shared.h"
#import "CJSONDeserializer.h"
#import "Constants.h"
#import "Player.h"
#import "Enemy.h"
#import "Bullet.h"
#import "GameObject.h"
#import "MovingPlatform.h"
#import "Switch.h"
#import "Dialogue.h"
#import "MultiChoice.h"
#import "CheckPoint.h"
#import "Collectable.h"
#import "Robot.h"
#import "Loader.h"
#import "Win.h"
#import "Lose.h"
#import "Controls.h"
#import "Pause.h"
#import "NextLevel.h"
#import "IntermediateLayer.h"
#import "Completed.h"
#import "SimpleAudioEngine.h"
//#import "InputController.h"

#define PLAYER_COLLISION				1
#define HORIZONTAL_PLATFORM_COLLISION	2
#define VERTICAL_PLATFORM_COLLISION		3
#define STATIC_OBJECTS_COLLISION		4

#define BG_MUSIC_VOL 0.4f
#define BG_MUSIC_DIP 0.2f

#define HEALTH_BAR_MAXLENGTH 100.0f

// GameLayer implementation
@implementation GameLayer

GameLayer *instance;

@synthesize controls;
@synthesize points;
@synthesize totalPoints;
@synthesize mapWidth;
@synthesize mapHeight;
@synthesize world;
@synthesize hudSpriteSheet;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

#pragma mark -
#pragma mark Box2D

-(void) setupWorld {
	// Setup world
	gravity = b2Vec2(0.0f, -15.0f);
	world = new b2World(gravity);
	
	contactListener = new ContactListener();
    world->SetContactListener(contactListener);
}

-(void) setupDebugDraw {
	debugDraw = new GLESDebugDraw(PTM_RATIO * REDUCE_FACTOR * CC_CONTENT_SCALE_FACTOR());
	world->SetDebugDraw(debugDraw);
	debugDraw->SetFlags(b2Draw::e_shapeBit);
}

-(void) createGround:(CGSize)size {
	
	float width = size.width;
	float height = size.height + 100.0f;
	
	float32 margin = 1.0f;
	b2Vec2 lowerLeft = b2Vec2(margin/PTM_RATIO, margin/PTM_RATIO);
	b2Vec2 lowerRight = b2Vec2((width-margin)/PTM_RATIO,margin/PTM_RATIO);
	b2Vec2 upperRight = b2Vec2((width-margin)/PTM_RATIO, (height-margin)/PTM_RATIO);
	b2Vec2 upperLeft = b2Vec2(margin/PTM_RATIO, (height-margin)/PTM_RATIO);
	
	b2BodyDef groundBodyDef;
	groundBodyDef.type = b2_staticBody;
	groundBodyDef.position.Set(0, 0);
	groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;
    
	// bottom
	groundBox.Set(lowerLeft, lowerRight);
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(upperRight, upperLeft);
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(upperLeft, lowerLeft);
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(lowerRight, upperRight);
	groundBody->CreateFixture(&groundBox,0);
	
	
	// Create ground killing floor
	GameObject *floor = [GameObject node];
	floor.position = ccp(size.width/2, 0.5f);
	[floor createBox2dObject:world size:CGSizeMake(width, 1.0f)];
	[floor setType:kGameObjectKiller];
	[self addChild:floor];
	
}

-(void) cleanup
{
    //Iterate over the bodies in the physics world and remove all spawned
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
		if (b->GetUserData() != NULL) {
			GameObject *sprite = (GameObject*)b->GetUserData();
            if (sprite.spawned) {
                world->DestroyBody(b);
                [sprite destroy];
            }
		}
	}    
}

-(void) update:(ccTime)dt {
    
    //It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	double delta = dt;
	//double delta = 1.0 / 60.0;
	world->Step(delta, velocityIterations, positionIterations);
	
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
		if (b->GetUserData() != NULL) {
            // Synchronize the sprites position and rotation with the corresponding body.
            // Pending box2d actions will destroy or transform the body if necessary.
			GameObject *sprite = (GameObject*)b->GetUserData();
            if ([sprite applyPendingBox2dActions]) [sprite update:dt];
		}
	}
    
    [self setViewpointCenter];
}

-(void) timer:(ccTime)dt {
	seconds -= dt;
	if (seconds <= 0) {
		seconds = 0;
	}
	[self setTimer:seconds];
	
	if (seconds == 0) {
		[player lose];
	}
}

-(void) draw {
    
    /*
    if (DEBUG_WORLD) {
        glColor4f(1, 1, 1, 1);
        
        for (int x = 0; x < mapWidth; x++) {
            ccDrawLine(ccp(x*MAP_TILE_WIDTH*REDUCE_FACTOR, 0), ccp(x*MAP_TILE_WIDTH*REDUCE_FACTOR, mapHeight*MAP_TILE_HEIGHT*REDUCE_FACTOR));
        }
        
        for (int y = 0; y < mapHeight; y++) {
            ccDrawLine(ccp(0, y*MAP_TILE_HEIGHT*REDUCE_FACTOR), ccp(mapWidth*MAP_TILE_WIDTH*REDUCE_FACTOR, y*MAP_TILE_HEIGHT*REDUCE_FACTOR));
        }
    }
    */
    
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
	world->DrawDebugData();
    
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

#pragma mark -
#pragma mark Init

+(GameLayer *)getInstance {
	return instance;
}

// on "init" you need to initialize your instance
-(id) init
{    
	[[CCDirector sharedDirector] setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];

	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
        //CCLOG(@"GameLayer.init: %@", self);
        
		instance = self;
		
        // Check what server to use, if staging or live
        /*
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if([Shared isBetaMode]) {
            serverUsed = [prefs integerForKey:@"server"];
        } else {
            serverUsed = 1;
        }
        */
        
		// Check if we need to download the level data or use cache
		ignoreCache = YES;		
		/*
        NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(SAVE_FOLDER, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *resource = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cachedLevel%i",[Shared getLevelID]]];
		CCLOG(@"Find if level cache is expired: %@", resource);
		if ([fileManager fileExistsAtPath:resource]) {
			NSString *cachedDate = [NSString stringWithContentsOfFile:resource encoding:NSASCIIStringEncoding error:nil];
			CCLOG(@"%@ == %@ ? %i", cachedDate, [Shared getLevelDate], [cachedDate isEqualToString:[Shared getLevelDate]]);
			if ([cachedDate isEqualToString:[Shared getLevelDate]]) {
				// Level not changed since last download, so use cached contents
                ignoreCache = NO;
			}
		}
        */
		
		// Initialise properties dictionary
		NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
		NSString *plistPath = [mainBundlePath stringByAppendingPathComponent:@"properties.plist"];
		properties = [[[NSDictionary alloc] initWithContentsOfFile:plistPath] retain];
		
		// Tiles ids
		//NSString *tilesIdsPath = [mainBundlePath stringByAppendingPathComponent:@"iphone_tiles.json"];
		NSString *tilesIdsPath = [mainBundlePath stringByAppendingPathComponent:@"tiles.json"];
		NSString *dataTilesIds = [NSString stringWithContentsOfFile:tilesIdsPath encoding:NSASCIIStringEncoding error:nil];
		NSData *rawTilesData = [dataTilesIds dataUsingEncoding:NSUTF8StringEncoding];
		NSArray *arrayTilesIds = [[CJSONDeserializer deserializer] deserializeAsArray:rawTilesData error:nil];
		int countTiles = [arrayTilesIds count];
		tilesIds = [[NSMutableDictionary dictionaryWithCapacity:countTiles] retain];
		for (int i=0; i < countTiles; i++) {
			NSDictionary *values = (NSDictionary *)[arrayTilesIds objectAtIndex:i];
			//CCLOG(@"tile id %@ map to %@", [values objectForKey:@"id"], [values objectForKey:@"sprite_id"]);
			[tilesIds setObject:[values objectForKey:@"sprite_id"] forKey:[values objectForKey:@"id"]];
		}
		
		// Items ids
		//NSString *itemsIdsPath = [mainBundlePath stringByAppendingPathComponent:@"iphone_items.json"];
		NSString *itemsIdsPath = [mainBundlePath stringByAppendingPathComponent:@"items.json"];
		NSString *dataItemsIds = [NSString stringWithContentsOfFile:itemsIdsPath encoding:NSASCIIStringEncoding error:nil];
		NSData *rawItemsData = [dataItemsIds dataUsingEncoding:NSUTF8StringEncoding];
		NSArray *arrayItemsIds = [[CJSONDeserializer deserializer] deserializeAsArray:rawItemsData error:nil];
		int countItems = [arrayItemsIds count];
		itemsIds = [[NSMutableDictionary dictionaryWithCapacity:countItems] retain];
		for (int i=0; i < countItems; i++) {
			NSDictionary *values = (NSDictionary *)[arrayItemsIds objectAtIndex:i];
			//CCLOG(@"item id %@ map to %@", [values objectForKey:@"id"], [values objectForKey:@"sprite_id"]);
			int spriteId = [[values objectForKey:@"sprite_id"] intValue] + (SPRITESHEETS_TILE_WIDTH * 5);
			[itemsIds setObject:[NSNumber numberWithInt:spriteId] forKey:[values objectForKey:@"id"]];
		}
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		self.isTouchEnabled = NO;
		self.isAccelerometerEnabled = NO;
		
		enemies = [[CCArray array] retain];
		items = [[CCArray array] retain];
		movingPlatforms = [[CCArray array] retain];
		robots = [[CCArray array] retain];
		switches = [[NSMutableDictionary dictionary] retain];
		bullets = [[CCArray array] retain];
		cached = [[NSMutableDictionary dictionary] retain];
        
		// Init containers
		scene = [CCParallaxNode node];
		[self addChild:scene z:-1];
		
		background = [CCNode node];
		[scene addChild:background z:1 parallaxRatio:ccp(0.0f, 0.0f) positionOffset:CGPointZero];
		
		objects = [CCNode node];
		objects.scale = REDUCE_FACTOR;
		//[self addChild:objects z:10];
		[scene addChild:objects z:2 parallaxRatio:ccp(1.0f, 1.0f) positionOffset:CGPointZero];
		
		hud = [CCNode node];
		//[self addChild:hud z:10000];
		[scene addChild:hud z:3 parallaxRatio:ccp(0.0f, 0.0f) positionOffset:CGPointZero];
		
        pauseCover = [Pause node];
		[hud addChild:pauseCover z:1000];
		[pauseCover hide];
		
		//
		seconds = 180;
		points = 0;
		ammo = 100;
		timerEnabled = NO;
		lock = NO;
        checkpoints = NO;
		paused = YES;
        
        //
        cameraBehaviour = kCameraFollowPlayer;
        cameraLocation = CGPointZero;
        cameraXOffset = 0;
        cameraYOffset = 0;
        
        //
		pauseBtn = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"pause.png"] selectedSprite:[CCSprite spriteWithFile:@"pause.png"] target:self selector:@selector(pauseGame)];
		[[(CCSprite *)pauseBtn.normalImage texture] setAliasTexParameters];
		((CCSprite *)pauseBtn.normalImage).opacity = 100;
		[[(CCSprite *)pauseBtn.selectedImage texture] setAliasTexParameters];
		CCMenu *menu = [CCMenu menuWithItems:pauseBtn, nil];
		//[menu setPosition:ccp(size.width - pauseBtn.contentSize.width/2, size.height - pauseBtn.contentSize.height*2)];
		[menu setPosition:ccp(size.width/2 + pauseBtn.contentSize.width + 20.0f, size.height - pauseBtn.contentSize.height + 5.0f)];
		[hud addChild:menu z:5];
		
		livesLabel = [CCLabelBMFont labelWithString:@"00xHD" fntFile:@"hud.fnt"];
		[livesLabel setPosition: ccp(livesLabel.contentSize.width/2 + 5, size.height - livesLabel.contentSize.height/2)];
		[livesLabel.textureAtlas.texture setAliasTexParameters];
		[hud addChild:livesLabel z:1];
		
		pointsLabel = [CCLabelBMFont labelWithString:@"000000" fntFile:@"hud.fnt"];
		[pointsLabel setPosition: ccp(size.width - pointsLabel.contentSize.width/2 - 5, size.height - pointsLabel.contentSize.height/2)];
		[pointsLabel.textureAtlas.texture setAliasTexParameters];
		[hud addChild:pointsLabel z:2];
		[self increasePoints:points];
		
		timerLabel = [CCLabelBMFont labelWithString:@" " fntFile:@"hud.fnt"];
		[timerLabel setPosition: ccp(size.width/2, size.height - timerLabel.contentSize.height/2)];
		[timerLabel.textureAtlas.texture setAliasTexParameters];
		[hud addChild:timerLabel z:2];
		[self setTimer:seconds];
		timerLabel.visible = NO;
		
		hudSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"hud_spritesheet.png"];
		[hudSpriteSheet.textureAtlas.texture setAliasTexParameters];
		[hud addChild:hudSpriteSheet z:10];
		
		controls = [Controls controlsWithFile:@"controls.png"];
		[controls.textureAtlas.texture setAliasTexParameters];
		[hud addChild:controls z:500];
		
		//
		barBGLeft = [CCSprite spriteWithSpriteFrameName:@"FatBarBGLeft.png"];
		barBGMiddle = [CCSprite spriteWithSpriteFrameName:@"FatBarBGMiddle.png"];
		barBGRight = [CCSprite spriteWithSpriteFrameName:@"FatBarBGRight.png"];
		[hudSpriteSheet addChild:barBGLeft];
		[hudSpriteSheet addChild:barBGMiddle];
		[hudSpriteSheet addChild:barBGRight];
		
		barBGMiddle.anchorPoint = ccp(0.0, 0.5);
		barBGMiddle.scaleX = 101;
		[barBGLeft setPosition:ccp(livesLabel.position.x + livesLabel.contentSize.width - 15, livesLabel.position.y + 2)];
		[barBGMiddle setPosition:ccp(barBGLeft.position.x + barBGLeft.contentSize.width/2, barBGLeft.position.y)];
		[barBGRight setPosition:ccp(barBGMiddle.position.x + barBGMiddle.contentSize.width * barBGMiddle.scaleX, barBGMiddle.position.y)];
		
		barLeft = [CCSprite spriteWithSpriteFrameName:@"FatBarLeft.png"];
		barMiddle = [CCSprite spriteWithSpriteFrameName:@"FatBarMiddle.png"];
		barRight = [CCSprite spriteWithSpriteFrameName:@"FatBarRight.png"];
		[hudSpriteSheet addChild:barLeft];
		[hudSpriteSheet addChild:barMiddle];
		[hudSpriteSheet addChild:barRight];
		
		barMiddle.anchorPoint = ccp(0.0, 0.5);
		barMiddle.scaleX = 100;
		[barLeft setPosition:ccp(barBGLeft.position.x + 1, barBGLeft.position.y + 0.5)];
		[barMiddle setPosition:ccp(barLeft.position.x + barLeft.contentSize.width/2, barLeft.position.y)];
		[barRight setPosition:ccp(barMiddle.position.x + barMiddle.contentSize.width * barMiddle.scaleX, barMiddle.position.y)];
		
		//
        ammoIcon = [CCSprite spriteWithSpriteFrameName:@"GunIcon.png"];
		[hudSpriteSheet addChild:ammoIcon];
		[ammoIcon setPosition:ccp(ammoIcon.contentSize.width/2 + 5, livesLabel.position.y - livesLabel.contentSize.height/2 - ammoIcon.contentSize.height/2 + 10)];
		
		ammoBarBGLeft = [CCSprite spriteWithSpriteFrameName:@"ThinBarBGLeft.png"];
		ammoBarBGMiddle = [CCSprite spriteWithSpriteFrameName:@"ThinBarBGMiddle.png"];
		ammoBarBGRight = [CCSprite spriteWithSpriteFrameName:@"ThinBarBGRight.png"];
		[hudSpriteSheet addChild:ammoBarBGLeft];
		[hudSpriteSheet addChild:ammoBarBGMiddle];
		[hudSpriteSheet addChild:ammoBarBGRight];
		
		ammoBarBGMiddle.anchorPoint = ccp(0.0, 0.5);
		ammoBarBGMiddle.scaleX = 80;
		[ammoBarBGLeft setPosition:ccp(ammoIcon.position.x + ammoIcon.contentSize.width - 15, ammoIcon.position.y + 5)];
		[ammoBarBGMiddle setPosition:ccp(ammoBarBGLeft.position.x + ammoBarBGLeft.contentSize.width/2, ammoBarBGLeft.position.y)];
		[ammoBarBGRight setPosition:ccp(ammoBarBGMiddle.position.x + ammoBarBGMiddle.contentSize.width * ammoBarBGMiddle.scaleX, ammoBarBGMiddle.position.y)];
		
		ammoBarLeft = [CCSprite spriteWithSpriteFrameName:@"ThinBarLeft.png"];
		ammoBarMiddle = [CCSprite spriteWithSpriteFrameName:@"ThinBarMiddle.png"];
		ammoBarRight = [CCSprite spriteWithSpriteFrameName:@"ThinBarRight.png"];
		[hudSpriteSheet addChild:ammoBarLeft];
		[hudSpriteSheet addChild:ammoBarMiddle];
		[hudSpriteSheet addChild:ammoBarRight];
		
		ammoBarMiddle.anchorPoint = ccp(0.0, 0.5);
		ammoBarMiddle.scaleX = 79;
		[ammoBarLeft setPosition:ccp(ammoBarBGLeft.position.x + 1, ammoBarBGLeft.position.y + 0.5)];
		[ammoBarMiddle setPosition:ccp(ammoBarLeft.position.x + ammoBarLeft.contentSize.width/2, ammoBarLeft.position.y)];
		[ammoBarRight setPosition:ccp(ammoBarMiddle.position.x + ammoBarMiddle.contentSize.width * ammoBarMiddle.scaleX, ammoBarMiddle.position.y)];
        [self disableAmmo];
        
		// Setup loader screen
        nextLevelID = [Shared getNextLevelID];
        loadingNextLevel = nextLevelID > 0;
        
		if (loadingNextLevel) [self setupNextLevelScreen];
        else [self setupLoadingScreen];
		
		// Init Box2D
		[self setupWorld];
		if (DEBUG_WORLD) [self setupDebugDraw];
		
	}
	return self;
}

-(NSString *) returnServer
{
    return serverUsed == 1 ? [properties objectForKey:@"server_live"] : [properties objectForKey:@"server_staging"];
}

-(void)music: (id)sender {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setInteger:[sender selectedIndex] forKey:@"music"];
	[prefs synchronize];
	
	if ([sender selectedIndex] == 1) {
		[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
		
	} else {
		NSString *bgmusic = [data objectForKey:@"bgmusic"];
        if (![bgmusic isEqualToString:@""]) {
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:bgmusic loop:YES];
        }
	}
}

-(void)dpad: (id)sender {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setInteger:[sender selectedIndex] forKey:@"dpad"];
	[prefs synchronize];
	
	if ([sender selectedIndex] == 1) {
		useDPad = YES;
		
	} else {
		useDPad = NO;
	}
	
    [controls checkSettings];
}

-(void) setupLoadingScreen
{	
    CCLOG(@"GameLayer.setupLoadingScreen");
    
	// Loading
	mainMenu = [GameMenu node];
	[mainMenu setPosition:ccp(0,0)];
	[self addChild:mainMenu z:1000];
    [mainMenu resetProgressBar];
    [mainMenu playModeOn:NO];
    parts = 7;
    partsLoaded = 0;
    [mainMenu setProgressBar:0.0f];
    [self schedule:@selector(startLoading) interval:0.1f];    
}

-(void) removeLoadingScreen
{
    CCLOG(@"GameLayer.removeLoadingScreen");
    
	[self removeChild:mainMenu cleanup:YES];
    
    [self initControls];
    [self initGame];
    
    [hud show];
    [scene show];
    if (paused) [self resume];
    
    [player immortal];
}

-(void) setupNextLevelScreen
{	
    CCLOG(@"GameLayer.setupNextLevelScreen");
    
	// Loading
	nextLevel = [NextLevel node];
	[nextLevel setPosition:ccp(0,0)];
	[self addChild:nextLevel z:1001];
    [nextLevel resetProgressBar];
    parts = 7;
    partsLoaded = 0;
    [nextLevel setProgressBar:0.0f];
    [self schedule:@selector(startLoading) interval:0.1f];
}


-(void) removeNextLevelScreen
{
    CCLOG(@"GameLayer.removeNextLevelScreen");
    
	[self removeChild:nextLevel cleanup:YES];
    
    [self initControls];
    [self initGame];
    
    [hud show];
    [scene show];
    if (paused) [self resume];
    
    [player immortal];
}

-(void) startLoading
{
	[self unschedule:@selector(startLoading)];
	
	switch (partsLoaded) {
		case 0:
			if (loadingNextLevel) [self loadLevelData:nextLevelID];
            else [self loadLevelData:[Shared getLevelID]];
            
			break;
			
		case 1:
			[self loadBackgroundLevel];
			break;
			
		case 2:
			[self loadTilesLevel];
			break;
			
		case 3:
			[self createMapTiles];
			break;
			
		case 4:
			[self createMapItems];
			break;
			
		case 5:
			[self loadPlayer];
			break;
			
		case 6:
			[self loadEnemies];
			break;
	}
	
    /*
    if (DEBUG_WORLD) {
        for (int x = 0; x < mapWidth; x++) {
            for (int y = 0; y < mapHeight; y++) {
                if ((x > 14) && (x < 20)) { // ((x > 40) && (x < 50)) || 
                    if ((mapHeight-y-1) > 15) {
                        CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i,%i",x,(mapHeight-y-1)] fontName:@"Arial" fontSize:8.0f];
                        [self addChild:label];
                        [label setPosition:ccp(x*MAP_TILE_WIDTH*REDUCE_FACTOR + label.contentSize.width, y*MAP_TILE_HEIGHT*REDUCE_FACTOR + label.contentSize.height)];
                    }
                }
            }
        }
    }
    */
    
	partsLoaded++;
	float percent = ((float)partsLoaded / (float)parts) * 100.0f;
	
    if (loadingNextLevel) [nextLevel setProgressBar:percent];
    else [mainMenu setProgressBar:percent];
	
	CCLOG(@"Percent loaded: %f (%i of %i)", percent, partsLoaded, parts);
	
	if (partsLoaded >= parts) {
		// Init game
        if (!loadingNextLevel) [mainMenu playModeOn:YES];
        
	} else {		
		[self schedule:@selector(startLoading) interval:0.1f];
	}
	
}

-(int) getIntValue:(NSString *)value
{
    if ((value != nil) && ![value isMemberOfClass:[NSNull class]] && [value respondsToSelector:@selector(intValue)]) {
        return [value intValue];
        
    } else return 0;
}

-(void) loadLevelData:(int)gameID
{
	data = [[NSMutableDictionary dictionary] retain];
	[data setObject:[NSNumber numberWithInt:gameID] forKey:@"gameID"];
	
	// NSString *gameURL = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=json&map_id=%d", [self returnServer], gameID];
	//CCLOG(@"Load level: %@, ignore cache: %i", gameURL, ignoreCache);
	
    NSString *stringData;
    NSString *mapFilePath = [Shared findAsset:[NSString stringWithFormat:@"%@.map",[data objectForKey:@"gameID"]] withType:@"levels"];
    if(mapFilePath) {
        stringData = [NSString stringWithContentsOfFile:mapFilePath encoding:NSUTF8StringEncoding error:nil];
    } else {
        CCLOG(@"Error! cannot find map data!");
    }
    
    NSData *rawData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *jsonData = [[CJSONDeserializer deserializer] deserializeAsDictionary:rawData error:nil];
    
    if (!jsonData || ([jsonData objectForKey:@"map"] == nil) || [[jsonData objectForKey:@"map"] isMemberOfClass:[NSNull class]]) {
        
        if (![Shared connectedToNetwork]) {
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle: @"Server Connection" 
                                                                 message: @"We cannot connect to our servers, please review your internet connection." 
                                                                delegate: self 
                                                       cancelButtonTitle: @"Back" 
                                                       otherButtonTitles: nil] autorelease];
            [alertView show];
            return;
        } else {
            [[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
            return;
        }
    }
	
	//CCLOG(@"%@", [jsonData description]);
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load Header Data
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NSDictionary *headerData = [jsonData objectForKey:@"meta"];
	if (headerData) {
        
        
        NSArray *musicArray = [[jsonData objectForKey:@"sprites"] objectForKey:@"background_music"];
        if ((musicArray != nil) && [musicArray isKindOfClass:[NSArray class]] && [musicArray count] > 0) {
            
            NSDictionary *defaultMusicURL = [[headerData objectForKey:@"background"] objectForKey:@"default_music"];
            
            if ([defaultMusicURL isKindOfClass:[NSDictionary class]]) {
                
                musicData = [[NSMutableDictionary alloc] init];
                
                // Take care of default music 
                NSString *musicFileName = [NSString stringWithFormat:@"%@.mp3", [defaultMusicURL objectForKey:@"id"]];
                NSString *musicPath = [Shared findAsset:musicFileName withType:@"music"];
                if(musicPath) {
                    [musicData setValue:musicPath forKey:@"default"];
                } else {
                    [musicData setValue:@"" forKey:@"default"];
                }
                
                // Get all the paths for music
                for (NSDictionary *music in musicArray) {
                    musicFileName = [NSString stringWithFormat:@"%@.mp3", [defaultMusicURL objectForKey:@"id"]];
                    musicPath = [Shared findAsset:musicFileName withType:@"music"];
                    if(musicPath) {
                        [musicData setValue:musicPath forKey:[NSString stringWithFormat:@"%@",[music objectForKey:@"id"]]];
                    }
                }
                
                // now set the default music
                [data setObject:[musicData objectForKey:@"default"] forKey:@"bgmusic"];
                
            } else {
                [data setObject:@"" forKey:@"bgmusic"];
            }
            
            
		} else {
			[data setObject:@"" forKey:@"bgmusic"];
		}

        
        //CCLOG(@"musicData: %@", [musicData description]);
       
        
		CCLOG(@"Level music '%@'", [data objectForKey:@"bgmusic"]);
		
		int width = [[headerData objectForKey:@"width"] intValue];
		int height = [[headerData objectForKey:@"height"] intValue];
		
		NSString *backgroundFilename = [[headerData objectForKey:@"background"] objectForKey:@"image"];
		if ((backgroundFilename == nil) || [backgroundFilename isMemberOfClass:[NSNull class]]) {
			backgroundFilename = @"back0";
		}
		[data setObject:backgroundFilename forKey:@"mapBackground"];
		[data setObject:[NSNumber numberWithInt:width] forKey:@"mapWidth"];
		[data setObject:[NSNumber numberWithInt:height] forKey:@"mapHeight"];
		
		// Set map limits
		mapWidth = (int)[[data objectForKey:@"mapWidth"] intValue];
		mapHeight = (int)[[data objectForKey:@"mapHeight"] intValue];
		
		CCLOG(@"Map Size: %d, %d", mapWidth, mapHeight);
		
		// Add four walls to our screen
		[self createGround:CGSizeMake(mapWidth*MAP_TILE_WIDTH, mapHeight*MAP_TILE_HEIGHT)];
		
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load animations
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NSArray *arrayAnimationIds = [[jsonData objectForKey:@"sprites"] objectForKey:@"animations"];
	int countAnimations = [arrayAnimationIds count];
	animationsIds = [[NSMutableDictionary dictionaryWithCapacity:countAnimations] retain];
	for (int i=0; i < countAnimations; i++) {
		NSDictionary *values = (NSDictionary *)[arrayAnimationIds objectAtIndex:i];
		//CCLOG(@"animation id %@ map to %@", [values objectForKey:@"id"], [values objectForKey:@"sprite_id"]);
		[animationsIds setObject:[values objectForKey:@"sprite_id"] forKey:[values objectForKey:@"id"]];
		[animationsIds setObject:[values objectForKey:@"frame_count"] forKey:[NSString stringWithFormat:@"f_%@",[values objectForKey:@"id"]]];
	}
	//CCLOG(@"Animations: %@", [animationsIds description]);
	
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load robots
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NSArray *arrayRobotsIds = [[jsonData objectForKey:@"sprites"] objectForKey:@"robots"];
	int countRobots = [arrayRobotsIds count];
	robotsIds = [[NSMutableDictionary dictionaryWithCapacity:countRobots] retain];
	for (int i=0; i < countRobots; i++) {
		NSDictionary *values = (NSDictionary *)[arrayRobotsIds objectAtIndex:i];
		//CCLOG(@"robot id %@ with script %@", [values objectForKey:@"id"], [values objectForKey:@"script"]);
		[robotsIds setObject:[values objectForKey:@"script"] forKey:[values objectForKey:@"id"]];
	}
	//CCLOG(@"Robots: %@", [robotsIds description]);
    
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load Player
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//CCLOG(@"Player: %@", [[jsonData objectForKey:@"map"] objectForKey:@"player"]);
    NSMutableDictionary *playerData = [[NSMutableDictionary alloc] init];
	[playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"num"]]] forKey:@"type"];
	[playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"xpos"]]] forKey:@"positionX"];
	[playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"ypos"]]] forKey:@"positionY"];
    [playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"player_jetpack"]]] forKey:@"hasJetpack"];
    [playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"starting_health"]]] forKey:@"health"];
    [playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"starting_lives"]]] forKey:@"lives"];
    [playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"max_speed"]]] forKey:@"speed"];
    
    // Check backward compatibilty with previus API to avoid crashes
    if ([[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"has_weapon"] != nil)
        [playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"has_weapon"]]] forKey:@"hasWeapon"];
    else if ([[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"player_weapon"] != nil)
        [playerData setObject:[NSNumber numberWithInt:[self getIntValue:[[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"player_weapon"]]] forKey:@"hasWeapon"];
    else 
        [playerData setObject:[NSNumber numberWithInt:0] forKey:@"has_weapon"];
    
    // Check backward compatibilty with previus API to avoid crashes
    id weapon = [[[jsonData objectForKey:@"map"] objectForKey:@"player"] objectForKey:@"chosen_weapon"];
    [playerData setObject:[NSNumber numberWithInt:[weapon intValue]] forKey:@"weapon"];
	
    [data setObject:playerData forKey:@"player"];
	//CCLOG(@"Player: %@", [playerData description]);
    
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load Characters
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NSArray *characterElements = [[jsonData objectForKey:@"map"] objectForKey:@"characters"];
	if(characterElements)
	{
		NSMutableArray *characters = [[NSMutableArray alloc] init];
		
		for(uint i = 0; i < [characterElements count]; i++)
		{
            //CCLOG(@"Enemy: %@", [characterElements objectAtIndex:i]);
			NSMutableDictionary *characterData = [[NSMutableDictionary alloc] init];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"health"]]] forKey:@"health"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"num"]]] forKey:@"type"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"xpos"]]] forKey:@"positionX"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"ypos"]]] forKey:@"positionY"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"score"]]] forKey:@"score"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"damage"]]] forKey:@"damage"];
			[characterData setObject:[[characterElements objectAtIndex:i] objectForKey:@"weapon"] forKey:@"weapon"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"shot_delay"]]] forKey:@"shotDelay"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"speed"]]] forKey:@"speed"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"multi_shot"]]] forKey:@"multiShot"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"multi_shot_delay"]]] forKey:@"multiShotDelay"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"collide_take"]]] forKey:@"collideTakeDamage"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"collide_give"]]] forKey:@"collideGiveDamage"];
			[characterData setObject:[NSNumber numberWithInt:[self getIntValue:[[characterElements objectAtIndex:i] objectForKey:@"enemy_type"]]] forKey:@"behaviour"];
			
			[characters addObject:characterData];
		}
		[data setObject:characters forKey:@"characters"];		
		//CCLOG(@"Characters: %@", [characters description]);
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load Level Items
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NSArray *itemElements = [[jsonData objectForKey:@"map"] objectForKey:@"items"];
	if(itemElements)
	{
		NSMutableArray *itemTiles = [[NSMutableArray alloc] init];
		
		for(uint i = 0; i < [itemElements count]; i++)
		{
			NSMutableDictionary *itemData = [[NSMutableDictionary alloc] init];
			//CCLOG(@"Item data: %@", [[itemElements objectAtIndex:i] description]);
			
			int animationId = [self getIntValue:[[itemElements objectAtIndex:i] objectForKey:@"animation_id"]];
			int tileNum = [self getIntValue:[[itemElements objectAtIndex:i] objectForKey:@"num"]];
			BOOL isEmbedded = [itemsIds objectForKey:[NSNumber numberWithInt:tileNum]] != nil;
			
			if (!isEmbedded) customTiles = YES;
			
			// Get tile id on the level spritesheet
			[itemData setObject:[NSNumber numberWithInt:animationId] forKey:@"animationId"];
			
			// Get tile id on global embedded spritesheet
			[itemData setObject:[NSNumber numberWithInt:tileNum] forKey:@"tileNum"];
						
			// Get position
			[itemData setObject:[NSNumber numberWithInt:[self getIntValue:[[itemElements objectAtIndex:i] objectForKey:@"xpos"]]] forKey:@"positionX"];
			[itemData setObject:[NSNumber numberWithInt:[self getIntValue:[[itemElements objectAtIndex:i] objectForKey:@"ypos"]]] forKey:@"positionY"];
			
			// Get behaviour
			NSArray *behaviour = [[itemElements objectAtIndex:i] objectForKey:@"behaviour"];
			//CCLOG(@"Item behaviour: %@", [behaviour description]);
			
            if ((behaviour != nil) && (![behaviour isMemberOfClass:[NSNull class]]) && ([behaviour count] >= 1)) {
                [itemData setObject:[[behaviour objectAtIndex:0] objectForKey:@"type"] forKey:@"type"];
                [itemData setObject:[[behaviour objectAtIndex:0] objectForKey:@"amount"] forKey:@"value"];
            }
            
			/*
			NSString *subtype = [[positions objectAtIndex:1] objectAtIndex:0];
			[itemData setObject:subtype forKey:@"subtype"];
			*/
			
			// Check frame animations
			int frames = [[animationsIds objectForKey:[NSString stringWithFormat:@"f_%i", animationId]] intValue];
			[itemData setObject:[NSNumber numberWithInt:frames] forKey:@"frames"];
			
			// Is robot?
			NSDictionary *robot = [[itemElements objectAtIndex:i] objectForKey:@"robot"];
			if ((robot == nil) || ([robot isMemberOfClass:[NSNull class]])) {
				[itemData setObject:[NSDictionary dictionary] forKey:@"robot"];
				
			} else if ([robot isKindOfClass:[NSDictionary class]]) {
                if ([robotsIds objectForKey:[robot objectForKey:@"id"]] != nil) [itemData setObject:[robotsIds objectForKey:[robot objectForKey:@"id"]] forKey:@"robot"];
                else if ([robotsIds objectForKey:[NSNumber numberWithInt:[self getIntValue:[robot objectForKey:@"id"]]]] != nil) [itemData setObject:[robotsIds objectForKey:[NSNumber numberWithInt:[self getIntValue:[robot objectForKey:@"id"]]]] forKey:@"robot"];
                else [itemData setObject:[NSDictionary dictionary] forKey:@"robot"];
                
                [itemData setObject:robot forKey:@"robotParameters"];
			}
                 
            [itemTiles addObject:itemData];
			
		}
		[data setObject:itemTiles forKey:@"itemTiles"];		
		//CCLOG(@"Item Tiles: %@", [itemTiles description]);
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Load Level Tiles
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NSMutableArray *mapTiles = [[NSMutableArray alloc] init];
	NSArray *tiles = [[jsonData  objectForKey:@"map"] objectForKey:@"terrain"];
	for(uint i = 0; i < [tiles count]; i++)
	{
		NSMutableDictionary *tileData = [[NSMutableDictionary alloc] init];
		//CCLOG(@"tile: %@", [[tiles objectAtIndex:i] description]);
		
		int animationId = [self getIntValue:[[tiles objectAtIndex:i] objectForKey:@"animation_id"]];
		int tileNum = [self getIntValue:[[tiles objectAtIndex:i] objectForKey:@"num"]];
		BOOL isEmbedded = [tilesIds objectForKey:[NSNumber numberWithInt:tileNum]] != nil;
		
		if (!isEmbedded) customTiles = YES;
		
		// Get tile id on the level spritesheet
		[tileData setObject:[NSNumber numberWithInt:animationId] forKey:@"animationId"];
		
		// Get tile id on global embedded spritesheet
		[tileData setObject:[NSNumber numberWithInt:tileNum] forKey:@"tileNum"];
		
		// Get behaviour (careful, can be null!)
		id hasBehaviour = [[tiles objectAtIndex:i] objectForKey:@"behaviour"];
		if ((hasBehaviour != nil) && (![hasBehaviour isMemberOfClass:[NSNull class]])) {
			NSString *behaviour = [[tiles objectAtIndex:i] objectForKey:@"behaviour"];
			[tileData setObject:behaviour forKey:@"behaviour"];
		} else {
			[tileData setObject:@"TERRAIN_BACKGROUND" forKey:@"behaviour"];
		}
		
		// Check if tile is moving and if so get end position
		NSArray *positions = [[tiles objectAtIndex:i] objectForKey:@"mover_array"];
		
		if ((positions != nil) && [positions isKindOfClass:[NSArray class]]) {
			NSDictionary *endPositions = [positions objectAtIndex:1];
			[tileData setObject:[NSNumber numberWithInt:[[endPositions objectForKey:@"xpos"] intValue]] forKey:@"endPositionX"];
			[tileData setObject:[NSNumber numberWithInt:[[endPositions objectForKey:@"ypos"] intValue]] forKey:@"endPositionY"];
			
			// lever_var: if it is set to false then the moving tile will start off
			[tileData setObject:[NSNumber numberWithInt:[[[tiles objectAtIndex:i] objectForKey:@"lever_var"] boolValue]] forKey:@"startOn"];
			
		} else {
			[tileData setObject:[NSNumber numberWithInt:[[[tiles objectAtIndex:i] objectForKey:@"xpos"] intValue]] forKey:@"endPositionX"];
			[tileData setObject:[NSNumber numberWithInt:[[[tiles objectAtIndex:i] objectForKey:@"ypos"] intValue]] forKey:@"endPositionY"];
		}
		
		// Get position (start position on miving tiles)
		[tileData setObject:[NSNumber numberWithInt:[[[tiles objectAtIndex:i] objectForKey:@"xpos"] intValue]] forKey:@"positionX"];
		[tileData setObject:[NSNumber numberWithInt:[[[tiles objectAtIndex:i] objectForKey:@"ypos"] intValue]] forKey:@"positionY"];
		[mapTiles addObject:tileData];
		
		// Check zorder
		[tileData setObject:[NSNumber numberWithInt:[[[tiles objectAtIndex:i] objectForKey:@"zpos"] intValue]] forKey:@"zorder"];
		
		// Check frame animations
		int frames = [[animationsIds objectForKey:[NSString stringWithFormat:@"f_%i", animationId]] intValue];
		[tileData setObject:[NSNumber numberWithInt:frames] forKey:@"frames"];
		
		// Check if switch
		BOOL isSwitch = [[[tiles objectAtIndex:i] objectForKey:@"is_switch"] boolValue];
		[tileData setObject:[NSNumber numberWithInt:isSwitch] forKey:@"isSwitch"];
		
		// Check if switch controlled
		id switchRef = [[tiles objectAtIndex:i] objectForKey:@"switch_ref"];
		BOOL isSwitchControlled = ((switchRef != nil) && (![switchRef isMemberOfClass:[NSNull class]]));
		[tileData setObject:[NSNumber numberWithInt:isSwitchControlled] forKey:@"isSwitchControlled"];
		
		if (isSwitchControlled) {
			int switchX = [[[[tiles objectAtIndex:i] objectForKey:@"switch_ref"] objectForKey:@"xpos"] intValue];
			int switchY = [[[[tiles objectAtIndex:i] objectForKey:@"switch_ref"] objectForKey:@"ypos"] intValue];
			[tileData setObject:[NSNumber numberWithInt:switchX] forKey:@"switchX"];
			[tileData setObject:[NSNumber numberWithInt:switchY] forKey:@"switchY"];
		}
		
	}	
	[data setObject:mapTiles forKey:@"mapTiles"];		
	//CCLOG(@"Map Tiles: %@", [mapTiles description]);
	
	CCLOG(@"Load completed!");
}

-(void) loadBackgroundLevel
{
	CGSize size = [[CCDirector sharedDirector] winSize];
    
    NSString *backgroundFilename = [data objectForKey:@"mapBackground"];
    NSString *assetPath;
    
    if ( ([backgroundFilename rangeOfString:@".png"].location != NSNotFound) ||
        ([backgroundFilename rangeOfString:@".jpg"].location != NSNotFound) ||
        ([backgroundFilename rangeOfString:@".gif"].location != NSNotFound) )
    {
        assetPath = [Shared findAsset:backgroundFilename withType:@"backgrounds"];
    } else {
        assetPath = [Shared findAsset:[backgroundFilename stringByAppendingString:@".png"] withType:@"backgrounds"];
    }

    if(assetPath) {
        CCSprite *bg = [CCSprite spriteWithFile:assetPath];
        [background addChild:bg];
        
        // PNG is 768x512
        bg.scale = 0.625 * CC_CONTENT_SCALE_FACTOR();
        [bg setPosition:ccp(size.width/2, size.height/2)];
    }
    
    /*
    
    if ( ([backgroundFilename rangeOfString:@".png"].location != NSNotFound) ||
         ([backgroundFilename rangeOfString:@".jpg"].location != NSNotFound) ||
         ([backgroundFilename rangeOfString:@".gif"].location != NSNotFound) )
    {
        
        NSString *urlBackground = [NSString stringWithFormat:@"%@wp-content/plugins/game_data/backgrounds/user/%@", [self returnServer], backgroundFilename];
        CCLOG(@"Load custom background: %@", urlBackground);
        
        // Load Custom background
        @try
        {
            bg = [CCSprite spriteWithTexture:[Shared getTexture2DFromWeb:urlBackground ignoreCache:ignoreCache]];
        }
        @catch (NSException * e)
        {
            CCLOG(@"Failed loading custom background");
            return;
        }
        
    } else {
        CCLOG(@"Load embedded background level: %@", backgroundFilename);
        
        // Load embedded background
        bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@.png", backgroundFilename]];
    }
     */
    
    
}


-(void) loadTilesLevel
{	
	
    NSString *assetFN = [NSString stringWithFormat:@"%@.png", [data objectForKey:@"gameID"]];
    NSString *assetPath = [Shared findAsset:assetFN withType:@"tiles"];
    
    if(assetPath) {
        spriteSheet = [CCSpriteBatchNode batchNodeWithFile:assetPath];
        if (REDUCE_FACTOR != 1.0f) [spriteSheet.textureAtlas.texture setAntiAliasTexParameters];
		else [spriteSheet.textureAtlas.texture setAliasTexParameters];
		
		[objects addChild:spriteSheet z:LAYER_TILES];
        
        teleportSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"teleporter.png"];
        [objects addChild:teleportSpriteSheet z:LAYER_TILES+1];
        
        // Add telepoter hardcoded animation
        id animation = [[CCAnimationCache sharedAnimationCache] animationByName:@"teleport"];
        if (animation == nil) {
            
            CCLOG(@"Load spritesheet teleport");
            
            float speed = 0.1f;
            
            NSMutableArray *frameList = [NSMutableArray array];
            for (int i=0; i < 5; i++) {
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:teleportSpriteSheet.textureAtlas.texture rect:CGRectMake(i * MAP_TILE_WIDTH,0,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
                [frameList addObject:frame];
            }
            animation = [CCAnimation animationWithFrames:frameList delay:speed];
            
            [[CCAnimationCache sharedAnimationCache] addAnimation:animation name:@"teleport"];
        }
    }
    
    // Load tiles
    /*
	@try
	{
		if (customTiles) {
			int gameID = (int)[[data objectForKey:@"gameID"] intValue];
			//NSString *tilesFilename = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_tilesheet&id=%d", [self returnServer], gameID];
			NSString *tilesFilename = [NSString stringWithFormat:@"%@?gamemakers_api=1&type=get_game_animations&id=%d", [self returnServer], gameID];
			CCLOG(@"Load spritesheet tiles: %@", tilesFilename);
			spriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:tilesFilename ignoreCache:ignoreCache]];
			
		} else {
			// Load embedded spritesheet
			//CCLOG(@"Load spritesheet tiles: iphone_tiles.png");
			//spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"iphone_tiles.png"];
			CCLOG(@"Load spritesheet tiles: tiles.png");
			spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"tiles.png"];
		}
		
		if (REDUCE_FACTOR != 1.0f) [spriteSheet.textureAtlas.texture setAntiAliasTexParameters];
		else [spriteSheet.textureAtlas.texture setAliasTexParameters];
		
		[objects addChild:spriteSheet z:LAYER_TILES];
        
        teleportSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"teleporter.png"];
        [objects addChild:teleportSpriteSheet z:LAYER_TILES+1];
        
        // Add telepoter hardcoded animation
        id animation = [[CCAnimationCache sharedAnimationCache] animationByName:@"teleport"];
        if (animation == nil) {
            
            CCLOG(@"Load spritesheet teleport");
            
            float speed = 0.1f;
            
            NSMutableArray *frameList = [NSMutableArray array];
            for (int i=0; i < 5; i++) {
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:teleportSpriteSheet.textureAtlas.texture rect:CGRectMake(i * MAP_TILE_WIDTH,0,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
                [frameList addObject:frame];
            }
            animation = [CCAnimation animationWithFrames:frameList delay:speed];
            
            [[CCAnimationCache sharedAnimationCache] addAnimation:animation name:@"teleport"];
            
        }
	}
	@catch (NSException * e)
	{
		CCLOG(@"Failed loading tiles");
		return;
	}
     */
}

/* DEPRECATED!!
-(void) createDelimiterAt:(CGPoint)_poition size:(CGSize)_size
{
	b2BodyDef playerBodyDef;
	playerBodyDef.allowSleep = false;
	playerBodyDef.fixedRotation = true;
	playerBodyDef.type = b2_staticBody;
	playerBodyDef.position.Set(_poition.x/PTM_RATIO, _poition.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&playerBodyDef);
	
	b2PolygonShape shape;
	shape.SetAsBox((_size.width/2.0)/PTM_RATIO, (_size.height/2.0f)/PTM_RATIO);
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;
	fixtureDef.density = 1.0;
	fixtureDef.friction = 0.0;
	fixtureDef.restitution = 0.0; // bouncing
	fixtureDef.isSensor = true;
	body->CreateFixture(&fixtureDef);
}
*/

-(int) getTileAt:(CGPoint)position
{
    int pos = position.x + position.y*mapWidth;
    if ((pos >= 0) && (pos < 100000)) {
        //CCLOG(@"get tile at: %f, %f => %i = %i", position.x, position.y, pos, arrayTiles[pos]);
        return arrayTiles[pos];
        
    } else return 0;
}

-(void) createMapTiles
{
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Add tiles to map
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	[spriteSheet removeAllChildrenWithCleanup:false];
	NSMutableArray *arTiles = [data objectForKey:@"mapTiles"];
	
	NSSortDescriptor *descriptorZOrder = [[NSSortDescriptor alloc] initWithKey:@"zorder" ascending:NO];
	NSSortDescriptor *descriptorX = [[NSSortDescriptor alloc] initWithKey:@"positionX" ascending:YES];
	NSSortDescriptor *descriptorY = [[NSSortDescriptor alloc] initWithKey:@"positionY" ascending:YES];
    [arTiles sortUsingDescriptors:[NSArray arrayWithObjects:descriptorZOrder, descriptorX, descriptorY, nil]];
	//CCLOG(@"%@", arTiles);
    
	for (int y = 0; y < mapHeight; y++) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"positionY = %i", y];
		NSArray *filteredArray = [arTiles filteredArrayUsingPredicate:predicate];
		//CCLOG(@"%@", filteredArray);
		
		int initialType = -1;
		int prevXPos = -1;
		int countTiles = 0;
		CGPoint pos;
		CGPoint initialPos = CGPointZero;
		
		for(uint x = 0; x < [filteredArray count]; x++)
		{
			NSDictionary *dict = (NSDictionary *)[filteredArray objectAtIndex:x];
			//CCLOG(@"%@", [dict description]);
			
			int tileNum;
			if (customTiles) {
                if ([animationsIds objectForKey:[dict objectForKey:@"animationId"]] != nil) tileNum = [[animationsIds objectForKey:[dict objectForKey:@"animationId"]] intValue];
                else tileNum = [[animationsIds objectForKey:[[dict objectForKey:@"animationId"] stringValue]] intValue];
			} 
            else tileNum = [[tilesIds objectForKey:[dict objectForKey:@"tileNum"]] intValue];
			
			int dx = [[dict objectForKey:@"positionX"] intValue];
			int dy = [[dict objectForKey:@"positionY"] intValue];			
			
			int tileX = (tileNum - floor(tileNum/SPRITESHEETS_TILE_WIDTH)*SPRITESHEETS_TILE_WIDTH) * MAP_TILE_WIDTH;
			int tileY = floor(tileNum/SPRITESHEETS_TILE_WIDTH) * MAP_TILE_HEIGHT;
			//CCLOG(@"TileID: %d  TileX: %d  TileY: %d", tileNum, tileX, tileY);
			
			NSString *stringBehaviour = [dict objectForKey:@"behaviour"];
			//CCLOG(@"Tile behaviour: %@", stringBehaviour);
			// 0: TERRAIN_BACKGROUND
			// 1: TERRAIN_SOLID
			// 2: TERRAIN_CLOUD
			// 3: TERRAIN_SPIKE
			// 4: TERRAIN_ICE
			// 5: TERRAIN_DESTRUCTABLE
			//
			int behaviour = 0; // TERRAIN_BACKGROUND 
			if ([stringBehaviour isEqualToString:@"TERRAIN_SOLID"]) behaviour = 1;
			else if ([stringBehaviour isEqualToString:@"TERRAIN_CLOUD"]) behaviour = 2;
			else if ([stringBehaviour isEqualToString:@"TERRAIN_SPIKE"]) behaviour = 3;
			else if ([stringBehaviour isEqualToString:@"TERRAIN_ICE"]) behaviour = 4;
			else if ([stringBehaviour isEqualToString:@"TERRAIN_DESTRUCTABLE"]) behaviour = 5;
			
			int zorder = [[dict objectForKey:@"zorder"] intValue];
			int frames = [[dict objectForKey:@"frames"] intValue];
			BOOL isSwitch = [[dict objectForKey:@"isSwitch"] intValue];
			BOOL isSwitchControlled = [[dict objectForKey:@"isSwitchControlled"] intValue];
			
			pos = ccp(dx * MAP_TILE_WIDTH, (mapHeight - dy - 1) * MAP_TILE_HEIGHT);
			pos.x += MAP_TILE_WIDTH/2.0f;
			pos.y += MAP_TILE_HEIGHT/2.0f;
			
			int endx = [[dict objectForKey:@"endPositionX"] intValue];
			int endy = [[dict objectForKey:@"endPositionY"] intValue];
			
			//CCLOG(@"x:%i y:%i - type:%i, type before: %i, count:%i", dx, dy, behaviour, initialType, countTiles);
			
			if (isSwitch) {
				Switch *switchTile = [Switch spriteWithBatchNode:spriteSheet rect:CGRectMake(tileX,tileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
				[switchTile setPosition:pos];
				[switchTile createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH, MAP_TILE_HEIGHT)];
				[switchTile setupSwitch:tileNum withKey:[NSString stringWithFormat:@"%i_%i",dx,dy] frames:frames];
				[spriteSheet addChild:switchTile z:zorder];
				
				if (frames > 1) {
					float speed = 0.1f;
					
					id animation = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"tile_%i", tileNum]];
					if (animation == nil) {
						
						NSMutableArray *frameList = [NSMutableArray array];
						for (int i=0; i < frames; i++) {
							int nextTileX = ((tileNum+i) - floor((tileNum+i)/SPRITESHEETS_TILE_WIDTH)*SPRITESHEETS_TILE_WIDTH) * MAP_TILE_WIDTH;
							int nextTileY = floor((tileNum+i)/SPRITESHEETS_TILE_WIDTH) * MAP_TILE_HEIGHT;
							
							CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.textureAtlas.texture rect:CGRectMake(nextTileX,nextTileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
							[frameList addObject:frame];
						}
						animation = [CCAnimation animationWithFrames:frameList delay:speed];
						
						[[CCAnimationCache sharedAnimationCache] addAnimation:animation name:[NSString stringWithFormat:@"tile_%i", tileNum]];
					}
				}
				
				[items addObject:switchTile];
				
			} else if ((endx != dx) || (endy != dy)) {
				// Moving platforms
				
				MovingPlatform *platform = [MovingPlatform spriteWithBatchNode:spriteSheet rect:CGRectMake(tileX,tileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
				[platform setPosition:pos];
				[platform createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH, MAP_TILE_HEIGHT)];
				[movingPlatforms addObject:platform];
				
				if (behaviour == 1) platform.isCloud = NO;
				else if (behaviour == 3) platform.isKiller = YES;
                
				if (frames > 1) {
					// Set animation (if frames)
					float speed = 0.1f;
					
					id animation = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"tile_%i", tileNum]];
					if (animation == nil) {
						
						NSMutableArray *frameList = [NSMutableArray array];
						for (int i=0; i < frames; i++) {
							int nextTileX = ((tileNum+i) - floor((tileNum+i)/SPRITESHEETS_TILE_WIDTH)*SPRITESHEETS_TILE_WIDTH) * MAP_TILE_WIDTH;
							int nextTileY = floor((tileNum+i)/SPRITESHEETS_TILE_WIDTH) * MAP_TILE_HEIGHT;
							
							CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.textureAtlas.texture rect:CGRectMake(nextTileX,nextTileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
							[frameList addObject:frame];
						}
						animation = [CCAnimation animationWithFrames:frameList delay:speed];
						
						[[CCAnimationCache sharedAnimationCache] addAnimation:animation name:[NSString stringWithFormat:@"tile_%i", tileNum]];
					}
					
					CCAnimate *action = [CCAnimate actionWithAnimation:animation];
					CCRepeatForever *repeatAction = [CCRepeatForever actionWithAction:action];
					[platform runAction:repeatAction];
				}
				
				CGPoint endPos = ccp(endx * MAP_TILE_WIDTH, (mapHeight - endy - 1) * MAP_TILE_HEIGHT);
				endPos.x += MAP_TILE_WIDTH/2.0f;
				endPos.y += MAP_TILE_HEIGHT/2.0f;
				
				if ((endPos.x == pos.x) && (endPos.y != pos.y)) {
					[platform moveVertically:(endPos.y - pos.y) duration:fabsf(endPos.y - pos.y) / 100.0f]; // set 100px per second
					
				} else if ((endPos.x != pos.x) && (endPos.y == pos.y)) {
					[platform moveHorizontally:(endPos.x - pos.x) duration:fabsf(endPos.x - pos.x) / 100.0f]; // set 100px per second
					
				} else {
					[platform moveTo:endPos duration:fabsf(endPos.x - pos.x) / 100.0f]; // set 100px per second
				}
				
				[spriteSheet addChild:platform z:zorder];
				
				// Check if switch controlled
				if (isSwitchControlled) {
					int switchX = [[dict objectForKey:@"switchX"] intValue];
					int switchY = [[dict objectForKey:@"switchY"] intValue];
					
					id platforms = [switches objectForKey:[NSString stringWithFormat:@"%i_%i", switchX, switchY]];
					if (platforms != nil) {
						NSMutableArray *list = (NSMutableArray *)platforms;
						[list addObject:platform];
						[switches setObject:list forKey:[NSString stringWithFormat:@"%i_%i", switchX, switchY]];
						
					} else {
						NSMutableArray *list = [NSMutableArray array];
						[list addObject:platform];
						[switches setObject:list forKey:[NSString stringWithFormat:@"%i_%i", switchX, switchY]];
					}
					
					BOOL startOn = [[dict objectForKey:@"startOn"] intValue];
					if (!startOn) [platform startsOff];
				}
				
				
			} else {
				// Tile sprite
				GameObject *sprite = [GameObject spriteWithBatchNode:spriteSheet rect:CGRectMake(tileX,tileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
				[sprite setPosition:pos];
				[sprite setAnchorPoint:ccp(0.5,0.5)];
				[spriteSheet addChild:sprite z:zorder];
                    
                // Set array tiles
                if (behaviour > 0) {
                    int index = dx + (dy*mapWidth);
                    //CCLOG(@"set tile %i at %i,%i (%i)", behaviour, dx, dy, index);
                    arrayTiles[index] = behaviour;
				}
                
				if (frames > 1) {
					float speed = 0.1f;
					
					id animation = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"tile_%i", tileNum]];
					if (animation == nil) {
						
						NSMutableArray *frameList = [NSMutableArray array];
						for (int i=0; i < frames; i++) {
							int nextTileX = ((tileNum+i) - floor((tileNum+i)/SPRITESHEETS_TILE_WIDTH)*SPRITESHEETS_TILE_WIDTH) * MAP_TILE_WIDTH;
							int nextTileY = floor((tileNum+i)/SPRITESHEETS_TILE_WIDTH) * MAP_TILE_HEIGHT;
							
							CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.textureAtlas.texture rect:CGRectMake(nextTileX,nextTileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
							[frameList addObject:frame];
						}
						animation = [CCAnimation animationWithFrames:frameList delay:speed];
						
						[[CCAnimationCache sharedAnimationCache] addAnimation:animation name:[NSString stringWithFormat:@"tile_%i", tileNum]];
					}
					
					CCAnimate *action = [CCAnimate actionWithAnimation:animation];
					CCRepeatForever *repeatAction = [CCRepeatForever actionWithAction:action];
					[sprite runAction:repeatAction];
				}
				
                /* DEPRECATED!!
				// If background tile, check if there is already a foreground tile so we ignore collision 
				if (zorder == 0) {
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"positionX = %i AND positionY = %i AND zorder=1", dx, dy];
					NSArray *repeatedArray = [arTiles filteredArrayUsingPredicate:predicate];
					//CCLOG(@"%@", repeatedArray);
					if ([repeatedArray count] > 0) behaviour = 100 + dx;
				}
				*/
				
				if (behaviour != initialType) {
					// Detected a change on tile type
					
					if (countTiles > 0) {
						// Draw batch of prev tiles collision area
						
						@try
						{
							if ((initialType > 0) && (initialType < 100)) {
								//CCLOG(@"create collision area (1): %i on pos: %f, %f, type: %i", countTiles, initialPos.x, initialPos.y, initialType);
								
								GameObject *block = [GameObject node];
								block.visible = NO;								 
								[self addChild:block];
								
								// Create collision body
								[block setPosition:ccp(initialPos.x - (MAP_TILE_WIDTH/2.0f) + (MAP_TILE_WIDTH * ((float)(countTiles)/2.0f)), initialPos.y)];
								
                                if (initialType == 3) [block createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH/2 * countTiles, MAP_TILE_HEIGHT/2)];
                                else [block createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH * countTiles, MAP_TILE_HEIGHT)];
								
								if (initialType == 2) [block setType:kGameObjectCloud];
								else if (initialType == 3) [block setType:kGameObjectKiller];
								else [block setType:kGameObjectPlatform];
								
								block.contentSize = CGSizeMake(MAP_TILE_WIDTH * countTiles, MAP_TILE_HEIGHT);
								//CCLOG(@"------->%f, %f", block.contentSize.width, block.contentSize.height);
								
                                /* DEPRECATED!!
								if ((initialType == 1) && (countTiles > 1)) {
									NSPredicate *predicate = [NSPredicate predicateWithFormat:@"positionX = %i AND positionY = %i", prevXPos, y-1];
									NSArray *repeatedArray = [arTiles filteredArrayUsingPredicate:predicate];
									//CCLOG(@"%@", repeatedArray);
									if ([repeatedArray count] == 0) {
										// Put sensors on borders to avoid enemies to fall
										[self createDelimiterAt:ccp(block.position.x - ((MAP_TILE_WIDTH * countTiles) / 2.0f), block.position.y + MAP_TILE_HEIGHT) size:CGSizeMake(MAP_TILE_WIDTH/4, MAP_TILE_HEIGHT/10)];
										[self createDelimiterAt:ccp(block.position.x + ((MAP_TILE_WIDTH * countTiles) / 2.0f), block.position.y + MAP_TILE_HEIGHT) size:CGSizeMake(MAP_TILE_WIDTH/4, MAP_TILE_HEIGHT/10)];
									}
								}
                                */
							}
							
						}
						@catch(NSException *e)
						{
						}
					}
					
					initialPos = ccp(pos.x, pos.y);
					initialType = behaviour;
					countTiles = 1;
					//CCLOG(@"Save inital pos: %f, %f for type:%i", pos.x, pos.y, initialType);
					
				} else if (dx == prevXPos + 1) {
					// is a consecutive tile of same type
					countTiles++;
					
				} else {
					// There is a gap
					if (countTiles > 0) {
						// Draw batch of prev tiles collision area
						
						@try
						{
							if ((initialType > 0) && (initialType < 100)) {
								//CCLOG(@"create collision area (2): %i on pos: %f, %f, type: %i", countTiles, initialPos.x, initialPos.y, initialType);
								
								GameObject *block = [GameObject node];
								block.visible = NO;
								[self addChild:block];
								
								// Create collision body
								[block setPosition:ccp(initialPos.x - (MAP_TILE_WIDTH/2.0f) + (MAP_TILE_WIDTH * ((float)(countTiles)/2.0f)), initialPos.y)];
								
                                if (initialType == 3) [block createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH/2 * countTiles, MAP_TILE_HEIGHT/2)];
                                else [block createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH * countTiles, MAP_TILE_HEIGHT)];
								
								if (initialType == 2) [block setType:kGameObjectCloud];
								else if (initialType == 3) [block setType:kGameObjectKiller];
								else [block setType:kGameObjectPlatform];
								
								block.contentSize = CGSizeMake(MAP_TILE_WIDTH * countTiles, MAP_TILE_HEIGHT);
								//CCLOG(@"------->%f, %f", block.contentSize.width, block.contentSize.height);
								
                                /* DEPRECATED!!
								if ((initialType == 1) && (countTiles > 1)) {
									NSPredicate *predicate = [NSPredicate predicateWithFormat:@"positionX = %i AND positionY = %i", prevXPos, y-1];
									NSArray *repeatedArray = [arTiles filteredArrayUsingPredicate:predicate];
									//CCLOG(@"%@", repeatedArray);
									if ([repeatedArray count] == 0) {
										// Put sensors on borders to avoid enemies to fall
										[self createDelimiterAt:ccp(block.position.x - ((MAP_TILE_WIDTH * countTiles) / 2.0f), block.position.y + MAP_TILE_HEIGHT) size:CGSizeMake(MAP_TILE_WIDTH/4, MAP_TILE_HEIGHT/10)];
										[self createDelimiterAt:ccp(block.position.x + ((MAP_TILE_WIDTH * countTiles) / 2.0f), block.position.y + MAP_TILE_HEIGHT) size:CGSizeMake(MAP_TILE_WIDTH/4, MAP_TILE_HEIGHT/10)];
									}
								}
                                */
							}
							
						}
						@catch(NSException *e)
						{
						}
					}
					
					initialPos = ccp(pos.x, pos.y);
					initialType = behaviour;
					countTiles = 1;
					//CCLOG(@"Save inital pos: %f, %f for type:%i", pos.x, pos.y, initialType);
				}
				
				prevXPos = dx;
			}
			
		}
		
		// Check last tile collision area
		@try
		{
			if ((initialType > 0) && (initialType < 100)) {
				//CCLOG(@"create collision area (3): %i on pos: %f, %f, type: %i", countTiles, initialPos.x, initialPos.y, initialType);
				
				GameObject *block = [GameObject node];
				block.visible = NO;
				[self addChild:block];
				
				// Create collision body
				[block setPosition:ccp(initialPos.x - (MAP_TILE_WIDTH/2.0f) + (MAP_TILE_WIDTH * ((float)(countTiles)/2.0f)), initialPos.y)];
				
                if (initialType == 3) [block createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH/2 * countTiles, MAP_TILE_HEIGHT/2)];
                else [block createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH * countTiles, MAP_TILE_HEIGHT)];
				
				if (initialType == 2) [block setType:kGameObjectCloud];
				else if (initialType == 3) [block setType:kGameObjectKiller];
				else [block setType:kGameObjectPlatform];
				
				block.contentSize = CGSizeMake(MAP_TILE_WIDTH * countTiles, MAP_TILE_HEIGHT);
				//CCLOG(@"------->%f, %f", block.contentSize.width, block.contentSize.height);
				
                /* DEPRECATED!!
				if ((initialType == 1) && (countTiles > 1)) {
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"positionX = %i AND positionY = %i", prevXPos, y-1];
					NSArray *repeatedArray = [arTiles filteredArrayUsingPredicate:predicate];
					//CCLOG(@"%@", repeatedArray);
					if ([repeatedArray count] == 0) {
						// Put sensors on borders to avoid enemies to fall
						[self createDelimiterAt:ccp(block.position.x - ((MAP_TILE_WIDTH * countTiles) / 2.0f), block.position.y + MAP_TILE_HEIGHT) size:CGSizeMake(MAP_TILE_WIDTH/4, MAP_TILE_HEIGHT/10)];
						[self createDelimiterAt:ccp(block.position.x + ((MAP_TILE_WIDTH * countTiles) / 2.0f), block.position.y + MAP_TILE_HEIGHT) size:CGSizeMake(MAP_TILE_WIDTH/4, MAP_TILE_HEIGHT/10)];
					}
				}
                */
			}
			
		}
		@catch(NSException *e)
		{
		}
	}
	
	
}

-(void) createMapItems
{
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Add items to map
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	NSArray *arItemTiles = [data objectForKey:@"itemTiles"];
	for(uint i = 0; i < [arItemTiles count]; i++)
	{
		NSDictionary *dict = (NSDictionary *)[arItemTiles objectAtIndex:i];
		//CCLOG(@"%@", [dict description]);
		
		int tileNum;
        if (customTiles) {
            if ([animationsIds objectForKey:[dict objectForKey:@"animationId"]] != nil) tileNum = [[animationsIds objectForKey:[dict objectForKey:@"animationId"]] intValue];
            else tileNum = [[animationsIds objectForKey:[[dict objectForKey:@"animationId"] stringValue]] intValue];
        } 
		else tileNum = [[itemsIds objectForKey:[dict objectForKey:@"tileNum"]] intValue];
		
		int dx = [[dict objectForKey:@"positionX"] intValue];
		int dy = [[dict objectForKey:@"positionY"] intValue];			
		
		int tileX = (tileNum - floor(tileNum/SPRITESHEETS_ITEM_WIDTH)*SPRITESHEETS_ITEM_WIDTH) * MAP_TILE_WIDTH;
		int tileY = floor(tileNum/SPRITESHEETS_ITEM_WIDTH) * MAP_TILE_HEIGHT;
		
		int type = [[dict objectForKey:@"type"] intValue];
		int value = [[dict objectForKey:@"value"] intValue];
		NSString *subtype = [dict objectForKey:@"subtype"];
		NSDictionary *robot = [dict objectForKey:@"robot"];
		
		int frames = [[dict objectForKey:@"frames"] intValue];
		int zorder  = 1;
		
		// Types
		// 0: Points? subtype: Money
		// 7: Check point? subtype: sign
		// 3: Weapon?
		// 3: Ammo? subtype: Ammo
		// 9: Jetpack
		// 100: Final item?
		
		@try
		{
			CGPoint pos = ccp(dx * MAP_TILE_WIDTH, (mapHeight - dy - 1) * MAP_TILE_HEIGHT);
			pos.x += MAP_TILE_WIDTH/2.0f;
			pos.y += MAP_TILE_HEIGHT/2.0f;
			
			id animation = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"item_%i", tileNum]];
			if (frames > 1) {
				float speed = 0.1f;					
				if (animation == nil) {
					
					NSMutableArray *frameList = [NSMutableArray array];
					for (int i=0; i < frames; i++) {
						int nextTileX = ((tileNum+i) - floor((tileNum+i)/SPRITESHEETS_ITEM_WIDTH)*SPRITESHEETS_ITEM_WIDTH) * MAP_TILE_WIDTH;
						int nextTileY = floor((tileNum+i)/SPRITESHEETS_ITEM_WIDTH) * MAP_TILE_HEIGHT;
						
						CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.textureAtlas.texture rect:CGRectMake(nextTileX,nextTileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
						[frameList addObject:frame];
					}
					animation = [CCAnimation animationWithFrames:frameList delay:speed];
					
					[[CCAnimationCache sharedAnimationCache] addAnimation:animation name:[NSString stringWithFormat:@"item_%i", tileNum]];
				}
			}
			
			if ([robot count] > 0) {
				// Override other functionality
				Robot *item = [Robot spriteWithBatchNode:spriteSheet rect:CGRectMake(tileX,tileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
				[item setPosition:pos];
				[item setupRobot:dict];
				[item createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH, MAP_TILE_HEIGHT)];
				[spriteSheet addChild:item z:zorder];
  
                NSRange range = [[robot description] rangeOfString: @"triggerCheckpoint"];
                if (range.location != NSNotFound)
                {
                    checkpoints = YES;
                }
				
				[robots addObject:item];
				
			} else if (type == 7) {
				// Check point
				CheckPoint *checkPoint = [CheckPoint spriteWithBatchNode:spriteSheet rect:CGRectMake(tileX,tileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
				[checkPoint setPosition:pos];
				[checkPoint createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH, MAP_TILE_HEIGHT)];
				[checkPoint setupCheckPointWithX:dx andY:dy tileId:tileNum frames:frames];
				[spriteSheet addChild:checkPoint z:zorder];
                checkpoints = YES;
				
			} else {
				// Tile sprite
				Collectable *item = [Collectable spriteWithBatchNode:spriteSheet rect:CGRectMake(tileX,tileY,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
				[item setPosition:pos];
				[item createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH, MAP_TILE_HEIGHT)];
				[item setType:kGameObjectCollectable];
				[spriteSheet addChild:item z:zorder];
				
				if (type == 0) {
					item.itemType = kCollectableMoney;
					totalPoints += value;
					
				} else if (type == 1) item.itemType = kCollectableHealth;
				else if (type == 2) item.itemType = kCollectableTime;
				else if ((type == 3) && ([subtype isEqualToString:@"Ammo"])) item.itemType = kCollectableAmmo;
				else if (type == 3) item.itemType = kCollectableWeapon;
				else if (type == 6) item.itemType = kCollectableLive;
				else if (type == 9) item.itemType = kCollectableJetpack;
				else if (type == 100) item.itemType = kCollectableFinal;
				
				item.itemValue = value;
				
				if (animation != nil) {
					CCAnimate *action = [CCAnimate actionWithAnimation:animation];
					CCRepeatForever *repeatAction = [CCRepeatForever actionWithAction:action];
					[item runAction:repeatAction];
				}
				
				[items addObject:item];
			}
			
		}
		@catch(NSException *e)
		{
		}
	}
	
	CCLOG(@"Total points level: %i", totalPoints);
}

-(void) loadPlayer
{
	NSDictionary *dict = (NSDictionary *)[data objectForKey:@"player"];
	int playerID = [[dict objectForKey:@"type"] intValue];
	int dx = [[dict objectForKey:@"positionX"] intValue];
	int dy = [[dict objectForKey:@"positionY"] intValue];			
	CCLOG(@"Player id: %i, initial position: %i,%i", playerID, dx, dy);
	
    CCSpriteBatchNode *playerSpriteSheet;
    NSString *playerFilename;
    
    if (playerID > 10) {
        playerFilename = [Shared findAsset:[NSString stringWithFormat:@"character%d.png", playerID] withType:@"characters"];
    } else {
        playerFilename = [Shared findAsset:[NSString stringWithFormat:@"player_%d.png", playerID] withType:@"characters"];
    }
    
    if(playerFilename) {
        playerSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:playerFilename];
        if (REDUCE_FACTOR != 1.0f) [playerSpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
        else [playerSpriteSheet.textureAtlas.texture setAliasTexParameters];
        
        [objects addChild:playerSpriteSheet z:LAYER_PLAYER];
        
        float spriteWidth = playerSpriteSheet.texture.contentSize.width / 8;
        float spriteHeight = playerSpriteSheet.texture.contentSize.height / 2;
        
        //CCLOG(@"Player size: %f,%f", spriteWidth,spriteHeight);
        
        CGSize hitArea = CGSizeMake(PLAYER_WIDTH / CC_CONTENT_SCALE_FACTOR(), PLAYER_HEIGHT / CC_CONTENT_SCALE_FACTOR());
        CGPoint pos = ccp(dx * MAP_TILE_WIDTH, ((mapHeight - dy - 1) * MAP_TILE_HEIGHT));
        pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f;
        pos.y += hitArea.height/2.0f;
        
        // Create player
        player = [Player spriteWithBatchNode:playerSpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];        
        [player setPosition:pos];
        [player setAnchorPoint:ccp(PLAYER_ANCHOR_X,PLAYER_ANCHOR_Y)];
        [player setupPlayer:playerID properties:dict];
        [player createBox2dObject:world size:hitArea];
        [playerSpriteSheet addChild:player z:LAYER_PLAYER];
        
        player.autoSafepoint = !checkpoints;
        if (player.autoSafepoint) CCLOG(@"Player uses auto-safe points!");
        
        [controls setPlayer:player];
    } else {
        CCLOG(@"Error could not find player spritesheet!");
    }

    
    /*
	
	BOOL custom = NO;
	
	if (playerID > 10) {
		playerFilename = [NSString stringWithFormat:@"%@wp-content/characters/character%d.png", [self returnServer], playerID];
		
		custom = ignoreCache;
		if ([cached objectForKey:playerFilename] != nil) {
			custom = NO; // cached on previous steps
			
		} else {
			[cached setObject:@"YES" forKey:playerFilename];
		}
		
		CCLOG(@"Player spritesheet url: %@", playerFilename);
		@try {
			playerSpriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:playerFilename ignoreCache:custom]];
			
		} @catch (NSException * e) {
			CCLOG(@"Player spritesheet not found or error, use default one");
			playerSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"player_%i.png", arc4random()%11]];
		}	
		
	} else {
		//playerFilename = [NSString stringWithFormat:@"%@wp-content/characters/player_%d.png", [self returnServer], playerID];
		//playerSpriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:playerFilename ignoreCache:custom || ignoreCache]];
		
		CCLOG(@"Player spritesheet: %@", [NSString stringWithFormat:@"player_%i.png", playerID]);
		playerSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"player_%i.png", playerID]];
	}
     
     */
	
}

-(void) loadEnemies
{
	NSMutableArray *enemiesList = [data objectForKey:@"characters"];
	
	for(uint i = 0; i < [enemiesList count]; i++)
	{
		NSDictionary *dict = (NSDictionary *)[enemiesList objectAtIndex:i];
		int enemyID = [[dict objectForKey:@"type"] intValue];
		int dx = [[dict objectForKey:@"positionX"] intValue];
		int dy = [[dict objectForKey:@"positionY"] intValue];
		CCLOG(@"Enemy id: %i, initial position: %i,%i", enemyID, dx, dy);
		
        CCSpriteBatchNode *enemySpriteSheet;
		NSString *enemyFilename;        
        
        if (enemyID > 10) {
            enemyFilename = [Shared findAsset:[NSString stringWithFormat:@"enemy%d.png", enemyID] withType:@"characters"];
        } else {
            enemyFilename = [Shared findAsset:[NSString stringWithFormat:@"enemy_sheet%d.png", enemyID] withType:@"characters"];
        }
        
        if(enemyFilename) {
            enemySpriteSheet = [CCSpriteBatchNode batchNodeWithFile:enemyFilename];
            
            if (REDUCE_FACTOR != 1.0f) [enemySpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
            else [enemySpriteSheet.textureAtlas.texture setAliasTexParameters];
            
            [objects addChild:enemySpriteSheet z:LAYER_PLAYER];
            
            float spriteWidth = enemySpriteSheet.texture.contentSize.width / 8;
            float spriteHeight = enemySpriteSheet.texture.contentSize.height / 2;
            
            CGSize hitArea = CGSizeMake(ENEMY_WIDTH / CC_CONTENT_SCALE_FACTOR(), ENEMY_HEIGHT / CC_CONTENT_SCALE_FACTOR());
            CGPoint pos = ccp(dx * MAP_TILE_WIDTH, ((mapHeight - dy - 1) * MAP_TILE_HEIGHT));
            pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f;
            pos.y += hitArea.height/2.0f;
            
            // Create player		
            Enemy *enemy = [Enemy spriteWithBatchNode:enemySpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];        
            [enemy setPosition:pos];
            [enemy setAnchorPoint:ccp(ENEMY_ANCHOR_X,ENEMY_ANCHOR_Y)];
            [enemy setupEnemy:enemyID properties:dict player:player];
            [enemy createBox2dObject:world size:hitArea];
            [enemySpriteSheet addChild:enemy z:LAYER_PLAYER];
            
            [enemies addObject:enemy];

            
            
        } else {
            CCLOG(@"Could not load enemy: %i spritesheet", i);
        }
        
        /*
        
		CCSpriteBatchNode *enemySpriteSheet;
		BOOL custom = NO;
		NSString *enemyFilename;
		if (enemyID > 10) {
			enemyFilename = [NSString stringWithFormat:@"%@wp-content/characters/enemy%d.png", [self returnServer], enemyID];
			
			custom = ignoreCache;
			if ([cached objectForKey:enemyFilename] != nil) {
				custom = NO; // cached on previous steps
				
			} else {
				[cached setObject:@"YES" forKey:enemyFilename];
			}
			
			CCLOG(@"Enemy spritesheet url: %@", enemyFilename);
			@try {
				enemySpriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:enemyFilename ignoreCache:custom]];
				
			} @catch (NSException * e) {
				CCLOG(@"Enemy Spritesheet not found or error, use default one");
				enemySpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"enemy_sheet%i.png", arc4random()%11]];
			}
			
		} else {
			//enemyFilename = [NSString stringWithFormat:@"%@wp-content/characters/enemy_sheet%d.png", [self returnServer], enemyID];
			//enemySpriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:enemyFilename ignoreCache:custom || ignoreCache]];
			
			CCLOG(@"Enemy spritesheet: %@", [NSString stringWithFormat:@"enemy_sheet%i.png", enemyID]);
			enemySpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"enemy_sheet%i.png", enemyID]];
		}
         
        */
    }
}

-(void) spawnEnemy:(CGPoint) pos
{
    id action = [CCSequence actions:
                 [CCDelayTime actionWithDuration:1.0/60.0],
                 [CCCallFuncND actionWithTarget:self selector:@selector(_spawnEnemy:data:) data:[[NSValue valueWithCGPoint:pos] retain]],
                 nil];
    [self runAction: action];
}

-(void) _spawnEnemy:(id)selector data:(NSValue *) value
{
    [value release];
    CGPoint pos = [value CGPointValue];
    NSMutableArray *enemiesList = [data objectForKey:@"characters"];
    
    int i = arc4random() % [enemiesList count];

    NSDictionary *dict = (NSDictionary *)[enemiesList objectAtIndex:i];
    int enemyID = [[dict objectForKey:@"type"] intValue];

    CCLOG(@"GameLayer.spawnEnemy: %f,%f", pos.x, pos.y);
    
    
    CCSpriteBatchNode *enemySpriteSheet;
    NSString *enemyFilename;        
    
    if (enemyID > 10) {
        enemyFilename = [Shared findAsset:[NSString stringWithFormat:@"enemy%d.png", enemyID] withType:@"characters"];
    } else {
        enemyFilename = [Shared findAsset:[NSString stringWithFormat:@"enemy_sheet%d.png", enemyID] withType:@"characters"];
    }
    
    if(enemyFilename) {
        enemySpriteSheet = [CCSpriteBatchNode batchNodeWithFile:enemyFilename];
        if (REDUCE_FACTOR != 1.0f) [enemySpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
        else [enemySpriteSheet.textureAtlas.texture setAliasTexParameters];
        
        [objects addChild:enemySpriteSheet z:LAYER_PLAYER];
        
        float spriteWidth = enemySpriteSheet.texture.contentSize.width / 8;
        float spriteHeight = enemySpriteSheet.texture.contentSize.height / 2;
        
        CGSize hitArea = CGSizeMake(ENEMY_WIDTH / CC_CONTENT_SCALE_FACTOR(), ENEMY_HEIGHT / CC_CONTENT_SCALE_FACTOR());
        
        Enemy *enemy = [Enemy spriteWithBatchNode:enemySpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];
        [enemy setPosition:pos];
        [enemy setAnchorPoint:ccp(ENEMY_ANCHOR_X,ENEMY_ANCHOR_Y)];
        enemy.spawned = YES;
        [enemy setupEnemy:enemyID properties:dict player:player];
        [enemy createBox2dObject:world size:hitArea];
        [enemySpriteSheet addChild:enemy z:LAYER_PLAYER];
        
        [enemies addObject:enemy];
    } else {
        CCLOG(@"_spawn enemy unable to load spritesheet");
    }
    
    /*
    CCSpriteBatchNode *enemySpriteSheet;
    BOOL custom = NO;
    NSString *enemyFilename;
    if (enemyID > 10) {
        enemyFilename = [NSString stringWithFormat:@"%@wp-content/characters/enemy%d.png", [self returnServer], enemyID];
        
        custom = ignoreCache;
        if ([cached objectForKey:enemyFilename] != nil) {
            custom = NO; // cached on previous steps
            
        } else {
            [cached setObject:@"YES" forKey:enemyFilename];
        }
        
        //CCLOG(@"Enemy spritesheet url: %@", enemyFilename);
        @try {
            enemySpriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:enemyFilename ignoreCache:custom]];
            
        } @catch (NSException * e) {
            //CCLOG(@"Enemy Spritesheet not found or error, use default one");
            enemySpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"enemy_sheet%i.png", arc4random()%11]];
        }
        
    } else {
        //enemyFilename = [NSString stringWithFormat:@"%@wp-content/characters/enemy_sheet%d.png", [self returnServer], enemyID];
        //enemySpriteSheet = [CCSpriteBatchNode batchNodeWithTexture:[Shared getTexture2DFromWeb:enemyFilename ignoreCache:custom || ignoreCache]];
        
        //CCLOG(@"Enemy spritesheet: %@", [NSString stringWithFormat:@"enemy_sheet%i.png", enemyID]);
        enemySpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"enemy_sheet%i.png", enemyID]];
    }
    
    if (REDUCE_FACTOR != 1.0f) [enemySpriteSheet.textureAtlas.texture setAntiAliasTexParameters];
    else [enemySpriteSheet.textureAtlas.texture setAliasTexParameters];
    
    [objects addChild:enemySpriteSheet z:LAYER_PLAYER];
    
    float spriteWidth = enemySpriteSheet.texture.contentSize.width / 8;
    float spriteHeight = enemySpriteSheet.texture.contentSize.height / 2;
    
    CGSize hitArea = CGSizeMake(ENEMY_WIDTH / CC_CONTENT_SCALE_FACTOR(), ENEMY_HEIGHT / CC_CONTENT_SCALE_FACTOR());
    */
     
    /*
    CGPoint pos = ccp(mapPos.x * MAP_TILE_WIDTH, ((mapHeight - mapPos.y - 1) * MAP_TILE_HEIGHT));
    pos.x += hitArea.width/2.0f + (MAP_TILE_WIDTH - hitArea.width)/2.0f;
    pos.y += hitArea.height/2.0f;
    */
    
    // Create player
    /*
    Enemy *enemy = [Enemy spriteWithBatchNode:enemySpriteSheet rect:CGRectMake(0,0,spriteWidth,spriteHeight)];
    [enemy setPosition:pos];
    [enemy setAnchorPoint:ccp(ENEMY_ANCHOR_X,ENEMY_ANCHOR_Y)];
     enemy.spawned = YES;
    [enemy setupEnemy:enemyID properties:dict player:player];
    [enemy createBox2dObject:world size:hitArea];
    [enemySpriteSheet addChild:enemy z:LAYER_PLAYER];
   
    
    [enemies addObject:enemy];
     */
}

-(void) spawnRobot:(CGRect) rect data:(NSDictionary *) originalData pos:(CGPoint) pos direction:(float)direction speed:(float)speed;
{
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:3];
    [values insertObject:[[NSValue valueWithCGRect:rect] retain] atIndex:0];
    [values insertObject:[originalData retain] atIndex:1];
    [values insertObject:[[NSValue valueWithCGPoint:pos] retain] atIndex:2];
    [values insertObject:[[NSNumber numberWithFloat:direction] retain] atIndex:3];
    [values insertObject:[[NSNumber numberWithFloat:speed] retain] atIndex:4];
    
    id action = [CCSequence actions:
                 [CCDelayTime actionWithDuration:1.0/60.0],
                 [CCCallFuncND actionWithTarget:self selector:@selector(_spawnRobot:data:) data:[values retain]],
                 nil];
    [self runAction: action];
}

-(void) _spawnRobot:(id)selector data:(NSArray *) values
{
    NSValue *valueRect = [values objectAtIndex:0];
    [valueRect release];
    CGRect rect = [valueRect CGRectValue];
    
    NSDictionary *originalData = [values objectAtIndex:1];
    [originalData release];
    
    NSValue *valuePos = [values objectAtIndex:2];
    [valuePos release];
    CGPoint pos = [valuePos CGPointValue];
    
    NSNumber *valueDirection = [values objectAtIndex:3];
    [valueDirection release];
    float direction = [valueDirection floatValue];
    
    NSNumber *valueSpeed = [values objectAtIndex:4];
    [valueSpeed release];
    float speed = [valueSpeed floatValue];
    
    [values release];
    
    int zorder  = 1;
    
    CCLOG(@"GameLayer.spawnRobot: %f,%f", pos.x, pos.y);
    
    /*
    CGPoint pos = ccp(mapPos.x * MAP_TILE_WIDTH, (mapHeight - mapPos.y - 1) * MAP_TILE_HEIGHT);
    pos.x += MAP_TILE_WIDTH/2.0f;
    pos.y += MAP_TILE_HEIGHT/2.0f;
    */
    
    Robot *item = [Robot spriteWithBatchNode:spriteSheet rect:rect];
    [item setPosition:pos];
    [item setupRobot:originalData];
    [item createBox2dObject:world size:CGSizeMake(MAP_TILE_WIDTH, MAP_TILE_HEIGHT)];
    [spriteSheet addChild:item z:zorder];
    item.spawned = YES;
    
    [robots addObject:item];
    
    if (speed != 0) {
        float xVel = -(speed*1.2f/(PTM_RATIO*CC_CONTENT_SCALE_FACTOR())) * sinf(M_PI*(direction/180.0f));
        float yVel = -(speed*1.2f/(PTM_RATIO*CC_CONTENT_SCALE_FACTOR())) * cosf(M_PI*(direction/180.0f));
        // Speed was slower compared with Flash version, so increased a 20%
        
        item.rotation = direction;
        [item shootTo:b2Vec2(xVel,yVel)];
        [item markToTransformBody:b2Vec2(((item.position.x)/PTM_RATIO), (item.position.y)/PTM_RATIO) angle:CC_DEGREES_TO_RADIANS(-direction)];
    }
    
    [item triggerEvent:@"onSpawn"];
}

#pragma mark -
#pragma mark Setup

-(void) initControls
{
    [controls setup];
}

-(void) initGame
{
    [Shared setPlaying:YES];
    
	// Game loaded, save cached date
	NSString *published = [Shared getLevelDate];
	//CCLOG(@"Game published: %@", published);
	NSArray *paths = NSSearchPathForDirectoriesInDomains(SAVE_FOLDER, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *resource = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cachedLevel%i",[Shared getLevelID]]];
	[published writeToFile:resource atomically:YES encoding:NSASCIIStringEncoding error:nil];
	CCLOG(@"Write level cache: %@ on: %@", published, resource);
    	
	// Init music
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	int musicPref = [prefs integerForKey:@"music"];
	
	NSString *bgmusic = [data objectForKey:@"bgmusic"];
	if ((![bgmusic isEqualToString:@""]) && (musicPref == 0)) {
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:bgmusic loop:YES];
	}
	
	[[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:BG_MUSIC_VOL];
	
	self.isTouchEnabled = YES;
    
    // Trigger onSpawn on robots
    Robot *robot; CCARRAY_FOREACH(robots, robot) {
		[robot triggerEvent:@"onSpawn"];
	}
}

-(void) offsetCameraX:(float)offset
{
    cameraXOffset = offset;
}

-(void) offsetCameraY:(float)offset
{
    cameraYOffset = offset;
}

-(void) cameraOnPlayer
{
    cameraBehaviour = kCameraFollowPlayer;
}

-(void) stopCameraMove
{
    cameraBehaviour = kCameraFixed;
}

-(void) panToLocation:(CGPoint)location
{
    cameraLocation = location;
    cameraBehaviour = kCameraPanToLocation;
}

-(void) snapToLocation:(CGPoint)location
{
    cameraLocation = location;
    cameraBehaviour = kCameraSnapToLocation;
}

-(void) setViewpointCenter 
{
    CGPoint point;
    
    if (cameraBehaviour == kCameraFixed) {
        point = previousLocation;
    }
	else if (cameraBehaviour == kCameraSnapToLocation) 
    {
        point = cameraLocation;
    }
	else if (cameraBehaviour == kCameraPanToLocation) 
    {
        float diff = ccpDistance(cameraLocation, previousLocation);
        if (diff < 1.0) {
            point = cameraLocation;
        }
        else 
        {    
            float angle = findAngle(cameraLocation, previousLocation);
            point = findPoint(previousLocation, angle, 2.0f);
        }
    } 
    else { //kCameraFollowPlayer
        point = player.position;
    }
    
    previousLocation = point;
	point = ccp((point.x + cameraXOffset) * REDUCE_FACTOR, (point.y + cameraYOffset) * REDUCE_FACTOR);
    
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint centerPoint = ccp(size.width/2, size.height/2);
	CGPoint viewPoint = ccpSub(centerPoint, point);
	
	// dont scroll so far so we see anywhere outside the visible map which would show up as black bars
	if (point.x < centerPoint.x)
		viewPoint.x = 0;
	if (point.y < centerPoint.y)
		viewPoint.y = 0;
	
	//CCLOG(@"x: %f, %f - width: %f", point.x, viewPoint.x, mapWidth*MAP_TILE_WIDTH*REDUCE_FACTOR);
	
	if (point.x > mapWidth*MAP_TILE_WIDTH*REDUCE_FACTOR - size.width/2)
		viewPoint.x = size.width - mapWidth*MAP_TILE_WIDTH*REDUCE_FACTOR;
	if (point.y > mapHeight*MAP_TILE_HEIGHT*REDUCE_FACTOR - size.height/2)
		viewPoint.y = size.height - mapHeight*MAP_TILE_HEIGHT*REDUCE_FACTOR;
	
	self.position = ccp(viewPoint.x, viewPoint.y);
}

-(CGPoint)convertToMapCoordinates:(CGPoint)point {
	return [self convertToWorldSpace:ccp(point.x*REDUCE_FACTOR, point.y*REDUCE_FACTOR)];
}

-(BOOL) isPaused
{
    return paused;
}

-(void) pause
{
    if (!paused) {
        CCLOG(@"GameLayer.pause");
        
        // Stop updater
        [self unscheduleUpdate];
        if (timerEnabled) [self unschedule:@selector(timer:)];
        paused = YES;
        
        Enemy *enemy; CCARRAY_FOREACH(enemies, enemy) {
            [enemy pause];
        }
        
        MovingPlatform *platform; CCARRAY_FOREACH(movingPlatforms, platform) {
            [platform pause];
        }
        
        Robot *robot; CCARRAY_FOREACH(robots, robot) {
            [robot pause];
        }
        
        [player pause];
    }
}

-(void) resume
{
    if (paused) {
        CCLOG(@"GameLayer.resume");
        
        // Start updater
        [self scheduleUpdate];
        if (timerEnabled) [self schedule:@selector(timer:) interval:1.0f];
        paused = NO;
        
        Enemy *enemy; CCARRAY_FOREACH(enemies, enemy) {
            [enemy resume];
        }
        
        MovingPlatform *platform; CCARRAY_FOREACH(movingPlatforms, platform) {
            [platform resume];
        }
        
        Robot *robot; CCARRAY_FOREACH(robots, robot) {
            [robot resume];
        }
        
        [player resume];
    }
}

-(void) resetScheduledElements {
    CCLOG(@"GameLayer.resetScheduledElements");
	MovingPlatform *platform; CCARRAY_FOREACH(movingPlatforms, platform) {
		[platform resetStatus:false];
	}
    
    [self cleanup];
}

#pragma mark -
#pragma mark Interactions

-(void) addBullet:(CCSpriteBatchNode *)bullet
{
	[objects addChild:bullet z:LAYER_PLAYER];
	[bullets addObject:bullet];
}

-(void) removeBullet:(CCSpriteBatchNode *)bullet
{
    [bullet removeAllChildrenWithCleanup:YES];
	if ([bullets containsObject:bullet]) [bullets removeObject:bullet];
	[objects removeChild:bullet cleanup:YES];
}

-(void) addOverlay:(CCNode *)node
{
	[hud addChild:node z:1001];
}

-(void) removeOverlay:(CCNode *)node
{
	[hud removeChild:node cleanup:YES];
}

-(void) addObject:(CCNode *)node
{
	[objects addChild:node z:LAYER_PLAYER];
}

-(void) addObject:(CCNode *)node withZOrder:(int)zorder
{
	[objects addChild:node z:zorder];
}

-(void) removeObject:(CCNode *)node
{
	[objects removeChild:node cleanup:YES];
}

-(void) removeEnemy:(Enemy *)enemy
{
    [enemies removeObject:enemy];
    [enemy removeFromParentAndCleanup:YES];
}

-(void) removeRobot:(Robot *)robot
{
    [robots removeObject:robot];
    [robot removeFromParentAndCleanup:YES];
}


-(void) activateSwitch:(NSString *) key 
{
	//CCLOG(@"switches: %@", switches);
	NSMutableArray *list = [switches objectForKey:key];
	for (MovingPlatform *platform  in list) {
		if (platform != nil) {
			[platform togle];
		}
	}
}

-(void) stopPlayer
{
	[player stop];
}

-(void) winGame
{
	lock = YES;
	
	[player win];
	[player stop];
	
	Win *win = [Win node];
	[self addOverlay:win];
}

-(void) loseGame
{
	lock = YES;
	
	[player stop];
	
	Lose *lose = [Lose node];
	[self addOverlay:lose];
}

-(void) transportPlayerToX:(int)x andY:(int)y
{
	[player changePositionX:x andY:y];
}

-(void) changeInitialPlayerPositionToX:(int)x andY:(int)y
{
	[player changeInitialPositionX:x andY:y];
}

-(void) transportPlayerToPosition:(CGPoint)pos
{
    [player changeToPosition:pos];
}

-(void) runTeleportAnimation:(CGPoint)pos
{
    id animation = [[CCAnimationCache sharedAnimationCache] animationByName:@"teleport"];
    if (animation != nil) {
        
        CCLOG(@"GameLayer.runTeleportAnimation");
        
        CCSprite *teleport = [CCSprite spriteWithTexture:teleportSpriteSheet.textureAtlas.texture rect:CGRectMake(0,0,MAP_TILE_WIDTH,MAP_TILE_HEIGHT)];
        [teleportSpriteSheet addChild:teleport];
        [teleport setPosition:pos];
        
        id action = [CCSequence actions:
                     [CCAnimate actionWithAnimation:animation],
                     [CCCallFuncND actionWithTarget:self selector:@selector(_removeTeleportAnimation:data:) data:teleport],
                     nil];
       [teleport runAction:action];
    }    
}

-(void) _removeTeleportAnimation:(id)selector data:(CCSprite *) teleport {
    [teleportSpriteSheet removeChild:teleport cleanup:YES];
}

-(CGPoint) playerPosition
{
	return player.position;
}

-(void) broadcastMessageToRobots:(NSDictionary *)command
{
	Robot *robot; CCARRAY_FOREACH(robots, robot) {
		[robot receiveMessage:[command objectForKey:@"message"]];
	}
}

-(void) setAmmo:(int)_ammo
{
    if (!ammoEnabled) return;
    
	if (_ammo == 0) {
		ammoBarLeft.visible = NO;
		ammoBarMiddle.visible = NO;
		ammoBarRight.visible = NO;
		
	} else {
        if (ammoIcon.visible) {
            ammoBarLeft.visible = YES;
            ammoBarMiddle.visible = YES;
            ammoBarRight.visible = YES;
        }
		
		ammoBarMiddle.scaleX = 79 * (_ammo/100.0f);
		[ammoBarMiddle setPosition:ccp(ammoBarLeft.position.x + ammoBarLeft.contentSize.width/2, ammoBarLeft.position.y)];
	}
}

-(int) getAmmo;
{
	return ammo;
}

-(void) increaseAmmo:(int)amount
{
	ammo += amount;
	if (ammo > 100) ammo = 100;
	
	[self setAmmo:ammo];
}

-(void) reduceAmmo
{
	ammo--;
	if (ammo < 0) ammo = 0;
	[self setAmmo:ammo];
}

-(void) changeWeapon:(int)_weaponID
{
	[player changeWeapon:_weaponID];
}

-(void) increaseHealth:(int)amount
{
	[player increaseHealth:amount];
}

-(void) decreaseHealth:(int)amount
{
	[player decreaseHealth:amount];
}

-(void) changeMaxHealth:(int)amount
{
    [player setMaxHealth:amount];
}

-(int) playerHealth
{
    return player.health;
}

-(void) godModeOff
{
    player.immune = NO;
}

-(void) godModeOn
{
    player.immune = YES;    
}

-(void) lockPlayerYSpeed:(float)speed
{
    player.fixedYSpeed = speed;
}

-(void) lockPlayerXSpeed:(float)speed
{
    player.fixedXSpeed = speed;
}

-(void) playerSmokeOn
{
    [player displaySmoke];
}

-(void) playerSmokeOff
{
    [player removeSmoke];
}

-(void) setTime:(int)amount
{
    seconds = amount;
    [self setTimer:seconds];
}

-(void) increaseTime:(int)amount
{
	seconds += amount;
    [self setTimer:seconds];
}

-(void) decreaseTime:(int)amount
{
	seconds -= amount;
	if (seconds <= 0) {
		seconds = 0;
	}
	
    [self setTimer:seconds];
    
	if (timerEnabled && (seconds == 0)) {
		[player lose];
	}
}

-(void) showClock
{
    timerLabel.visible = YES;
}

-(void) hideClock
{
    timerLabel.visible = NO;
}

-(ccTime) timeLeft
{
    return seconds;
}

-(void) pauseBgm
{
    NSString *bgmusic = [data objectForKey:@"bgmusic"];
    if (![bgmusic isEqualToString:@""]) {
        [[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
    }
}

-(void) resumeBgm
{
    NSString *bgmusic = [data objectForKey:@"bgmusic"];
    if (![bgmusic isEqualToString:@""]) {
        [[SimpleAudioEngine sharedEngine] resumeBackgroundMusic];
    }
}

-(void) restartBgm
{
    NSString *bgmusic = [data objectForKey:@"bgmusic"];
    if (![bgmusic isEqualToString:@""]) {
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:bgmusic loop:YES];
    }
}

-(void) increaseLive:(int)amount
{
	[player increaseLive:amount];
}

-(void) decreaseLive:(int)amount
{
	[player decreaseLive:amount];
}

-(void) enableAmmo
{
	ammoIcon.visible = YES;
	ammoBarBGLeft.visible = YES;
    ammoBarBGMiddle.visible = YES;
    ammoBarBGRight.visible = YES;
    ammoBarLeft.visible = YES;
	ammoBarMiddle.visible = YES;
	ammoBarRight.visible = YES;
    
    ammoEnabled = YES;
}

-(void) disableAmmo
{
	ammoIcon.visible = NO;
	ammoBarBGLeft.visible = NO;
    ammoBarBGMiddle.visible = NO;
    ammoBarBGRight.visible = NO;
    ammoBarLeft.visible = NO;
	ammoBarMiddle.visible = NO;
	ammoBarRight.visible = NO;
    
    ammoEnabled = NO;
}

-(void) enableTimer
{
    if (!timerEnabled) {
        [self schedule:@selector(timer:) interval:1.0f];
        timerEnabled = YES;
        timerLabel.visible = YES;
    }
}

-(void) pauseTimer
{
	if (timerEnabled) [self unschedule:@selector(timer:)];
}

-(void) disableTimer
{
    if (timerEnabled) {
        [self unschedule:@selector(timer:)];
        timerEnabled = NO;
        timerLabel.visible = NO;
    }
}

-(void) hideHealth
{
    barBGLeft.visible = NO;
    barBGMiddle.visible = NO;
    barBGRight.visible = NO;
	barLeft.visible = NO;
	barMiddle.visible = NO;
	barRight.visible = NO;
	
    ammoIcon.visible = NO;
    ammoBarBGMiddle.visible = NO;
    ammoBarBGRight.visible = NO;
	ammoBarBGLeft.visible = NO;
	ammoBarLeft.visible = NO;
	ammoBarMiddle.visible = NO;
	ammoBarRight.visible = NO;
    
    livesLabel.visible = NO;
}

-(void) hideScore
{
    pointsLabel.visible = NO;
}

-(void) showHealth
{
    barBGLeft.visible = YES;
    barBGMiddle.visible = YES;
    barBGRight.visible = YES;
	barLeft.visible = YES;
	barMiddle.visible = YES;
	barRight.visible = YES;
	
    ammoIcon.visible = YES;
    ammoBarBGMiddle.visible = YES;
    ammoBarBGRight.visible = YES;
	ammoBarBGLeft.visible = YES;
	ammoBarLeft.visible = YES;
	ammoBarMiddle.visible = YES;
	ammoBarRight.visible = YES;
    
    livesLabel.visible = YES;
}

-(void) showScore
{
    pointsLabel.visible = YES;
}

-(void) quakeCameraWithIntensity:(int)intensity during:(int)milliseconds
{
    originalPosition = scene.position;
    float origianlX = scene.position.x;
	float origianlY = scene.position.y;
    
    float time = (1.0f/60.0f) * 10.0f * 100.0f;
    int times = milliseconds / time;
    if (times <= 0) times = 1;
    //CCLOG(@"GameLayer.quakeCameraWithIntensity: %i times: %i at 1/60 secs", intensity, times);
    
    intensity *= 2;
    
	// Shake screen
	id action = [CCSequence actions:
				 [CCRepeat actionWithAction:
				  [CCSequence actions:
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX-intensity,origianlY)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX+intensity,origianlY)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX+intensity,origianlY-intensity)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX-intensity,origianlY)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX-intensity,origianlY)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX,origianlY+intensity)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX-intensity,origianlY)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX,origianlY-intensity)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX-intensity,origianlY)],
				   [CCMoveTo actionWithDuration:1.0f/60.0f position:ccp(origianlX,origianlY)],
				   nil] times:times],
                 [CCCallFunc actionWithTarget:self selector:@selector(_resetPosition)],
				 nil];
	[scene runAction: action];
}

-(void) _resetPosition
{
    [scene setPosition:originalPosition];
}

-(void) flashScreenWithColor:(NSString *)color during:(int)milliseconds
{
    CCLayerColor *layer = [CCLayerColor layerWithColor:[Shared colorForHex:color withTransparency:255]];
    [hud addChild:layer z:5001 tag:5001];
    
    id action = [CCSequence actions:
                 [CCFadeOut actionWithDuration:milliseconds/100.0f],
                 [CCCallFunc actionWithTarget:self selector:@selector(_removeColorOverlay)],
				 nil];
    [layer runAction: action];
}

-(void) _removeColorOverlay
{    [hud removeChildByTag:5001 cleanup:YES];
}


-(void) say:(NSString *)msg
{
    Dialogue *npcs = [Dialogue node];
    [npcs setupDialogue:msg];
}

-(void) think:(NSString *)msg
{
	Dialogue *npcs = [Dialogue node];
    [npcs setupDialogue:msg];
}

-(void) sayInChatPanel:(NSString *)msg
{
	Dialogue *npcs = [Dialogue node];
    [npcs setupDialogue:msg];
}

-(void) askMultichoice:(NSDictionary *)command robot:(Robot *)robot
{
    robotMultiChoice = robot;
    
	MultiChoice *npcs = [MultiChoice node];
    [npcs setupChoices:command];
}

-(void) answeredMultiChoice:(MultiChoice *)multiChoice withAnswer:(NSString *)answer
{
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    [[GameLayer getInstance] resume];
    
    [[GameLayer getInstance] removeOverlay:multiChoice];
    
    id action = [CCSequence actions:
                 [CCDelayTime actionWithDuration:1.0/60.0],
                 [CCCallFuncND actionWithTarget:self selector:@selector(_robotReceiveAnswer:data:) data:answer],
                 nil];
	[self runAction: action];
}

-(void) _robotReceiveAnswer:(id)selector data:(NSString *) answer {
    [robotMultiChoice receiveMessage:answer];
}

-(void) jetpack
{
	[player addJetpack];
}

-(void) setTimer:(int)_seconds 
{
	NSString *label;
	
	int lminutes = (_seconds / 60);
	int lseconds = _seconds % 60;
	if ((lseconds < 10) && (lminutes < 10)) label = [NSString stringWithFormat:@"0%i:0%i", lminutes, lseconds];
	else if ((lseconds < 10) && (lminutes >= 10)) label = [NSString stringWithFormat:@"%i:0%i", lminutes, lseconds];
	else if ((lseconds >= 10) && (lminutes < 10)) label = [NSString stringWithFormat:@"0%i:%i", lminutes, lseconds];
	else label = [NSString stringWithFormat:@"%i:%i", lminutes, lseconds];
	
	[timerLabel setString: label];
}

-(void) setLives:(int)_lives
{
	[livesLabel setString:[NSString stringWithFormat:@"%ixHP", _lives]];
}

-(void) setHealth:(int)_health {
    
	if (_health == 0) {
		barLeft.visible = NO;
		barMiddle.visible = NO;
		barRight.visible = NO;
		
	} else {
		barLeft.visible = YES;
		barMiddle.visible = YES;
		barRight.visible = YES;
		
        // set pixel increment based on max bar size
		barMiddle.scaleX = (int)(((float)_health / (float)player.topHealth) * HEALTH_BAR_MAXLENGTH);
		[barMiddle setPosition:ccp(barLeft.position.x + barLeft.contentSize.width/2, barLeft.position.y)];
		[barRight setPosition:ccp(barMiddle.position.x + barMiddle.contentSize.width * barMiddle.scaleX, barMiddle.position.y)];
	}
}

-(void) increasePoints:(int)_points
{
	points += _points;
	[pointsLabel setString:[NSString stringWithFormat:@"%06d", points]];
}

-(void) setPoints:(int)_points
{
    points = _points;
	[pointsLabel setString:[NSString stringWithFormat:@"%06d", points]];

}

#pragma mark -
#pragma mark Touch controls

-(void) resetControls
{
    [controls resetControls];
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (lock) return;
	
	UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	
	//CCLOG(@"Touch began: %f,%f (%@)", location.x, location.y, touch);
    
    if (!paused) {
        [controls ccTouchBegan:touch withEvent:event andLocation:location];
    }
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (lock) return;
	
	//CCLOG(@"touches ended: %i", [touches count]);
	//UITouch *touch = [touches anyObject];
	
	NSEnumerator *enumerator = [touches objectEnumerator];
	while (UITouch *touch = [enumerator nextObject]) {
		
		CGPoint location = [touch locationInView: [touch view]];
		location = [[CCDirector sharedDirector] convertToGL:location];
		
		//int numFingers = icFingerCount(touches, event);
		//numFingers--;
		
		//CCLOG(@"Touch ended: %f,%f (%@)", location.x, location.y, touch);
		
        if (!paused) {
            [controls ccTouchEnded:touch withEvent:event andLocation:location];
        }
	}
	
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (lock) return;
	
	UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	
	//CCLOG(@"Touch moved: %f,%f", location.x, location.y);
	
    if (!paused) {
        [controls ccTouchMoved:touch withEvent:event andLocation:location];
    }
}

-(void) ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (lock) return;
	
	UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView: [touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	
	//CCLOG(@"Touch cancelled: %f,%f", location.x, location.y);
    
	if (!paused) {
        [controls ccTouchCancelled:touch withEvent:event andLocation:location];
	}
}

#pragma mark -
#pragma mark Flow control

-(void) loadNextLevel:(int)gameID
{
    [Shared setNextLevelID:gameID];
    
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    
    // IMPORTANT!! It seems we cannot replace scene with another instance of current scene,
    // so I created an intermediate scene that will simply load the game scene again.
    
    NSString *backgroundFilename = [data objectForKey:@"mapBackground"];
    NSString *assetPath;
    
    if ( ([backgroundFilename rangeOfString:@".png"].location != NSNotFound) ||
        ([backgroundFilename rangeOfString:@".jpg"].location != NSNotFound) ||
        ([backgroundFilename rangeOfString:@".gif"].location != NSNotFound) )
    {
        assetPath = [Shared findAsset:backgroundFilename withType:@"backgrounds"];
    } else {
        assetPath = [Shared findAsset:[backgroundFilename stringByAppendingString:@".png"] withType:@"backgrounds"];
    }
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setValue:assetPath forKey:@"nextBackground"];
	[prefs synchronize];
    
    [[CCDirector sharedDirector] replaceScene:[IntermediateLayer scene]];
}

-(void) completeAndLoadNextLevel:(int)gameID withTitle:(NSString *)text
{
    [Shared setNextLevelID:gameID];
    
    lock = YES;
	
	[player stop];
    
    Completed *completed = [Completed node];
    [completed setup:text];
	[self addOverlay:completed];
}

-(void) loseGameWithText:(NSString *)text
{
    [self loseGame];
}

-(void) winGameWithText:(NSString *)text
{
    [self winGame];
}

-(void) quitGame
{   
    [Shared setNextLevelID:0];
    
    [self restartGameFromPause];
    [self pause];
    
    [pauseCover hide];
    [hud hide];
    [scene hide];
    
    [Shared setPlaying:NO];
    
    [[CCDirector sharedDirector] resume];
    
    mainMenu = [GameMenu node];
    [mainMenu setPosition:ccp(0,0)];
    [self addChild:mainMenu z:1000];
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    
    // IMPORTANT!! Since box2d uses the main layer, we scroll self, so we need 
    [self setPosition:ccp(0,0)]; 
}

-(void) pauseGame
{
	if (lock) return;

    [Shared setPaused:YES];
    
    [pauseCover show];
    [[CCDirector sharedDirector] pause];
    paused = YES;
    ((CCSprite *)pauseBtn.normalImage).opacity = 0;
		
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:BG_MUSIC_DIP];
}

-(void) resumeGame
{
	if (lock) return;
	
    [Shared setPaused:NO];
    
    [[CCDirector sharedDirector] resume];
    [pauseCover hide];
    paused = NO;
    ((CCSprite *)pauseBtn.normalImage).opacity = 100;
		
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:BG_MUSIC_VOL];
}

-(void) restartGame
{
    CCLOG(@"GameLayer.restartGame");
    
	lock = NO;
	
    [self cleanup];
    
	[self pause];
	
	seconds = 180;
	points = 0;
	ammo = 100;
	
	[self setAmmo:ammo];
	[self setPoints:points];
	[self setTimer:seconds];
	[self disableTimer];
	
	GameObject *item; CCARRAY_FOREACH(items, item) {
		[item restart];
	}
	
	Enemy *enemy; CCARRAY_FOREACH(enemies, enemy) {
        [enemy restart];
	}
    
    Robot *robot; CCARRAY_FOREACH(robots, robot) {
        [robot restart];
	}
    
    MovingPlatform *platform; CCARRAY_FOREACH(movingPlatforms, platform) {
		[platform resetStatus:true];
	}
	
    [player restart];
	[self resetControls];
    [Shared setPlaying:YES];
    
    [self showHealth];
    [self showScore];
    
    cameraBehaviour = kCameraFollowPlayer;
    cameraLocation = CGPointZero;
    cameraXOffset = 0;
    cameraYOffset = 0;
}

-(void) restartGameFromPause
{
    [self resumeGame];
    [self restartGame];
}

#pragma mark -
#pragma mark AlertView handler

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	if ([title isEqualToString:@"Back"])
    {
        [[CCDirector sharedDirector] replaceScene:[HomeLayer scene]];
    }
}

#pragma mark -

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	CCLOG(@"GameLayer.dealloc: %@", self);
	
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	if (world) {
		delete world;
		world = NULL;
	}
	
	if (debugDraw) {
		delete debugDraw;
		debugDraw = nil;
	}
	
	[background removeAllChildrenWithCleanup:YES];
	[objects removeAllChildrenWithCleanup:YES];
	[hud removeAllChildrenWithCleanup:YES];
	[scene removeAllChildrenWithCleanup:YES];
	
	[enemies release];
	[items release];
	[bullets release];
	[robots release];
	[movingPlatforms release];
	[properties release];
	[tilesIds release];
	[animationsIds release];
    [robotsIds release];
	[switches release];
	[cached release];
    [musicData release];
	
	[self removeAllChildrenWithCleanup:YES];
	
	// Stop music
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
    [CCAnimationCache purgeSharedAnimationCache];
    [[CCDirector sharedDirector] purgeCachedData];
    
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
