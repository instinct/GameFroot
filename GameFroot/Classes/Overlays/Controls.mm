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
    if (!dpadLeft) { // Be sure we don't recreate them again when restaring the game

        CGSize size = [[CCDirector sharedDirector] winSize];
        firstTouch = YES;

        dpadInitialPosition = ccp(CONTROLS_INIT_X,CONTROLS_INIT_Y);
        
        // Set up control sprites
        
        dpadLeft = [CCSprite spriteWithSpriteFrameName:@"dpad_side.png"];
        dpadLeft.flipX = YES;
        dpadRight = [CCSprite spriteWithSpriteFrameName:@"dpad_side.png"];
        dpadUp = [CCSprite spriteWithSpriteFrameName:@"dpad_up.png"];
        dpadDown = [CCSprite spriteWithSpriteFrameName:@"dpad_down.png"];
        aButton = [CCSprite spriteWithSpriteFrameName:@"b_button.png"];
        bButton = [CCSprite spriteWithSpriteFrameName:@"a_button.png"];
        psLeft = [CCSprite spriteWithSpriteFrameName:@"left.png"];
        psRight = [CCSprite spriteWithSpriteFrameName:@"right.png"];
        psProne = [CCSprite spriteWithSpriteFrameName:@"prone_icon.png"];
        hitZoneLeftJump = [CCSprite spriteWithSpriteFrameName:@"dpad_side.png"];
        hitZoneLeftJump.flipX = YES;
        hitZoneLeftJump.rotation = 45;
        hitZoneLeftJump.position = ccp((size.width*CONTROLS_SIDE_ZONE_BOUNDRY)/2,size.height/2 + 40);
        hitZoneLeftJump.opacity = CONTROLS_OPACITY;
        hitZoneRightJump = [CCSprite spriteWithSpriteFrameName:@"dpad_side.png"];
        hitZoneRightJump.position = ccp((size.width - (size.width*CONTROLS_SIDE_ZONE_BOUNDRY/2)),size.height/2 + 40);
        hitZoneRightJump.rotation = -45;
        hitZoneRightJump.opacity = CONTROLS_OPACITY;
        
        [self setControlsOpacity:CONTROLS_OPACITY];
        
        //position elements
        aButton.position = ccp(424,56);
        bButton.position = ccp(330,56);
        [self setDpadArrowPosition];
        psRight.position = dpadRight.position;
        psLeft.position = dpadLeft.position;
        psProne.position = ccp(CONTROLS_INIT_X,CONTROLS_INIT_Y);
        
        [self addChild:dpadLeft];
        [self addChild:dpadRight];
        [self addChild:dpadUp];
        [self addChild:dpadDown];
        [self addChild:aButton];
        [self addChild:bButton];
        [self addChild:psLeft];
        [self addChild:psRight];
        [self addChild:psProne];
        [self addChild:hitZoneLeftJump];
        [self addChild:hitZoneRightJump];
        
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
        aButtonTouchArea = CGRectMake(aButton.position.x - (aButton.contentSize.width/2) - 20, size.height, aButton.contentSize.width + 45, size.height);
        bButtonTouchArea = CGRectMake(bButton.position.x - (bButton.contentSize.width/2) - 35, size.height, bButton.contentSize.width + 45, size.height);
        
        // TODO: Change to center on visuals when availible.
        midPointAnchor = (CONTROLS_INIT_X);
        
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
        [self unschedule:@selector(hitZoneGuidesFadeOut:)];
        [self unschedule:@selector(hitZoneGuidesFadeIn:)];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:(int)type forKey:@"controlType"];
        [prefs synchronize];
        controlType = type;
        CCLOG(@"Control type set. Incoming value: %i", type);
        CCLOG(@"value stored in defaults: %i", [prefs integerForKey:@"controlType"]);
    }
    [self setControlsVisible:YES];
    [self setControlsOpacity:CONTROLS_OPACITY];
    aButton.visible = YES;
    bButton.visible = YES;
    firstTouch = YES;
    switch (type) {
        case controlDpad:
            [self setProSwipeControlVisible:NO];
            [self setHitZonesGuidesVisible:NO];
            [self setDpadControlVisible:YES];
            break;
        case controlNoDpad:
            [self setProSwipeControlVisible:NO];
            [self setDpadControlVisible:NO];
            [self setHitZonesGuidesVisible:YES];
            aButton.visible = NO;
            bButton.visible = NO;
            break;
        case controlProSwipe:
            [self setDpadControlVisible:NO];
            [self setHitZonesGuidesVisible:NO];
            [self setProSwipeControlVisible:YES];            
            [self setProSwipeControlOpacity:CONTROLS_OPACITY];
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
    [self unschedule:@selector(proSwipeFadeIn:)];
    [self unschedule:@selector(proSwipeFadeOut:)];
    [self unschedule:@selector(hitZoneGuidesFadeIn:)];
    [self unschedule:@selector(hitZoneGuidesFadeOut:)];
    
    [self setControlsOpacity:CONTROLS_OPACITY];
	
	gestureTouch = nil;
	gestureStartTime = 0;
	lastShoot = 0;
	leftTouch = nil;
	rightTouch = nil;
	jumpTouch = nil;
	shootTouch = nil;
	dpadTouch = nil;
    [self setControlType:controlType];
    
}

