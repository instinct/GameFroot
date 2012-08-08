//
//  GameLayer.h
//  DoubleHappy
//
//  Created by Jose Miguel on 08/09/2011.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "ContactListener.h"

@class Player;
@class GameObject;
@class Bullet;
@class GameMenu;
@class NextLevel;
@class Controls;
@class Pause;
@class Robot;
@class Enemy;
@class MultiChoice;

typedef enum{
	kCameraFixed = 0,
	kCameraPanToLocation,
    kCameraSnapToLocation,
    kCameraFollowPlayer
} CameraBehaviour;

typedef enum{
	kCameraPlatformer = 0,
	kCameraLockOn
} CameraType;

// GameLayer
@interface GameLayer : CCLayer
{
	// Properties
	NSDictionary *properties;
	NSMutableDictionary *tilesIds;
	NSMutableDictionary *itemsIds;
	NSMutableDictionary *animationsIds;
    NSMutableDictionary *robotsIds;
	NSMutableDictionary *switches;
	NSMutableDictionary *cached;
    NSMutableDictionary *musicData;
	NSMutableDictionary *customWeapons;
    
	// Containers
	CCParallaxNode *scene;
	CCNode *background;
	CCNode *objects;
	CCNode *hud;
	
	// Loader/Main menu
	GameMenu *mainMenu;
    NextLevel *nextLevel;
    BOOL loadingNextLevel;
    int nextLevelID;
	int parts;
	int partsLoaded;
	
	// Controls
    Controls *controls;
    
	// Spritesheets
	CCSpriteBatchNode *spriteSheet;
	CCSpriteBatchNode *hudSpriteSheet;
	CCSpriteBatchNode *teleportSpriteSheet;
    
	// Map
	NSMutableDictionary *data;
	int mapWidth;
	int mapHeight;
	
	// Box2D
	b2World * world;
	b2Vec2 gravity;
	GLESDebugDraw * debugDraw;
	b2Body *groundBody;
	Player *player;
    ContactListener *contactListener;
	
	CCArray *enemies;
	CCArray *items;
	CCArray *movingPlatforms;
	CCArray *robots;
	CCArray *bullets;
	
	// HUD
	Pause *pauseCover;
	CCLabelBMFont *livesLabel;
	CCLabelBMFont *timerLabel;
	CCLabelBMFont *pointsLabel;
	CCMenuItemSprite *pauseBtn;
	int points;
	int totalPoints;
	int ammo;
	ccTime seconds;
	
	CCSprite *barBGLeft;
    CCSprite *barBGMiddle;
    CCSprite *barBGRight;
	CCSprite *barLeft;
	CCSprite *barMiddle;
	CCSprite *barRight;
	
    CCSprite *ammoIcon;
    CCSprite *ammoBarBGMiddle;
    CCSprite *ammoBarBGRight;
	CCSprite *ammoBarBGLeft;
	CCSprite *ammoBarLeft;
	CCSprite *ammoBarMiddle;
	CCSprite *ammoBarRight;
	BOOL ammoEnabled;
    
    BOOL paused;
	BOOL timerEnabled;
	BOOL lock;
	BOOL customTiles;
	BOOL useDPad;
	BOOL ignoreCache;
    CGPoint originalPosition;
    
    int arrayTiles[100000];
    
    Robot *robotMultiChoice;
    
    int serverUsed;
    
    BOOL checkpoints;
    
    CameraBehaviour cameraBehaviour;
    CGPoint cameraLocation;
    float cameraXOffset;
    float cameraYOffset;
    float cameraYOffsetFixed;
    CGPoint previousLocation;
    float cameraYOffsetAdjustment;
    CameraType cameraType;
    
}

@property(nonatomic,assign) Controls *controls;
@property(nonatomic,assign) int points;
@property(nonatomic,assign) int totalPoints;
@property(nonatomic,assign) int mapWidth;
@property(nonatomic,assign) int mapHeight;
@property(nonatomic,assign) b2World * world;
@property(nonatomic,assign) CCSpriteBatchNode *hudSpriteSheet;
@property(nonatomic,assign) float cameraYOffsetAdjustment;

// returns a CCScene that contains the GameLayer as the only child
+(CCScene *) scene;

#pragma mark -
#pragma mark Init
+(GameLayer *)getInstance;
-(void) setupLoadingScreen;
-(void) removeLoadingScreen;
-(void) setupNextLevelScreen;
-(void) removeNextLevelScreen;
-(void) startLoading;
-(void) loadLevelData:(int)gameID;
-(void) loadBackgroundLevel;
-(void) loadTilesLevel;

-(int) getTileAt:(CGPoint)position;
-(void) createMapTiles;

