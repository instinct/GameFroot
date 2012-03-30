//
//  Completed.m
//  GameFroot
//
//  Created by Jose Miguel on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Completed.h"
#import "IntermediateLayer.h"
#import "CCLabelBMFontMultiline.h"

@implementation Completed

// on "init" you need to initialize your instance
-(id) init
{	
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super initWithColor:ccc4(0,0,0,128)])) {
		
		self.isTouchEnabled = YES;
	}
	
	return self;
}

-(void) setup:(NSString *)text
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    CCLabelBMFontMultiline *title = [CCLabelBMFontMultiline labelWithString:text fntFile:@"Chicago.fnt" width:size.width - 20 alignment:CenterAlignment];    
    //CCLabelBMFont *title = [CCLabelBMFont labelWithString:text fntFile:@"Chicago.fnt"];
    
    CCLOG(@"Completed.setup: %@", text);
    
    [title setPosition:ccp(size.width*0.5,size.height*0.5)];
    [title.textureAtlas.texture setAliasTexParameters];
    [self addChild:title];
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    [[CCDirector sharedDirector] replaceScene:[IntermediateLayer scene]];
    [[GameLayer getInstance] removeOverlay:self];
}

@end

