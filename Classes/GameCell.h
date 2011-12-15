//
//  GameCell.h
//  CCTableViewTest
//
//  Created by Ray Wenderlich on 3/1/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "SWTableViewCell.h"

@interface GameCell : SWTableViewCell {
	int index;
    int levelId;
	NSDictionary *data;
}

@property (nonatomic,assign) int index;
@property (nonatomic,assign) int levelId;
@property (nonatomic,assign) NSDictionary *data;

@end
