//
//  Controls.m
//  GameFroot
//
//  Created by Jose Miguel on 08/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Controls.h"
#import "Player.h"

@implementation Controls

+(id) controlsWithFile:(NSString *)filename
{   
    return [Controls batchNodeWithFile:filename];
}

-(void) setup 
{
    if (!leftJoy) { // Be sure we don't recreate them again when restaring the game
        
        
        
        [self checkSettings];
        
        leftJoy = [CCSprite spriteWithSpriteFrameName:@"d_pad_normal.png"];
        [leftJoy setScale:CC_CONTENT_SCALE_FACTOR()];
        [leftJoy setOpacity:125];
        leftJoy.position = ccp(76,66);
        
        leftBut = [CCSprite spriteWithSpriteFrameName:@"b_button_up.png"];
        [leftBut setScale:CC_CONTENT_SCALE_FACTOR()];
        [leftBut setOpacity:125];
        leftBut.position = ccp(330,56);
        
        rightBut = [CCSprite spriteWithSpriteFrameName:@"a_button_up.png"];
        [rightBut setScale:CC_CONTENT_SCALE_FACTOR()];
        [rightBut setOpacity:125];
        rightBut.position = ccp(424,56);
        
        [self addChild:leftJoy];
        [self addChild:leftBut];
        [self addChild:rightBut];
        
        northMoveArea = CGRectMake(5, 141, 140, 70);
        southMoveArea = CGRectMake(5, 71, 140, 70);
        eastMoveArea = CGRectMake(76, 141, 70, 140);
        westMoveArea = CGRectMake(5, 141, 70, 140);
        
        // This could perhaps be improved using just angle from centre of dpap
        // North is up, south is right, and so on...
        northTriangleArea = [Shared getTrianglePoints: northMoveArea direction:@"north"];
        southTriangleArea = [Shared getTrianglePoints: southMoveArea direction:@"south"];
        eastTriangleArea = [Shared getTrianglePoints: eastMoveArea direction:@"east"];
        westTriangleArea = [Shared getTrianglePoints: westMoveArea direction:@"west"];
        
        jumpArea = CGRectMake(480 - 100 - 1, 91 + 30, 90, 150);
        shootArea = CGRectMake(480 - 195 - 1, 91 + 30, 90, 150);
    }
}

-(void) checkSettings
{
    // Read saved settings
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if ([prefs boolForKey:@"firstlaunch"]) {
        [prefs setInteger:1 forKey:@"dpad"];
        [prefs synchronize];
    }
      
    int dpadPref = [prefs integerForKey:@"dpad"];
    //if ([Shared isDebugging]) CCLOG(@"DPad preference: %i", dpadPref);
    useDPad = dpadPref == 1;
    
    self.visible = useDPad;
}

-(void) setPlayer:(Player *)_player
{
    player = _player;
}

-(BOOL) dpadNorth:(CGPoint) location
{
	return [Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:northTriangleArea[0] pointB:northTriangleArea[1] pointC:northTriangleArea[2]];
}

-(BOOL) dpadSouth:(CGPoint) location
{
	return [Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:southTriangleArea[0] pointB:southTriangleArea[1] pointC:southTriangleArea[2]];
}

-(BOOL) dpadWest:(CGPoint) location
{
	return [Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:westTriangleArea[0] pointB:westTriangleArea[1] pointC:westTriangleArea[2]];
}

-(BOOL) dpadEast:(CGPoint) location
{
	return [Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:eastTriangleArea[0] pointB:eastTriangleArea[1] pointC:eastTriangleArea[2]];
}

-(BOOL) dpadA:(CGPoint) location
{
	if ((location.x >= shootArea.origin.x) && (location.x <= shootArea.origin.x + shootArea.size.width) 
		&& (location.y >= shootArea.origin.y - shootArea.size.height) && (location.y <= shootArea.origin.y)) {
        
		return YES;
		
	} else {
		return NO;
	}
}

-(BOOL) dpadB:(CGPoint) location
{
	if ((location.x >= jumpArea.origin.x) && (location.x <= jumpArea.origin.x + jumpArea.size.width) 
		&& (location.y >= jumpArea.origin.y - jumpArea.size.height) && (location.y <= jumpArea.origin.y)) {
		
		return YES;
		
	} else {
		return NO;
	}
}

