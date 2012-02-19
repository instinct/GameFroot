//
//  SpriteItem.m
//  Cloneggs
//
//  Created by Jose Miguel on 05/04/2011.
//  Copyright 2011 ITL Business Ltd. All rights reserved.
//

#import "ButtonLabelItem.h"

@implementation ButtonLabelItem

@synthesize button=button_, label=label_;

+(id) itemFromSprite:(CCNode<CCRGBAProtocol>*)sprite withLabel:(CCLabelBMFont *)label
{
	return [self itemFromSprite:sprite withLabel:label target:nil selector:nil];
}
+(id) itemFromSprite:(CCNode<CCRGBAProtocol>*)sprite withLabel:(CCLabelBMFont *)label target:(id)target selector:(SEL)selector
{
	return [[[self alloc] initFromSprite:sprite withLabel:label target:target selector:selector] autorelease];
}
-(id) initFromSprite:(CCSprite<CCRGBAProtocol>*)sprite withLabel:(CCLabelBMFont *)label target:(id)target selector:(SEL)selector
{
	if( (self=[super initWithTarget:target selector:selector]) ) {
		self.button = sprite;
		self.label = label;
		[self setContentSize: [button_ contentSize]];
		
		[button_ addChild:label_ z:1];
		[label_ setPosition:ccp(button_.contentSize.width/2, button_.contentSize.height/2 - label_.contentSize.height/4 + 2)];
		
	}
	return self;
}

-(void) dealloc
{
	[button_ release];
	[label_ release];
	
	[super dealloc];
}

-(void) draw
{
	
}

#pragma mark CCMenuItemImage - CCRGBAProtocol protocol
- (void) setOpacity: (GLubyte)opacity
{
	[button_ setOpacity:opacity];
	[label_ setOpacity:opacity];
}

-(void) setColor:(ccColor3B)color
{
	[button_ setColor:color];
	[label_ setColor:color];
}

-(GLubyte) opacity
{
	return [button_ opacity];
}
-(ccColor3B) color
{
	return [button_ color];
}

@end