-(void) createMapItems;
-(void) loadPlayer;
-(void) loadEnemies;

-(void) spawnRobot:(CGRect) rect data:(NSDictionary *) originalData pos:(CGPoint) pos direction:(float)direction speed:(float)speed;
-(void) spawnEnemy:(CGPoint) pos;

-(void)music: (id)sender;
-(void)dpad: (id)sender;

#pragma mark -
#pragma mark Setup

-(void) initControls;
-(void) initGame;
-(BOOL) isPaused;
-(void) pause;
-(void) resume;
-(void) resetScheduledElements;
-(void) addBullet:(CCSpriteBatchNode *)bullet;
-(void) removeBullet:(CCSpriteBatchNode *)bullet;
-(void) addOverlay:(CCNode *)node;
-(void) removeOverlay:(CCNode *)node;
-(void) addObject:(CCNode *)node;
-(void) addObject:(CCNode *)node withZOrder:(int)zorder;
-(void) removeObject:(CCNode *)node;

-(void) removeEnemy:(Enemy *)enemy;
-(void) removeRobot:(Robot *)robot;

-(void) activateSwitch:(NSString *) key;
-(void) stopPlayer;
-(void) transportPlayerToX:(int)x andY:(int)y;
-(void) transportPlayerToPosition:(CGPoint)pos;
-(void) runTeleportAnimation:(CGPoint)pos;
-(void) changeInitialPlayerPositionToX:(int)x andY:(int)y;
-(CGPoint) playerPosition;
-(void) broadcastMessageToRobots:(NSDictionary *)command except:(Robot *)instance;

-(NSMutableDictionary *) getCustomWeapon:(NSString *) key;

-(void) cameraOnPlayer;
-(void) stopCameraMove;
-(void) offsetCameraX:(float)offset;
-(void) offsetCameraY:(float)offset;
-(void) amendOffsetCameraY:(float)offset;
-(void) panToLocation:(CGPoint)location;
-(void) snapToLocation:(CGPoint)location;
-(void) setViewpointCenter;
-(CGPoint)convertToMapCoordinates:(CGPoint)point;
-(void) cameraLockdown;
-(void) cameraPlatformer;

-(void) setAmmo:(int)_ammo;
-(int) getAmmo;
-(void) increaseAmmo:(int)amount;
-(void) reduceAmmo;
-(void) jetpack;
-(void) changeWeapon:(int)_weaponID;
-(void) increaseHealth:(int)amount;
-(void) decreaseHealth:(int)amount;
-(void) changeMaxHealth:(int)amount;
-(int) playerHealth;
-(void) godModeOff;
-(void) godModeOn;
-(void) lockPlayerYSpeed:(float)speed;
-(void) lockPlayerXSpeed:(float)speed;
-(void) playerSmokeOn;
-(void) playerSmokeOff;

-(void) setTime:(int)amount;
-(void) increaseTime:(int)amount;
-(void) decreaseTime:(int)amount;
-(void) increaseLive:(int)amount;
-(void) decreaseLive:(int)amount;
-(void) enableAmmo;
-(void) disableAmmo;
-(void) enableTimer;
-(void) pauseTimer;
-(void) disableTimer;
-(void) hideHealth;
-(void) hideScore;
-(void) showHealth;
-(void) showScore;

-(void) quakeCameraWithIntensity:(int)intensity during:(int)milliseconds;
-(void) flashScreenWithColor:(NSString *)color during:(int)milliseconds;
-(void) say:(NSString *)msg;
-(void) think:(NSString *)msg;
-(void) sayInChatPanel:(NSString *)msg;
-(void) askMultichoice:(NSDictionary *)command robot:(Robot *)robot;
-(void) answeredMultiChoice:(MultiChoice *)multiChoice withAnswer:(NSString *)answer;
-(void) setTimer:(int)_seconds;
-(void) setLives:(int)_lives;
-(void) setHealth:(int)_health;
-(void) increasePoints:(int)_points;
-(void) setPoints:(int)_points;

-(void) showClock;
-(void) hideClock;
-(ccTime) timeLeft;

-(void) pauseBgm;
-(void) resumeBgm;
-(void) restartBgm;

-(void) resetControls;

-(void) loadNextLevel:(int)gameID;
-(void) completeAndLoadNextLevel:(int)gameID withTitle:(NSString *)text;
-(void) loseGameWithText:(NSString *)text;
-(void) winGameWithText:(NSString *)text;

-(void) loseGame;
-(void) winGame;
-(void) quitGame;
-(void) pauseGame;
-(void) resumeGame;
-(void) restartGame;
-(void) restartGameFromPause;

@end
