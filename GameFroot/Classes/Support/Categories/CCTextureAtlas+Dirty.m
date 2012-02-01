//
//  CCTextureAtlas+Dirty.m
//  IsoEngine
//
//  Created by Jose Miguel on 03/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CCTextureAtlas+Dirty.h"

@implementation CCTextureAtlas (Dirty)

- (void) makeDirty
{
#if CC_USES_VBO
	dirty_ = YES;
#endif
}

@end
