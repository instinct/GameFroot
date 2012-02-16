//
//  Controls.m
//  GameFroot
//
//  Created by Jose Miguel on 08/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Controls.h"
#import "Player.h"
#import <math.h>

@implementation Controls

+(id) controlsWithFile:(NSString *)filename
{   
    return [Controls batchNodeWithFile:filename];
}

-(void) setup 
{
    if (!leftJoy) { // Be sure we don't recreate them again when restaring the game

        CGSize size = [[CCDirector sharedDirector] winSize];

        dpadInitialPosition = ccp(CONTROLS_INIT_X,CONTROLS_INIT_Y);
        maxDpadTravel = CONTROLS_MAX_TRAVEL;
        deadSpotSize = CONTROLS_DEAD_SPOT_SIZE;
        
        leftJoy = [CCSprite spriteWithSpriteFrameName:@"d_pad_normal.png"];
        [leftJoy setScale:CC_CONTENT_SCALE_FACTOR()];
        [leftJoy setOpacity:125];
        leftJoy.position = dpadInitialPosition;        
    
        
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
        
        northMoveArea = CGRectMake(-35, 181, 220, 110); // 40 increase
        southMoveArea = CGRectMake(-35, 71, 220, 110); // done
        eastMoveArea = CGRectMake(76, 181, 110, 220); // done 
        westMoveArea = CGRectMake(-35, 181, 110, 220);
        
        // This could perhaps be improved using just angle from centre of dpap
        // North is up, south is right, and so on...
        northTriangleArea = [Shared getTrianglePoints: northMoveArea direction:@"north"];
        southTriangleArea = [Shared getTrianglePoints: southMoveArea direction:@"south"];
        eastTriangleArea = [Shared getTrianglePoints: eastMoveArea direction:@"east"];
        westTriangleArea = [Shared getTrianglePoints: westMoveArea direction:@"west"];
        
        jumpArea = CGRectMake(480 - 100 - 1, 91 + 30, 90, 150);
        shootArea = CGRectMake(480 - 195 - 1, 91 + 30, 90, 150);

        // The area within which the dpad will track touches, roughly half the screen.
        dpadTouchArea = CGRectMake(0, size.height, size.width/2 + 20, size.height);
        aButtonTouchArea = CGRectMake(rightBut.position.x - (rightBut.contentSize.width/2) - 20, size.height, rightBut.contentSize.width + 45, size.height);
        bButtonTouchArea = CGRectMake(leftBut.position.x - (leftBut.contentSize.width/2) - 35, size.height, leftBut.contentSize.width + 45, size.height);
        
        jumpArea = aButtonTouchArea;
        shootArea = bButtonTouchArea;

        
        [self checkSettings];
    }
}

-(void) checkSettings
{
    // Read saved settings
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if ([prefs boolForKey:@"firstlaunch"] && ![prefs boolForKey:@"controlDefaultsApplied"]) {
        [self setControlType:controlProSwipe];
        [prefs setBool:YES forKey:@"controlDefaultsApplied"];
        [prefs synchronize];
    } else {
        controlType = (GameControlType)[prefs integerForKey:@"controlType"];
        [self setControlType:controlType];
    }
}

-(GameControlType) getControlType {
    return controlType;
}

