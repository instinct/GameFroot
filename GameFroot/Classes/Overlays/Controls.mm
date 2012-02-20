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
        firstTouch = YES;

        dpadInitialPosition = ccp(CONTROLS_INIT_X,CONTROLS_INIT_Y);
        
        leftJoy = [CCSprite spriteWithSpriteFrameName:@"d_pad_normal.png"];
        [leftJoy setOpacity:CONTROLS_OPACITY];
        leftJoy.position = dpadInitialPosition;    
        
        proSwipeRing = [CCSprite spriteWithSpriteFrameName:@"ring.png"];
        [proSwipeRing setOpacity:CONTROLS_OPACITY];

        
        leftBut = [CCSprite spriteWithSpriteFrameName:@"b_button_up.png"];
        [leftBut setOpacity:CONTROLS_OPACITY];
        leftBut.position = ccp(330,56);
        
        rightBut = [CCSprite spriteWithSpriteFrameName:@"a_button_up.png"];
        [rightBut setOpacity:CONTROLS_OPACITY];
        rightBut.position = ccp(424,56);
        
        [self addChild:leftJoy];
        [self addChild:leftBut];
        [self addChild:rightBut];
        [self addChild:proSwipeRing];
        
        northMoveArea = CGRectMake(-5, 181, 220, 110); // 40 increase
        southMoveArea = CGRectMake(-5, 71, 220, 110); // done
        eastMoveArea = CGRectMake(106, 181, 110, 220); // done 
        westMoveArea = CGRectMake(-5, 181, 110, 220);
        
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
        
        // TODO: Change to center on visuals when availible.
        midPointAnchor = (dpadTouchArea.origin.x + dpadTouchArea.size.width/2);
        proSwipeRing.position = ccp(dpadTouchArea.size.width/2, dpadTouchArea.size.height/2 - 50);
        
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
        [self unschedule:@selector(proSwipeFadeIn:)];
        [self unschedule:@selector(proSwipeFadeOut:)];
        
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
            proSwipeRing.visible = NO;
            break;
        case controlNoDpad:
            self.visible = NO;
            break;
        case controlProSwipe:
            self.visible = YES;
            leftJoy.visible = NO;
            proSwipeRing.visible = YES;
            proSwipeRing.opacity = CONTROLS_OPACITY;
            firstTouch = YES;
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
    [leftJoy setOpacity:CONTROLS_OPACITY];
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
			[self initJumpWithTouch:touch];
			
		} else {
			// Shoot
			[self initShootWithTouch:touch andEvent:event];
			
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
				[self initJumpWithTouch:touch];
			}
            
		} else if ([self dpadA:location]) {
			[self initShootWithTouch:touch andEvent:event];
		}
	} else {
        
        // is point within trackable location?
        if (CGRectContainsPoint(CGRectMake(dpadTouchArea.origin.x, size.height - dpadTouchArea.origin.y, dpadTouchArea.size.width, dpadTouchArea.size.height), location)) {
            gestureStartTime = event.timestamp;
            gestureStartPoint = location;
            dpadTouch = touch;
            [self unschedule:@selector(proSwipeFadeIn:)];
            [self processProSwipeTouch:touch withEvent:event andLocation:location];
            
            if (firstTouch) {
                // set a timer for fade
                [self schedule:@selector(proSwipeFadeOut:) interval:2];
                firstTouch = NO;
            }
        }
        
        if ([self touchWithinJumpHitArea:location]) {
            [self initJumpWithTouch:touch];        }
        
        if ([self touchWithinShootHitArea:location]) {
            [self initShootWithTouch:touch andEvent:event];
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
            [self endJump];
            
        } else if (touch == gestureTouch) {
            
            // Detect swipe
            CGFloat diffY = gestureStartPoint.y - location.y;	
            //CCLOG(@"swipes, diffX:%f, diffY:%f", diffX, diffY);
            
            if (diffY > CONTROLS_PRONE_TRIGGER) {
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
                [self endJump];
            }
    
            dpadTouch = nil;
            [self releasedControls];
        }
        
        if (touch == jumpTouch) {
            [self endJump];
            
        } else if (touch == shootTouch) {
            [self endShoot];
        }
    } else {
    	 if (touch == dpadTouch) {
            [leftJoy setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"d_pad_normal.png"]];
            leftJoy.rotation = 0;
            
            [player stop];
             
             // Detect swipe
             CGFloat diffY = gestureStartPoint.y - location.y;
             
             if (diffY > CONTROLS_PRONE_TRIGGER) {
                 // swipe down
                 [player prone];
             }
            
            dpadTouch = nil;
            [self releasedControls];
            if(!proSwipeRing.visible) {
                 [self schedule:@selector(proSwipeFadeIn:) interval:CONTROLS_IDLE_TILL_REAPPEAR];
             }
        }
        
        if (touch == shootTouch) {
            [self endShoot];
           
            
        } else if (touch == jumpTouch) {
            [self endJump];
        }
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
					[self endJump];
				}
				
			} else if ([self dpadEast:location]) {
				[player moveRight];
				leftJoy.rotation = 0;
				if (dpadTouch == jumpTouch) {
					[self endJump];
				}
				
			} else if ([self dpadWest:location]) {
				[player moveLeft];
				leftJoy.rotation = 180;
				if (dpadTouch == jumpTouch) {
					[self endJump];
				}
			}
		}
	} else {
        
        // detect if any shoot or jump touches are now over
        // the other buttons
        
        if (touch == shootTouch) {
            if ([self touchWithinJumpHitArea:location]) {
                [self endShoot];
                [self initJumpWithTouch:touch];
            }
        }
        
        if(touch == jumpTouch) {
            if ([self touchWithinShootHitArea:location]) {
                [self endJump];
                [self initShootWithTouch:touch andEvent:event];
            }
        }
        
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

-(void) processProSwipeTouch:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location {
    
    if (dpadTouch == jumpTouch) {
        [self endJump];
    }
    
    if (touch == dpadTouch) {
        
        // Process movement
        float travel = location.x - midPointAnchor;
        // move if greater than dead spot size
        if(ABS(travel) > CONTROLS_DEAD_SPOT_SIZE) {
            if(travel > 0) {
                [player moveRight];  
            } else if(travel < 0) {
                [player moveLeft];  
            } else {
                [player stop];  
            }
            
            // if size of swipe is greater than max travel,
            // move anchorpoint.
            if(ABS(travel) > CONTROLS_MAX_TRAVEL) {
                if (travel > 0) {
                    midPointAnchor += (travel - CONTROLS_MAX_TRAVEL); 
                } else {
                    midPointAnchor += (travel + CONTROLS_MAX_TRAVEL);
                }
                if(proSwipeRing.visible) {
                    proSwipeRing.position = ccp(midPointAnchor, proSwipeRing.position.y);
                }
            }
        }
    }
}

-(void) initShootWithTouch:(UITouch*)touch andEvent:(UIEvent*)event {
    if (event.timestamp - lastShoot > player.shootDelay) {
        [player shoot];
        lastShoot = event.timestamp;
        shootTouch = touch;
        if(self.visible) {
            [leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_down.png"]];
        }

    }
}

-(void) initJumpWithTouch:(UITouch*)touch {
    if(self.visible) {
        [rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_down.png"]];
    }
    jumpTouch = touch;
    [player jump];
}

-(void) endShoot {
    shootTouch = nil;
    if(self.visible) {
         [leftBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"b_button_up.png"]];
    }
   
}

-(void) endJump {
    jumpTouch = nil;
    [player resetJump];
    if (self.visible) {
        [rightBut setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"a_button_up.png"]]; 
    }
}


-(bool) touchWithinJumpHitArea:(CGPoint)point {
    CGSize size = [[CCDirector sharedDirector] winSize];
    return CGRectContainsPoint(CGRectMake(aButtonTouchArea.origin.x, size.height - aButtonTouchArea.origin.y, aButtonTouchArea.size.width, aButtonTouchArea.size.height), point);
}

-(bool) touchWithinShootHitArea:(CGPoint)point {
    CGSize size = [[CCDirector sharedDirector] winSize];
    return CGRectContainsPoint(CGRectMake(bButtonTouchArea.origin.x, size.height - bButtonTouchArea.origin.y, bButtonTouchArea.size.width, bButtonTouchArea.size.height), point);
}

-(void) proSwipeFadeOut:(ccTime)deltaTime {
    id fadeAction = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction = [CCHide action];
    [proSwipeRing runAction:[CCSequence actions:fadeAction, hideAction, nil]];
    [self unschedule:@selector(proSwipeFadeOut:)];
}

-(void) proSwipeFadeIn:(ccTime)deltaTime {
    id fadeAction = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction = [CCShow action];
    [proSwipeRing runAction:[CCSequence actions:showAction, fadeAction, nil]];
    [self unschedule:@selector(proSwipeFadeIn:)];
    firstTouch = YES;
}


// Use this to trace the dpad hit areas
/*
-(void) visit {
	[super visit];
	[Shared drawCGRect:dpadTouchArea];
    [Shared drawCGRect:aButtonTouchArea];
    [Shared drawCGRect:bButtonTouchArea];
	[Shared drawTriangle: northMoveArea direction:@"north"];
	[Shared drawTriangle: southMoveArea direction:@"south"];
    [Shared drawTriangle: eastMoveArea direction:@"east"];
	[Shared drawTriangle: westMoveArea direction:@"west"];
	//[Shared drawCGRect: jumpArea];
	//[Shared drawCGRect: shootArea];
}
*/


@end
