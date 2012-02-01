//
//  FastSpriteBatchNode.m
//  TestTiles
//
//  Created by Jose Miguel on 01/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CCSpriteBatchNode+FastChildren.h"

@implementation CCSpriteBatchNode (FastChildren)

/* Adds a quad into the texture atlas but it won't be added into the children array.
 This method should be called only when you are dealing with very big AtlasSrite and when most of the CCSprite won't be updated.
 For example: a tile map (CCTMXMap) or a label with lots of characgers (BitmapFontAtlas)
 */
-(void) addQuadFromSprite:(CCSprite*)sprite quadIndex:(NSUInteger)index
{
	NSAssert( sprite != nil, @"Argument must be non-nil");
	NSAssert( [sprite isKindOfClass:[CCSprite class]], @"CCSpriteSheet only supports CCSprites as children");
	
	
	while(index >= textureAtlas_.capacity || textureAtlas_.capacity == textureAtlas_.totalQuads )
		[self increaseAtlasCapacity];
	
	//
	// update the quad directly. Don't add the sprite to the scene graph
	//
	
	[sprite useBatchNode:self];
	[sprite setAtlasIndex:index];
	
	ccV3F_C4B_T2F_Quad quad = [sprite quad];
	[textureAtlas_ insertQuad:&quad atIndex:index];
	
	// XXX: updateTransform will update the textureAtlas too using updateQuad.
	// XXX: so, it should be AFTER the insertQuad
	[sprite setDirty:YES];
	[sprite updateTransform];
}

/* This is the opposite of "addQuadFromSprite.
 It add the sprite to the children and descendants array, but it doesn't update add it to the texture atlas
 */
-(id) addSpriteWithoutQuad:(CCSprite*)child z:(NSUInteger)z tag:(NSInteger)aTag
{
	NSAssert( child != nil, @"Argument must be non-nil");
	NSAssert( [child isKindOfClass:[CCSprite class]], @"CCSpriteSheet only supports CCSprites as children");
	
	// quad index is Z
	[child setAtlasIndex:z];
	
	// XXX: optimize with a binary search
	int i=0;
	for( CCSprite *c in descendants_ ) {
		if( c.atlasIndex >= z )
			break;
		i++;
	}
	[descendants_ insertObject:child atIndex:i];
	
	
	// IMPORTANT: Call super, and not self. Avoid adding it to the texture atlas array
	[super addChild:child z:z tag:aTag];
	return self;	
}

-(void) addFastChild:(CCSprite*)sprite
{
	//always insert at the end, z and tag aren't used anymore
	NSUInteger indexForZ = [[self textureAtlas] totalQuads];
	
	// Optimization: add the quad without adding a child
	[self addQuadFromSprite:sprite quadIndex:indexForZ];
	
}

@end