-(void) setControlType:(GameControlType)type {
    if(type != controlType) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:(int)type forKey:@"controlType"];
        [prefs synchronize];
        controlType = type;
        CCLOG(@"Control type set. Incoming value: %i", type);
        CCLOG(@"value stored in defaults: %i", [prefs integerForKey:@"controlType"]);
    }
    switch (type) {
        case controlDpad:
            self.visible = YES;
            leftJoy.visible = YES;
            leftJoy.position = dpadInitialPosition;
            break;
        case controlNoDpad:
            self.visible = NO;
            break;
        case controlProSwipe:
            self.visible = YES;
            leftJoy.visible = NO;
            break;
        default:
            break;
    }
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
    
    if ([self getControlType] == controlNoDpad) {
		
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
        
	} else if([self getControlType] == controlDpad) {
		if ([self dpadNorth:location]) {
            dpadTouch = touch;
			if ([Shared isSimulator]) {
                // Allow dpad jump on simulator otherwise it's pretty difficult to play!
                [player jump];
                jumpTouch = dpadTouch;
            }
            
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = -90;
            
            [self pressedControls];
			
		} else if ([self dpadSouth:location]) {
			[player prone];
			dpadTouch = touch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = 90;
            
            [self pressedControls];
			
		} else if ([self dpadEast:location]) {
			[player moveRight];
			dpadTouch = touch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = 0;
            
            [self pressedControls];
			
		} else if ([self dpadWest:location]) {
			[player moveLeft];
			dpadTouch = touch;
			
			[leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_horizontal.png"]];
			leftJoy.rotation = 180;
            
            [self pressedControls];
			
		} else if ([self dpadB:location]) {
			
			if ((dpadTouch == nil) || (dpadTouch != jumpTouch)) {
				[player jump];
				jumpTouch = touch;
                
				[rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_down.png"]];
			}
            
		} else if ([self dpadA:location]) {
			
			if (event.timestamp - lastShoot > player.shootDelay) {
				[player shoot];
				lastShoot = event.timestamp;
				shootTouch = touch;
				
				[leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_down.png"]];
			}
		}
	} else {
        
        // is point within trackable location?
        if (CGRectContainsPoint(CGRectMake(dpadTouchArea.origin.x, size.height - dpadTouchArea.origin.y, dpadTouchArea.size.width, dpadTouchArea.size.height), location)) {
            proSwipeRing.position = location;
            gestureStartTime = event.timestamp;
            dpadTouch = touch;
            [self processProSwipeTouch:touch withEvent:event andLocation:location];
            CCLOG(@"dpad touch began");
        }
        
        if (CGRectContainsPoint(CGRectMake(aButtonTouchArea.origin.x, size.height - aButtonTouchArea.origin.y, aButtonTouchArea.size.width, aButtonTouchArea.size.height), location)) {
            [rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_down.png"]];
            
            jumpTouch = touch;
           
            [player jump];
			jumpTouch = touch;
        }
        
        if (CGRectContainsPoint(CGRectMake(bButtonTouchArea.origin.x, size.height - bButtonTouchArea.origin.y, bButtonTouchArea.size.width, bButtonTouchArea.size.height), location)) {
             [leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_down.png"]];
            shootTouch = touch;
            if (event.timestamp - lastShoot > player.shootDelay) {
				[player shoot];
				lastShoot = event.timestamp;
			}
        }	
	}

}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location 
{
    if ([self getControlType] == controlNoDpad) {
        
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
        
    } else if([self getControlType] == controlDpad) {
        
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
        
        if (touch == shootTouch) {
            [player resetJump];
            shootTouch = nil;
            [leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_up.png"]];
           
            
        } else if (touch == jumpTouch) {
            jumpTouch = nil;
             [rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_up.png"]];
        }
    }
}

-(void) processProSwipeTouch:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location {
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    if (dpadTouch == jumpTouch) {
        [player resetJump];
        jumpTouch = nil;
    }
    
    if (touch == dpadTouch) {
        // work out magnatude of control travel, (also maybe useful later for analog control)
        float magnitude = sqrtf(powf(gestureStartPoint.x - location.x, 2) + powf(gestureStartPoint.y - location.y, 2));
        
        CCLOG(@"magnitude: %f", magnitude);
        
        int directions = 0;
        
        // work out general directions of travel so we can derive a quadrant
        if (!CGPointEqualToPoint(location, gestureStartPoint)) {
            directions |= (location.x > gestureStartPoint.x) ? right : 0;
            directions |= (location.x < gestureStartPoint.x) ? left : 0;
            directions |= (location.y > gestureStartPoint.y) ? up : 0;
            directions |= (location.y < gestureStartPoint.y) ? down : 0;
        }
        
        // move control within bound
        if(CGRectContainsPoint(CGRectMake(dpadTouchArea.origin.x, size.height - dpadTouchArea.origin.y, dpadTouchArea.size.width, dpadTouchArea.size.height), location)) {
            proSwipeRing.position = location;                
        }
        
        // if magnitude within deadspot radius or ourside travel, don't register
        if((magnitude >= deadSpotSize) && (magnitude <= maxDpadTravel)) {
            
            // use some trig to get the angle
            float angle = asinf((abs(location.y - gestureStartPoint.y))/magnitude);
            
            //convert to degrees
            angle *= (180/M_PI);
            bool withinDiag = (angle >= CONTROLS_DIAG_LOWER && angle <= CONTROLS_DIAG_UPPER);
            
            switch (directions) {
                case 1:
                    // up
                    //[player jump];
                    //CCLOG(@"up");
                    break;
                case 2:
                    // down
                    //CCLOG(@"down");
                    [player prone];
                    break;
                case 4:
                    // left
                    //CCLOG(@"left");
                    [player moveLeft];
                    break;
                case 5:
                    // upperleft diag
                    if (withinDiag) {
                        //CCLOG(@"uperleft diag");
                        // [player jumpDirection:kDirectionLeft];
                    } else {
                        if (angle < CONTROLS_DIAG_LOWER) {
                            //CCLOG(@"left uld lde");
                            [player moveLeft];
                        } else {
                            //CCLOG(@"jump uld ude");
                            // [player jump];
                        }
                    }
                    break;
                case 6:
                    // lowerleft diag
                    if (withinDiag) {
                        //CCLOG(@"lowerleft diag");
                        [player prone];
                    } else {
                        if (angle < CONTROLS_DIAG_LOWER) {
                            //CCLOG(@"left lld lde");
                            [player moveLeft];
                        } else {
                            //CCLOG(@"crouch lld ude");
                            [player stop];
                            [player prone];
                        }
                    }
                    
                    break;
                case 8:
                    // right
                    //CCLOG(@"right");
                    [player moveRight];
                    break;
                case 9:
                    // upperright diag
                    if (withinDiag) {
                        //CCLOG(@"upperright diag");
                        // [player jumpDirection:kDirectionRight];
                    } else {
                        if (angle < CONTROLS_DIAG_LOWER) {
                            //CCLOG(@"right urd lde");
                            [player moveRight];
                        } else {
                            //CCLOG(@"jump urd ude");
                            // [player jump];
                        }
                    }
                    break;
                case 10:
                    // lowerright diag
                    if (withinDiag) {
                        //CCLOG(@"lowerright diag");
                        [player prone];
                    } else {
                        if (angle < CONTROLS_DIAG_LOWER) {
                            //CCLOG(@"right lrd lde");
                            [player moveRight];
                        } else {
                            //CCLOG(@"crouch lrd ude");
                            [player stop];
                            [player prone];
                        }
                    }
                    break;
                default:
                    //CCLOG(@"default");
                    break;
            }
        } else {
            //[player stop];
        }
        gestureStartPoint = location;
    }
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
	if ([self getControlType] == controlNoDpad) {
		
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
        
	} else if([self getControlType] == controlDpad) {
        
		if (touch == dpadTouch) {
			
			if (([self dpadNorth:location]) && ((dpadTouch != jumpTouch))) {
				if ([Shared isSimulator]) {
                    // Allow dpad jump on simulator otherwise it's pretty difficult to play!
                    [player jump];
                    jumpTouch = touch;
                }
                
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
	} else {
        [self processProSwipeTouch:touch withEvent:event andLocation:location];
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


// Use this to trace the dpad hit areas
/*
-(void) visit {
	[super visit];
	//[Shared drawCGRect:dpadTouchArea];
    //[Shared drawCGRect:aButtonTouchArea];
    //[Shared drawCGRect:bButtonTouchArea];
	[Shared drawTriangle: northMoveArea direction:@"north"];
	[Shared drawTriangle: southMoveArea direction:@"south"];
	[Shared drawTriangle: eastMoveArea direction:@"east"];
	[Shared drawTriangle: westMoveArea direction:@"west"];
	[Shared drawCGRect: jumpArea];
	[Shared drawCGRect: shootArea];
}
*/
@end
