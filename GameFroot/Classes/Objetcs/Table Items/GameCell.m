//
//  GameCell.m
//  CCTableViewTest
//
//  Created by Ray Wenderlich on 3/1/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "GameCell.h"
#import "CCNode.h"

@implementation GameCell

@synthesize index;
@synthesize levelId;
@synthesize data;

+(CGSize)cellSize 
{
	CGSize size = [[CCDirector sharedDirector] winSize];
    return CGSizeMake(size.width, 58);
}

@end
