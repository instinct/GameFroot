//
//  Controls.h
//  GameFroot
//
//  Created by Jose Miguel on 08/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "Shared.h"
#import "Constants.h"

#define CONTROLS_INIT_X 76
#define CONTROLS_INIT_Y 66

// Pro swipe constants
#define CONTROLS_MAX_TRAVEL 70
#define CONTROLS_DEAD_SPOT_SIZE 10
#define CONTROLS_PRONE_TRIGGER 80

@class Player;

@interface Controls : CCSpriteBatchNode 
{
    // DPad
    CCSprite *leftJoy;
    CCSprite *proSwipeRing;
	CCSprite *leftBut;
	CCSprite *rightBut;
	CGRect northMoveArea;
	CGRect southMoveArea;
	CGRect eastMoveArea;
	CGRect westMoveArea;
	CGRect jumpArea;
	CGRect shootArea;
	CGPoint *northTriangleArea;
	CGPoint *southTriangleArea;
	CGPoint *eastTriangleArea;
	CGPoint *westTriangleArea;
    
    // Pro Swipe
    CGRect dpadTouchArea;
	CGRect aButtonTouchArea;
    CGRect bButtonTouchArea;
    CGPoint dpadInitialPosition;
    float midPointAnchor;
    
    // Touch controls
	CGPoint	gestureStartPoint;
	UITouch	* gestureTouch;
	NSTimeInterval gestureStartTime;
	NSTimeInterval lastShoot;
	UITouch	*leftTouch;
	UITouch	*rightTouch;
	UITouch	*jumpTouch;
	UITouch	*shootTouch;
	UITouch	*dpadTouch;
    
    GameControlType controlType;
    Player *player;
    
}

+(id) controlsWithFile:(NSString *)filename;
-(void) setup;
-(GameControlType) getControlType;
-(void) setControlType:(GameControlType)type;
-(void) checkSettings;
-(void) setPlayer:(Player *)_player;
-(void) resetControls;
-(void) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location;
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location;
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location;
-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location;
-(void) processProSwipeTouch:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location;
-(bool) touchWithinJumpHitArea:(CGPoint)point;
-(bool) touchWithinShootHitArea:(CGPoint)point;
-(void) initShootWithTouch:(UITouch*)touch andEvent:(UIEvent*)event;
-(void) initJumpWithTouch:(UITouch*)touch;
-(void) endShoot;
-(void) endJump;

@end