-(void) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event andLocation:(CGPoint)location
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    if ([self getControlType] == controlNoDpad) {
		
        [self unschedule:@selector(hitZoneGuidesFadeIn:)];
        if (firstTouch) {
            [self schedule:@selector(hitZoneGuidesFadeOut:) interval:CONTROLS_HZ_TIME_TILL_FADE];
            firstTouch = NO;
        }
        
		if (location.x < size.width * CONTROLS_SIDE_ZONE_BOUNDRY) {
			
			if (location.y > size.height * CONTROLS_SIDE_TOP_ZONE_BOUNDRY) {
				// Jump left
				[player jumpDirection:kDirectionLeft];
				jumpTouch = touch;
				
			} else {
				// Walk left
				[player moveLeft];
				leftTouch = touch;
			}
			
		} else if (location.x > size.width - (size.width * CONTROLS_SIDE_ZONE_BOUNDRY)) {
			if (location.y > size.height * CONTROLS_SIDE_TOP_ZONE_BOUNDRY) {
				// Jump right
				[player jumpDirection:kDirectionRight];
				jumpTouch = touch;
				
			} else {
				// Walk right
				[player moveRight];
				rightTouch = touch;
			}
			
		} else if (location.y > size.height - (size.height * CONTROLS_MIDDLE_TOP_ZONE_BOUNDRY)) {
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
            
			dpadUp.opacity = 255;
			
		} else if ([self dpadSouth:location]) {
			[player prone];
			dpadTouch = touch;
			dpadDown.opacity = 255;
			
		} else if ([self dpadEast:location]) {
			[player moveRight];
			dpadTouch = touch;
            dpadRight.opacity = 255;
			
		} else if ([self dpadWest:location]) {
			[player moveLeft];
			dpadTouch = touch;
            dpadLeft.opacity = 255;
			
		} else if ([self touchWithinJumpHitArea:location]) {
			[self initJumpWithTouch:touch];
            
		} else if ([self touchWithinShootHitArea:location]) {
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
                [self schedule:@selector(proSwipeFadeOut:) interval:CONTROLS_TIME_TILL_FADE];
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
        
        if (!hitZoneLeftJump.visible) {
            [self schedule:@selector(hitZoneGuidesFadeIn:) interval:CONTROLS_HZ_IDLE_TILL_REAPPEAR];
        }
        
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
            
            [player stop];
            
            if (touch == jumpTouch) {
                [self endJump];
            }
    
            dpadTouch = nil;
            [self setDpadControlOpacity:CONTROLS_OPACITY];
        }
        
        if (touch == jumpTouch) {
            [self endJump];
            
        } else if (touch == shootTouch) {
            [self endShoot];
            
        }
    } else {
    	 if (touch == dpadTouch) {
             [self setDpadControlOpacity:CONTROLS_OPACITY];
            
            [player stop];
             
             // Detect swipe
             CGFloat diffY = gestureStartPoint.y - location.y;
             
             if (diffY > CONTROLS_PRONE_TRIGGER) {
                 // swipe down
                 if(psProne.visible) {
                     [self setProSwipeControlOpacity:CONTROLS_OPACITY];
                     psProne.opacity = 255;
                 }
                 [player prone];
             }
            
            dpadTouch = nil;
            if(!psLeft.visible) {
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
            
            [self setDpadControlOpacity:CONTROLS_OPACITY];
			
			if (([self dpadNorth:location]) && ((dpadTouch != jumpTouch))) {
				if ([Shared isSimulator]) {
                    // Allow dpad jump on simulator otherwise it's pretty difficult to play!
                    [player jump];
                    jumpTouch = touch;
                }
                
				dpadUp.opacity = 255;
				
			} else if ([self dpadSouth:location]) {
				[player prone];
				dpadDown.opacity = 255;
				if (dpadTouch == jumpTouch) {
					[self endJump];
				}
				
			} else if ([self dpadEast:location]) {
				[player moveRight];
				dpadRight.opacity = 255;
				if (dpadTouch == jumpTouch) {
					[self endJump];
				}
				
			} else if ([self dpadWest:location]) {
				[player moveLeft];
                dpadLeft.opacity = 255;
				if (dpadTouch == jumpTouch) {
					[self endJump];
				}
			}
		}
        
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
            
            if(psLeft.visible) {
                [self setProSwipeControlOpacity:CONTROLS_OPACITY];
            }
            
            if(travel > 0) {
                if (psRight.visible) {
                     psRight.opacity = 255;
                     psLeft.opacity = CONTROLS_OPACITY;
                }
                [player moveRight];
                
            } else if(travel < 0) {
                if (psLeft.visible) {
                    psLeft.opacity = 255;
                    psRight.opacity = CONTROLS_OPACITY;
                }
                [player moveLeft];
            } else {
                
                [player stop];  
            }
            
            // if size of swipe is greater than max travel,
            // move anchorpoint.
            if(ABS(travel) > CONTROLS_MAX_TRAVEL) {
                float delta;
                if (travel > 0) {
                    delta = (travel - CONTROLS_MAX_TRAVEL);
                } else {
                   delta = (travel + CONTROLS_MAX_TRAVEL);
                }
                midPointAnchor += delta;
                [self setProSwipeControlsPosition:delta];
            }
        }
    }
}

