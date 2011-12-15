//
//  CCMenu+Reset.h
//  IsoEngine
//
//  Created by Jose Miguel on 27/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface CCMenu (ClassName)

/** fix for locked items when touch lost, call manually **/
-(void) reset;

@end
