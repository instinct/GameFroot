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

@class Player;

@interface Controls : CCSpriteBatchNode 
{
    // DPad
    CCSprite *leftJoy;
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

@end
