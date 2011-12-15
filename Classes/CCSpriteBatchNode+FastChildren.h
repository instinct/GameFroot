//
//  CCSpriteBatchNode+FastChildren.h
//  TestTiles
//
//  Created by Jose Miguel on 01/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface CCSpriteBatchNode (FastChildren)

-(void) addQuadFromSprite:(CCSprite*)sprite quadIndex:(NSUInteger)index;
-(id) addSpriteWithoutQuad:(CCSprite*)child z:(NSUInteger)z tag:(NSInteger)aTag;
-(void) addFastChild:(CCSprite*)sprite;

@end
