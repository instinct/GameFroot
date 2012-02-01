//
//  CCLabelBMFont+AddToBatchNode.m
//  Cloneggs
//
//  Created by Jose Miguel on 07/05/2011.
//  Copyright 2011 ITL Business Ltd. All rights reserved.
//

#import "CCLabelBMFont+AddToBatchNode.h"

@implementation CCLabelBMFont (AddToBatchNode) 

-(void)addToBatchNode:(CCSpriteBatchNode *)batchnode zOrder:(int)order position:(CGPoint)position {
	for (int pos = self.children.count; pos > 0; --pos ) {
		CCSprite *node = [self.children objectAtIndex:pos-1];
		
		[node retain];
		[self removeChild:node cleanup:NO];
		[batchnode addChild:node z:order];
		
		[node setPosition:ccp(node.position.x+position.x-self.contentSize.width/2, 
							  node.position.y+position.y-self.contentSize.height/2)];

		[node release];
	}
}

@end