-(void) initShootWithTouch:(UITouch*)touch andEvent:(UIEvent*)event {
    if (event.timestamp - lastShoot > player.shootDelay) {
        [player shoot];
        lastShoot = event.timestamp;
        shootTouch = touch;
        if(bButton.visible) {
            bButton.opacity = 255;
        }

    }
}

-(void) initJumpWithTouch:(UITouch*)touch {
    if(aButton.visible) {
        aButton.opacity = 255;
    }
    jumpTouch = touch;
    [player jump];
}

-(void) endShoot {
    shootTouch = nil;
    if(bButton.visible) {
        bButton.opacity = CONTROLS_OPACITY;
    }
   
}

-(void) endJump {
    jumpTouch = nil;
    [player resetJump];
    if (aButton.visible) {
        aButton.opacity = CONTROLS_OPACITY;
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

-(void) hitZoneGuidesFadeOut:(ccTime)deltaTime {
    id fadeAction1 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction1 = [CCHide action];
    id fadeAction2 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction2 = [CCHide action];
    id fadeAction3 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction3 = [CCHide action];
    id fadeAction4 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction4 = [CCHide action];
    id fadeAction5 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction5 = [CCHide action];
    [dpadLeft runAction:[CCSequence actions:fadeAction1, hideAction1, nil]];
    [dpadRight runAction:[CCSequence actions:fadeAction2, hideAction2, nil]];
    [dpadUp runAction:[CCSequence actions:fadeAction3, hideAction3, nil]];
    [hitZoneRightJump runAction:[CCSequence actions:fadeAction4, hideAction4, nil]];
    [hitZoneLeftJump runAction:[CCSequence actions:fadeAction5, hideAction5, nil]];
    [self unschedule:@selector(hitZoneGuidesFadeOut:)];    
}

-(void) hitZoneGuidesFadeIn:(ccTime)deltaTime {
    id fadeAction1 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction1 = [CCShow action];
    id fadeAction2 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction2 = [CCShow action];
    id fadeAction3 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction3 = [CCShow action];
    id fadeAction4 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction4 = [CCShow action];
    id fadeAction5 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction5 = [CCShow action];
    [dpadLeft runAction:[CCSequence actions:showAction1, fadeAction1, nil]];
    [dpadRight runAction:[CCSequence actions:showAction2, fadeAction2, nil]];
    [dpadUp runAction:[CCSequence actions:showAction3, fadeAction3, nil]];
    [hitZoneLeftJump runAction:[CCSequence actions:showAction4, fadeAction4, nil]];
    [hitZoneRightJump runAction:[CCSequence actions:showAction5, fadeAction5, nil]];
    [self unschedule:@selector(hitZoneGuidesFadeIn:)];
    firstTouch = YES; 
}

-(void) proSwipeFadeOut:(ccTime)deltaTime {
    id fadeAction1 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction1 = [CCHide action];
    id fadeAction2 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction2 = [CCHide action];
    id fadeAction3 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:0];
    id hideAction3 = [CCHide action];
    [psLeft runAction:[CCSequence actions:fadeAction1, hideAction1, nil]];
    [psRight runAction:[CCSequence actions:fadeAction2, hideAction2, nil]];
    [psProne runAction:[CCSequence actions:fadeAction3, hideAction3, nil]];
    [self unschedule:@selector(proSwipeFadeOut:)];
}

-(void) proSwipeFadeIn:(ccTime)deltaTime {
    id fadeAction1 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction1 = [CCShow action];
    id fadeAction2 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction2 = [CCShow action];
    id fadeAction3 = [CCFadeTo actionWithDuration:CONTROLS_FADE_DURATION opacity:CONTROLS_OPACITY];
    id showAction3 = [CCShow action];
    [psLeft runAction:[CCSequence actions:showAction1, fadeAction1, nil]];
    [psRight runAction:[CCSequence actions:showAction2, fadeAction2, nil]];
    [psProne runAction:[CCSequence actions:showAction3, fadeAction3, nil]];
    [self unschedule:@selector(proSwipeFadeIn:)];
    firstTouch = YES;
}

-(void) setHitZonesGuidesVisible:(bool)visibility {
    if (visibility) {
        [self setHitZoneArrowPosition];
    }
    dpadLeft.visible = visibility;
    dpadRight.visible = visibility;
    dpadUp.visible = visibility;
    hitZoneRightJump.visible = visibility;
    hitZoneLeftJump.visible = visibility;
}

-(void) setDpadControlVisible:(bool)visibility {
    if(visibility) {
        [self setDpadArrowPosition];
    }
    dpadLeft.visible = visibility;
    dpadRight.visible = visibility;
    dpadUp.visible = visibility;
    dpadDown.visible = visibility;
}

-(void) setDpadControlOpacity:(float)opacity {
    dpadLeft.opacity = opacity;
    dpadRight.opacity = opacity;
    dpadUp.opacity = opacity;
    dpadDown.opacity = opacity;
}

-(void) setProSwipeControlVisible:(bool)visibility {
    psLeft.visible = visibility;
    psRight.visible = visibility;
    psProne.visible = visibility;
}

-(void) setProSwipeControlOpacity:(float)opacity {
    psLeft.opacity = opacity;
    psRight.opacity = opacity;
    psProne.opacity = opacity;
}

-(void) setControlsOpacity:(float)opacity {
    aButton.opacity = opacity;
    bButton.opacity = opacity;
    [self setDpadControlOpacity:opacity];
    [self setProSwipeControlOpacity:opacity];
    hitZoneLeftJump.opacity = opacity;
    hitZoneRightJump.opacity = opacity;
}

-(void) setControlsVisible:(bool)visibility {
    aButton.visible = visibility;
    bButton.visible = visibility;
    [self setDpadControlVisible:visibility];
    [self setProSwipeControlVisible:visibility];
    hitZoneLeftJump.visible = visibility;
    hitZoneRightJump.visible = visibility;
}

-(void) setProSwipeControlsPosition:(float)delta {
    psLeft.position = ccpAdd(psLeft.position, ccp(delta, 0));
    psRight.position = ccpAdd(psRight.position, ccp(delta, 0));
    psProne.position = ccpAdd(psProne.position, ccp(delta, 0));
}

-(void) setDpadArrowPosition {
    dpadLeft.position = ccp(CONTROLS_INIT_X - CONTROLS_OFFSET_FROM_ORIGIN,CONTROLS_INIT_Y);
    dpadRight.position = ccp(CONTROLS_INIT_X + CONTROLS_OFFSET_FROM_ORIGIN,CONTROLS_INIT_Y);
    dpadUp.position = ccp(CONTROLS_INIT_X,CONTROLS_INIT_Y + CONTROLS_OFFSET_FROM_ORIGIN);
    dpadDown.position = ccp(CONTROLS_INIT_X,CONTROLS_INIT_Y - CONTROLS_OFFSET_FROM_ORIGIN);
}

-(void) setHitZoneArrowPosition {
    CGSize size = [[CCDirector sharedDirector] winSize];
    dpadLeft.position = ccp((size.width*CONTROLS_SIDE_ZONE_BOUNDRY)/2,size.height/2 - 90); 
    dpadRight.position = ccp((size.width - (size.width*CONTROLS_SIDE_ZONE_BOUNDRY/2)),size.height/2 - 90);
    dpadUp.position = ccp(size.width/2,(size.height-(size.height*CONTROLS_MIDDLE_TOP_ZONE_BOUNDRY/2)));
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
