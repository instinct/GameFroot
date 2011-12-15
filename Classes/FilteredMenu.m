//
//  FilteredMenu.m
//  GameFroot
//
//  Created by Jose Miguel on 26/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilteredMenu.h"

@implementation FilteredMenu

#pragma mark Menu - Touches

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:kCCMenuTouchPriority swallowsTouches:YES];
}

-(CCMenuItem *) itemForTouch: (UITouch *) touch
{
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	
	CCMenuItem* item;
	CCARRAY_FOREACH(children_, item){
		// ignore invisible and disabled items: issue #779, #866
		if ( [item visible] && [item isEnabled] ) {
			
			CGPoint local = [item convertToNodeSpace:touchLocation];
			CGRect r = [item rect];
			r.origin = CGPointZero;
			
			if( CGRectContainsPoint( r, local ) )
				return item;
		}
	}
	return nil;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if( state_ != kCCMenuStateWaiting || !visible_ )
		return NO;
	
    CGPoint location = [touch locationInView: [touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	
	//CCLOG(@"DelayedMenu: %f,%f", location.x, location.y);
	if (((location.x > 100) && (location.x < 280)) || (location.y < 50) || (location.y > 328)) return NO; // TODO: implement this properly
	
	selectedItem_ = [self itemForTouch:touch];
	[selectedItem_ selected];
	
	if( selectedItem_ ) {
		state_ = kCCMenuStateTrackingTouch;
		return YES;
	}
	return NO;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchEnded] -- invalid state");
	
	[selectedItem_ unselected];
	[selectedItem_ activate];
	
	state_ = kCCMenuStateWaiting;
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchCancelled] -- invalid state");
	
	[selectedItem_ unselected];
	
	state_ = kCCMenuStateWaiting;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchMoved] -- invalid state");
	
	CCMenuItem *currentItem = [self itemForTouch:touch];
	
	if (currentItem != selectedItem_) {
		[selectedItem_ unselected];
		selectedItem_ = currentItem;
		[selectedItem_ selected];
	}
}

#elif defined(__MAC_OS_X_VERSION_MAX_ALLOWED)

-(NSInteger) mouseDelegatePriority
{
	return kCCMenuMousePriority+1;
}

-(CCMenuItem *) itemForMouseEvent: (NSEvent *) event
{
	CGPoint location = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:event];
	
	CCMenuItem* item;
	CCARRAY_FOREACH(children_, item){
		// ignore invisible and disabled items: issue #779, #866
		if ( [item visible] && [item isEnabled] ) {
			
			CGPoint local = [item convertToNodeSpace:location];
			
			CGRect r = [item rect];
			r.origin = CGPointZero;
			
			if( CGRectContainsPoint( r, local ) )
				return item;
		}
	}
	return nil;
}

-(BOOL) ccMouseUp:(NSEvent *)event
{
	if( ! visible_ )
		return NO;
	
	if(state_ == kCCMenuStateTrackingTouch) {
		if( selectedItem_ ) {
			[selectedItem_ unselected];
			[selectedItem_ activate];
		}
		state_ = kCCMenuStateWaiting;
		
		return YES;
	}
	return NO;
}

-(BOOL) ccMouseDown:(NSEvent *)event
{
	if( ! visible_ )
		return NO;
	
	selectedItem_ = [self itemForMouseEvent:event];
	[selectedItem_ selected];
	
	if( selectedItem_ ) {
		state_ = kCCMenuStateTrackingTouch;
		return YES;
	}
	
	return NO;	
}

-(BOOL) ccMouseDragged:(NSEvent *)event
{
	if( ! visible_ )
		return NO;
	
	if(state_ == kCCMenuStateTrackingTouch) {
		CCMenuItem *currentItem = [self itemForMouseEvent:event];
		
		if (currentItem != selectedItem_) {
			[selectedItem_ unselected];
			selectedItem_ = currentItem;
			[selectedItem_ selected];
		}
		
		return YES;
	}
	return NO;
}

#endif // Mac Mouse support

@end
