//
//  OnPressMenu.m
//  isoEngine
//
//  Created by Jose Miguel on 06/01/2010.
//  Copyright 2010 ITL Business Ltd. All rights reserved.
//

#import "OnPressMenu.h"
#import "CCDirector.h"
#import "CCTouchDispatcher.h"
#import "CGPointExtension.h"

enum {
	kDefaultPadding =  5,
};

@interface OnPressMenu (Private)
// returns touched menu item, if any
-(CCMenuItem *) itemForTouch: (UITouch *) touch;
@end

@implementation OnPressMenu

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if( state_ != kCCMenuStateWaiting ) return NO;
	
	selectedItem_ = [self itemForTouch:touch];
	[selectedItem_ selected];
	[selectedItem_ activate];
	
	if( selectedItem_ ) {
		state_ = kCCMenuStateTrackingTouch;
		return YES;
	}
	return NO;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[OnPressMenu ccTouchEnded] -- invalid state");
	
	//[selectedItem_ unselected];
	////[selectedItem_ activate];
	
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
	/*
	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchMoved] -- invalid state");
	
	CCMenuItem *currentItem = [self itemForTouch:touch];
	
	if (currentItem != selectedItem_) {
		[selectedItem_ unselected];
		selectedItem_ = currentItem;
		[selectedItem_ selected];
	}
	*/
}


@end
