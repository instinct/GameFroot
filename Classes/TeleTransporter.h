//
//  TeleTransporter.h
//  DoubleHappy
//
//  Created by Jose Miguel on 28/10/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObject.h"

@interface TeleTransporter : GameObject {
	int destinationX;
	int destinationY;
	
	BOOL active;
}

-(void) setupTeleTransporterWithX:(int)x andY:(int)y;

@end
