//
//  CCMenu+Reset.m
//  IsoEngine
//
//  Created by Jose Miguel on 27/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CCMenu+Reset.h"

@implementation CCMenu (ClassName)

/** fix for locked items when touch lost, call manually **/
-(void) reset { 
	[selectedItem_ unselected];
	state_ = kCCMenuStateWaiting;
}

@end