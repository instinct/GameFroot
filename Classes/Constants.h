//
//  Constants.h
//  SimpleBox2dScroller
//
//  Created by min on 3/17/11.
//  Copyright 2011 Min Kwon. All rights reserved.
//

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.

#define PTM_RATIO ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 50.0 : CC_CONTENT_SCALE_FACTOR() == 2 ? 25.0 : 50.0)

typedef enum {
    kGameObjectNone,
    kGameObjectPlayer,
	kGameObjectEnemy,
    kGameObjectPlatform,
	kGameObjectKiller,
	kGameObjectCloud,
	kGameObjectCollectable,
	kGameObjectBullet,
	kGameObjectBulletEnemy,
	kGameObjectMovingPlatform,
	kGameObjectSwitch,
	kGameObjectRobot,
	kGameObjectDialogue
} GameObjectType;

typedef enum{
	kDirectionLeft,
	kDirectionRight,
	kDirectionNone
} GameObjectDirection;

#define SAVE_FOLDER NSLibraryDirectory

#define HORIZONTAL_SPEED	5.0f
#define VERTICAL_SPEED		10.0f
#define BULLET_SPEED		9.0f
#define JETPACK_IMPULSE		1.8f
#define JETPACK_SPEED		0.35f

#define MAP_TILE_WIDTH	48.0f / CC_CONTENT_SCALE_FACTOR()
#define MAP_TILE_HEIGHT	48.0f / CC_CONTENT_SCALE_FACTOR()

#define SPRITESHEETS_TILE_WIDTH	42
#define SPRITESHEETS_ITEM_WIDTH	42

#define	LAYER_TILES		1
#define	LAYER_ITEMS		2
#define	LAYER_PLAYER	3

#define REDUCE_FACTOR	0.75f * CC_CONTENT_SCALE_FACTOR()

#define ADJUSTMENT_COLLISION_X	4.0f

#define DEBUG_WORLD				0