//
//  CCNode+HideShow.m
//  Cloneggs
//
//  Created by Jose Miguel on 29/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CCNode+HideShow.h"

@implementation CCNode (HideShow) 

-(void) hide {
	if (self.visible) {
		self.visible = NO;
		self.position = ccp(self.position.x+5000, self.position.y+5000);
	}
}

-(void) show {
	if (!self.visible) {
		self.visible = YES;
		self.position = ccp(self.position.x-5000, self.position.y-5000);
	}
}

@end