-(void) resetControls
{
	[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_normal.png"]];
	leftJoy.rotation = 0;
	
	[rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_up.png"]];
	[leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_up.png"]];
	
	gestureTouch = nil;
	gestureStartTime = 0;
	lastShoot = 0;
	leftTouch = nil;
	rightTouch = nil;
	jumpTouch = nil;
	shootTouch = nil;
	dpadTouch = nil;
}

-(void) pressedControls
{
    [leftJoy setOpacity:80];
}

-(void) releasedControls
{
    [leftJoy setOpacity:125];
}

-(void) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    if (!useDPad) {
		
		if (location.x < size.width * 0.25f) {
			
			if (location.y > size.height * 0.35f) {
				// Jump left
				[player jumpDirection:kDirectionLeft];
				jumpTouch = touch;
				
			} else {
				// Walk left
				[player moveLeft];
				leftTouch = touch;
			}
			
		} else if (location.x > size.width - (size.width * 0.25f)) {
			if (location.y > size.height * 0.35f) {
				// Jump right
				[player jumpDirection:kDirectionRight];
				jumpTouch = touch;
				
			} else {
				// Walk right
				[player moveRight];
				rightTouch = touch;
			}
			
		} else if (location.y > size.height - (size.height * 0.40f)) {
			// Jump
			[player jump];
			jumpTouch = touch;
			
		} else {
			// Shoot
			if (event.timestamp - lastShoot > player.shootDelay) {
				[player shoot];
				lastShoot = event.timestamp;
			}
			
			// Control swipe
			gestureStartPoint = location;
			gestureTouch = touch;
			gestureStartTime = event.timestamp;
		}
        
	} else {
		if ([Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:northTriangleArea[0] pointB:northTriangleArea[1] pointC:northTriangleArea[2]]) {
			[player jump];
			dpadTouch = touch;
			jumpTouch = dpadTouch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = -90;
            
            [self pressedControls];
			
		} else if ([Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:southTriangleArea[0] pointB:southTriangleArea[1] pointC:southTriangleArea[2]]) {
			[player prone];
			dpadTouch = touch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = 90;
            
            [self pressedControls];
			
		} else if ([Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:eastTriangleArea[0] pointB:eastTriangleArea[1] pointC:eastTriangleArea[2]]) {
			[player moveRight];
			dpadTouch = touch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = 0;
            
            [self pressedControls];
			
		} else if ([Shared pointInTriangle:CGPointMake(location.x, location.y) pointA:westTriangleArea[0] pointB:westTriangleArea[1] pointC:westTriangleArea[2]]) {
			[player moveLeft];
			dpadTouch = touch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = 180;
            
            [self pressedControls];
			
		} else if ((location.x >= jumpArea.origin.x) && (location.x <= jumpArea.origin.x + jumpArea.size.width) 
				   && (location.y >= jumpArea.origin.y - jumpArea.size.height) && (location.y <= jumpArea.origin.y)) {
			
			if ((dpadTouch == nil) || (dpadTouch != jumpTouch)) {
				[player jump];
				jumpTouch = touch;
                
				[rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_down.png"]];
			}
            
		} else if ((location.x >= shootArea.origin.x) && (location.x <= shootArea.origin.x + shootArea.size.width) 
				   && (location.y >= shootArea.origin.y - shootArea.size.height) && (location.y <= shootArea.origin.y)) {
			
			if (event.timestamp - lastShoot > player.shootDelay) {
				[player shoot];
				lastShoot = event.timestamp;
				shootTouch = touch;
				
				[leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_down.png"]];
			}
		}
	}

}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location 
{
    if (!useDPad) {
        
        if (touch == leftTouch) {
            if (rightTouch == nil) [player stop];
            leftTouch = nil;
            
        } else if (touch == rightTouch) {
            if (leftTouch == nil) [player stop];
            rightTouch = nil;
            
        } else if (touch == jumpTouch) {
            [player resetJump];
            jumpTouch = nil;
            
        } else if (touch == gestureTouch) {
            
            // Detect swipe
            CGFloat diffY = gestureStartPoint.y - location.y;	
            //CCLOG(@"swipes, diffX:%f, diffY:%f", diffX, diffY);
            
            if (diffY > 80) {
                // swipe down
                [player prone];
            }
            gestureTouch = nil;
            
        }
        
    } else {
        
        if (touch == dpadTouch) {
            [leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_normal.png"]];
            leftJoy.rotation = 0;
            
            [player stop];
            
            if (touch == jumpTouch) {
                [player resetJump];
                jumpTouch = nil;
            }
            
            dpadTouch = nil;
            
            [self releasedControls];
        }
        
        if (touch == jumpTouch) {
            [player resetJump];
            jumpTouch = nil;
            [rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_up.png"]];
            
        } else if (touch == shootTouch) {
            shootTouch = nil;
            [leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_up.png"]];
        }
    }
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
	if (!useDPad) {
		
		if (touch == leftTouch) {
			
			if (location.x >= size.width * 0.35f) {
				[player stop];
				leftTouch = nil;
				
			} else {
				if (location.y > size.height/2) {
					// Jump left
					[player stop];
					leftTouch = nil;
					
					[player jumpDirection:kDirectionLeft];
					jumpTouch = touch;
				}
			}
			
		} else if (touch == rightTouch) {
			
			if (location.x <= size.width - (size.width * 0.35f)) {
				[player stop];
				rightTouch = nil;
				
			} else {
				if (location.y > size.height/2) {
					// Jump right
					[player stop];
					rightTouch = nil;
					
					[player jumpDirection:kDirectionRight];
					jumpTouch = touch;
				}
			}
		}
        
	} else {
        
		if (touch == dpadTouch) {
			
			if (([self dpadNorth:location]) && ((dpadTouch != jumpTouch))) {
				[player jump];
				jumpTouch = touch;
				leftJoy.rotation = -90;
				
			} else if ([self dpadSouth:location]) {
				[player prone];
				leftJoy.rotation = 90;
				if (dpadTouch == jumpTouch) {
					[player resetJump];
					jumpTouch = nil;
				}
				
			} else if ([self dpadEast:location]) {
				[player moveRight];
				leftJoy.rotation = 0;
				if (dpadTouch == jumpTouch) {
					[player resetJump];
					jumpTouch = nil;
				}
				
			} else if ([self dpadWest:location]) {
				[player moveLeft];
				leftJoy.rotation = 180;
				if (dpadTouch == jumpTouch) {
					[player resetJump];
					jumpTouch = nil;
				}
			}
		}
	}
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location
{
    if (touch == leftTouch) {
        [player stop];
        leftTouch = nil;
        
    } else if (touch == rightTouch) {
        [player stop];
        rightTouch = nil;
    }
}

/*
// Use this to trace the dpad hit areas
-(void) visit {
	[super visit];
	
	[Shared drawTriangle: northMoveArea direction:@"north"];
	[Shared drawTriangle: southMoveArea direction:@"south"];
	[Shared drawTriangle: eastMoveArea direction:@"east"];
	[Shared drawTriangle: westMoveArea direction:@"west"];
	[Shared drawCGRect: jumpArea];
	[Shared drawCGRect: shootArea];
}
*/

@end
